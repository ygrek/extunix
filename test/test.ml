
open OUnit
open ExtUnix.All

let with_unix_error f () =
  try f ()
  with Unix.Unix_error(e,f,a) -> assert_failure (Printf.sprintf "Unix_error : %s(%s) : %s" f a (Unix.error_message e))

let require feature =
  match have feature with
  | None -> assert false
  | Some present -> skip_if (not present) (Printf.sprintf "%S is not available" feature)

let printer x = x

let test_eventfd () =
  require "eventfd";
  let e = eventfd 2 in
  assert_equal 2L (eventfd_read e);
  eventfd_write e 3L;
  assert_equal 3L (eventfd_read e)

let test_uname () =
  require "uname";
  let t = uname () in
  let _s: string = Uname.to_string t in
  ()

let test_fadvise () =
  require "fadvise";
  let (name,ch) = Filename.open_temp_file "extunix" "test" in
  try
    fadvise (Unix.descr_of_out_channel ch) 0 0 POSIX_FADV_NORMAL;
    LargeFile.fadvise (Unix.descr_of_out_channel ch) 0L 0L POSIX_FADV_SEQUENTIAL;
    close_out ch;
    Unix.unlink name
  with exn -> close_out_noerr ch; Unix.unlink name; raise exn

let test_fallocate () =
  require "fallocate";
  let (name,ch) = Filename.open_temp_file "extunix" "test" in
  try
    let fd = Unix.descr_of_out_channel ch in
    fallocate fd 0 1;
    LargeFile.fallocate fd 1L 1L;
    assert_equal (Unix.fstat fd).Unix.st_size 2;
    close_out_noerr ch;
    Unix.unlink name
  with exn -> close_out_noerr ch; Unix.unlink name; raise exn

(* Copied from oUnit.ml *)
(* Utility function to manipulate test *)
let rec test_decorate g tst =
  match tst with
    | TestCase f -> 
        TestCase (g f)
    | TestList tst_lst ->
        TestList (List.map (test_decorate g) tst_lst)
    | TestLabel (str, tst) ->
        TestLabel (str, test_decorate g tst)

let test_unistd =
  [
  "ttyname" >:: begin fun () ->
    require "ttyname";
    if Unix.isatty Unix.stdin then ignore (ttyname Unix.stdin);
    if Unix.isatty Unix.stdout then ignore (ttyname Unix.stdout);
  end;
  "ctermid" >:: (fun () -> require "ctermid"; ignore (ctermid ()));
  "pgid" >:: begin fun () ->
    require "getpgid";
    assert_equal (getsid 0) (getsid (Unix.getpid ()));
    let pgid = getpgid 0 in
    setpgid 0 0;
    assert_equal (getpgid 0) (Unix.getpid ());
    setpgid 0 pgid;
    assert_equal (getpgid 0) pgid;
  end;
  "fcntl" >:: begin fun () ->
    require "is_open_descr";
    assert (is_open_descr Unix.stdin);
    assert (is_open_descr Unix.stdout);
  end;
  "int_of_file_descr" >:: begin fun () ->
    try
      assert (Unix.stdout = (file_descr_of_int (int_of_file_descr Unix.stdout)))
    with
      Not_available _ -> skip_if true "int_of_file_descr"
  end
  ]

let test_realpath () =
  require "realpath";
  assert_equal ~printer (Unix.getcwd ()) (realpath ".");
  assert_equal ~printer (Unix.getcwd ()) (realpath "./././/./");
  assert_equal ~printer "/" (realpath "///");
  assert_equal ~printer "/" (realpath "/../../");
  ()

let test_signalfd () =
  require "signalfd";
  let pid = Unix.getpid () in
  let (_:int list) = Unix.sigprocmask Unix.SIG_BLOCK [Sys.sigusr1; Sys.sigusr2] in
  let fd = signalfd ~sigs:[Sys.sigusr1] ~flags:[] () in 
  Unix.kill pid Sys.sigusr1;
  let fd = signalfd ~fd ~sigs:[Sys.sigusr1; Sys.sigusr2] ~flags:[] () in
  Unix.set_nonblock fd;
  let printer = string_of_int in
  assert_equal ~printer Sys.sigusr1 (ssi_signo_sys (signalfd_read fd));
  Unix.kill pid Sys.sigusr2;
  assert_equal ~printer Sys.sigusr2 (ssi_signo_sys (signalfd_read fd));
  Unix.close fd

