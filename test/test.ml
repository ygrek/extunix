
open OUnit
open ExtUnix.All

let with_unix_error f () =
  try f ()
  with Unix.Unix_error(e,f,a) -> assert_failure (Printf.sprintf "Unix_error : %s(%s) : %s" f a (Unix.error_message e))

let require feature =
  match have feature with
  | None -> assert false
  | Some present -> skip_if (not present) (Printf.sprintf "%S is not available" feature)

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
  let printer x = x in
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
    let (soft,hard) = getrlimit r in
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
  assert_equal ~printer:(fun x -> x) "2010/12/14" (strftime "%Y/%m/%d" (strptime "%Y-%m-%d" "2010-12-14"));
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
  assert_bool "backtrace" ([||] <> backtrace ())

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
  ]) in
  ignore (run_test_tt_main (test_decorate wrap tests))