let test_resource =
  let all_resources = 
  [
    RLIMIT_CORE;
    RLIMIT_CPU;
    RLIMIT_DATA;
    RLIMIT_FSIZE;
    RLIMIT_NOFILE;
    RLIMIT_STACK;
    RLIMIT_AS;
  ]
  in
  let test_setrlimit r =
    require "setrlimit";
    let test soft hard =
      setrlimit r ~soft ~hard;
      let (soft',hard') = getrlimit r in
      assert_equal ~printer:Rlimit.to_string ~msg:"soft limit" ~cmp:Rlimit.eq soft soft';
      assert_equal ~printer:Rlimit.to_string ~msg:"hard limit" ~cmp:Rlimit.eq hard hard';
    in
    let (soft,hard) = match r with
    | RLIMIT_NOFILE ->
      (* kernel may have lower limits on open files (fs.nr_open or kern.maxfilesperproc) than rlimit.
         In such situation setrlimit may either silently adjust rlimits to lower values (BSD)
         or fail with EPERM (Linux)
      *)
      let (soft,hard) = getrlimit r in
      begin try setrlimit r ~soft ~hard with Unix.Unix_error (Unix.EPERM,_,_) -> skip_if true "setrlimit NOFILE EPERM" end;
      getrlimit r
    | _ -> getrlimit r
    in
    assert_bool "soft <= hard" (Rlimit.le soft hard);
    test hard hard;
    test soft hard;
    match hard with
    | Some 0L -> ()
    | None -> test soft soft
    | Some n -> let lim = Some (Int64.pred n) in test lim lim
  in
  let test_setrlimit r =
    (string_of_resource r) >:: (fun () -> test_setrlimit r)
  in
  [
    "setrlimit" >::: (List.rev_map test_setrlimit all_resources);
    "getpriority" >:: (fun () -> require "getpriority"; let (_:int) = getpriority (PRIO_PROCESS (Unix.getpid ())) in ());
    "setpriority" >:: (fun () ->
       require "setpriority";
       let me = PRIO_PROCESS (Unix.getpid ()) in
       let prio = getpriority me in
       setpriority me (prio + 1);
       assert_equal ~printer:string_of_int (prio + 1) (getpriority me));
  ]

let test_strtime () =
  require "strptime";
  assert_equal ~printer "2010/12/14" (strftime "%Y/%m/%d" (strptime "%Y-%m-%d" "2010-12-14"));
  let tm = Unix.localtime (Unix.gettimeofday ()) in
  let (_:string) = asctime tm in
  let (_:string) = tzname tm.Unix.tm_isdst in
  ()

let test_pts () =
  require "posix_openpt";
  let master = posix_openpt [Unix.O_RDWR] in
    grantpt master;
    unlockpt master;
    let name = ptsname master in
    let slave = Unix.openfile name [Unix.O_RDWR; Unix.O_NOCTTY] 0 in
    let test = "test" in
    let len = Unix.write slave test 0 (String.length test) in
    let str = String.create len in
    ignore (Unix.read master str 0 len);
    assert_equal str test;
    ()

let test_execinfo () =
  require "backtrace";
  (* backtrace may not work out of the box on all archs, see PR#5334 *)
(*   assert_bool "backtrace" ([||] <> backtrace ()) *)
  let (_:string array) = backtrace () in
  ()

let test_statvfs () =
  require "statvfs";
  let st = statvfs "." in
  assert_bool "blocks" (st.f_blocks >= st.f_bfree && st.f_bfree >= st.f_bavail);
  assert_bool "inodes" (st.f_files >= st.f_ffree && st.f_ffree >= st.f_favail);
  assert_bool "bsize" (st.f_bsize > 0)

let test_setenv () =
  require "setenv";
  let k = "EXTUNIX_TEST_VAR" in
  let v = string_of_float (Unix.gettimeofday ()) in
  setenv k k true;
  assert_equal ~printer k (Unix.getenv k);
  setenv k v false;
  assert_equal ~printer k (Unix.getenv k);
  setenv k v true;
  assert_equal ~printer v (Unix.getenv k);
  unsetenv k;
  unsetenv k;
  assert_raises Not_found (fun () -> Unix.getenv k)

let test_mkdtemp () =
  require "mkdtemp";
  let tmpl = Filename.concat Filename.temp_dir_name "extunix_test_XXXXXX" in
  let d1 = mkdtemp tmpl in
  let d2 = mkdtemp tmpl in
  try
    assert_bool "different" (d1 <> d2);
    assert_bool "d1 exists" ((Unix.stat d1).Unix.st_kind = Unix.S_DIR);
    assert_bool "d2 exists" ((Unix.stat d2).Unix.st_kind = Unix.S_DIR);
    Unix.rmdir d1;
    Unix.rmdir d2
  with exn -> Unix.rmdir d1; Unix.rmdir d2; raise exn

let test_memalign () =
  require "memalign";
  ignore (memalign 512 512);
  ignore (memalign 1024 2048);
  ignore (memalign 2048 16384);
  ignore (memalign 4096 65536)

let test_endian () =
  require "uint16_from_host";
  require "uint16_to_host";
  require "int16_from_host";
  require "int16_to_host";
  require "uint31_from_host";
  require "uint31_to_host";
  require "int31_from_host";
  require "int31_to_host";
  require "int32_from_host";
  require "int32_to_host";
  require "int64_from_host";
  require "int64_to_host";
  let module B = EndianBig in
  let module L = EndianLittle in
  let u16 = 0xABCD in
  let i16 = -0x1234 in
  let i32 = 0x89ABCDEFl in
  let i64 = 0x0123456789ABCDEFL in
  assert (B.uint16_to_host (B.uint16_from_host u16) =  u16);
  assert (B.int16_to_host  (B.int16_from_host i16) = i16);
  assert (L.uint16_to_host (L.uint16_from_host u16) =  u16);
  assert (L.int16_to_host  (L.int16_from_host i16) = i16);
  assert (B.uint16_from_host u16 <> L.uint16_from_host u16);
  assert (B.uint16_to_host u16 <> L.uint16_to_host u16);
  assert (B.int16_from_host i16 <> L.int16_from_host i16);
  assert (B.int16_to_host i16 <> L.int16_to_host i16);
  assert (B.int32_to_host  (B.int32_from_host i32) = i32);
  assert (L.int32_to_host  (L.int32_from_host i32) = i32);
  assert (B.int32_from_host i32 <> L.int32_from_host i32);
  assert (B.int32_to_host i32 <> L.int32_to_host i32);
  assert (B.int64_to_host  (B.int64_from_host i64) = i64);
  assert (L.int64_to_host  (L.int64_from_host i64) = i64);
  assert (B.int64_from_host i64 <> L.int64_from_host i64);
  assert (B.int64_to_host i64 <> L.int64_to_host i64)

let test_endian_string () =
  require "unsafe_get_int8";
  require "unsafe_get_int16";
  require "unsafe_get_int31";
  require "unsafe_get_int32";
  require "unsafe_get_int64";
  require "unsafe_get_uint8";
  require "unsafe_get_uint16";
  require "unsafe_get_uint31";
  require "unsafe_set_uint8";
  require "unsafe_set_uint16";
  require "unsafe_set_uint31";
  require "unsafe_set_int8";
  require "unsafe_set_int16";
  require "unsafe_set_int31";
  require "unsafe_set_int32";
  require "unsafe_set_int64";
  let module B = EndianBig in
  let module L = EndianLittle in
  let src = (* FF FF FEDC FEDC FEDCBA98 FEDCBA9876543210 *)
    "\255\255\254\220\254\220\254\220\186\152\254\220\186\152\118\084\050\016"
  in
  assert_equal (B.get_uint8  src  0) 0xFF;
  assert_equal (B.get_int8   src  1) (-0x01);
  assert_equal (B.get_uint16 src  2) 0xFEDC;
  assert_equal (B.get_int16  src  4) (-0x0124);
  assert_equal (B.get_int32  src  6) (0xFEDCBA98l);
  assert_equal (B.get_int64  src 10) (0xFEDCBA9876543210L);
  assert_equal (L.get_uint8  src  0) 0xFF;
  assert_equal (L.get_int8   src  1) (-0x01);
  assert_equal (L.get_uint16 src  2) 0xDCFE;
  assert_equal (L.get_int16  src  4) (-0x2302);
  assert_equal (L.get_int32  src  6) (0x98BADCFEl);
  assert_equal (L.get_int64  src 10) (0x1032547698BADCFEL);
  let b = "                  " in
  B.set_uint8  b  0 0xFF;
  B.set_int8   b  1 (-0x01);
  B.set_uint16 b  2 0xFEDC;
  B.set_uint16 b  4 (-0x0124);
  B.set_int32  b  6 (0xFEDCBA98l);
  B.set_int64  b 10 (0xFEDCBA9876543210L);
  assert_equal b src;
  let l = "                  " in
  L.set_uint8  l  0 0xFF;
  L.set_int8   l  1 (-0x01);
  L.set_uint16 l  2 0xDCFE;
  L.set_uint16 l  4 (-0x2302);
  L.set_int32  l  6 (0x98BADCFEl);
  L.set_int64  l 10 (0x1032547698BADCFEL);
  assert_equal l src
  
let () =
  let wrap test =
    with_unix_error (fun () -> test (); Gc.compact ())
  in
  let tests = ("tests" >::: [
    "eventfd" >:: test_eventfd;
    "uname" >:: test_uname;
    "fadvise" >:: test_fadvise;
    "fallocate" >:: test_fallocate;
    "unistd" >::: test_unistd;
    "realpath" >:: test_realpath;
    "signalfd" >:: test_signalfd;
    "resource" >::: test_resource;
    "strtime" >:: test_strtime;
    "pts" >:: test_pts;
    "execinfo" >:: test_execinfo;
    "statvfs" >:: test_statvfs;
    "setenv" >:: test_setenv;
    "mkdtemp" >:: test_mkdtemp;
    "memalign" >:: test_memalign;
    "endian" >:: test_endian;
    "endian" >:: test_endian_string;
  ]) in
  ignore (run_test_tt_main (test_decorate wrap tests))

