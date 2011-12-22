(** *)

open Printf

type arg = 
  | I of string (* check #include available *)
  | T of string (* check type available *)
  | DEFINE of string (* define *)
  | S of string (* check symbol available *)
  | V of string (* check value available (enum) *)
  | D of string (* check symbol defined *)

type test =
  | L of arg list
  | ANY of arg list list

type t = YES of (string * arg list) | NO of string

let ocamlc = ref "ocamlc"
let ext_obj = ref ".o"
let verbose = ref false

let () =
  let args = [
    "-ocamlc", Arg.Set_string ocamlc, "<path> ocamlc";
    "-ext_obj", Arg.Set_string ext_obj, "<ext> C object files extension";
    "-v", Arg.Set verbose, " Show code for failed tests";
  ] in
  Arg.parse args (failwith) ("Options are:")

let print_define b s = bprintf b "#define %s\n" s
let print_include b s = bprintf b "#include <%s>\n" s
let filter_map f l = List.fold_left (fun acc x -> match f x with Some s -> s::acc | None -> acc) [] l
let get_defines = filter_map (function DEFINE s -> Some s | _ -> None)
let get_includes = filter_map (function I s -> Some s | _ -> None)

let config_defines = [
  "_POSIX_C_SOURCE 200112L";
  "_XOPEN_SOURCE 600";
  "_BSD_SOURCE";
  "_LARGEFILE64_SOURCE";
  "WIN32_LEAN_AND_MEAN";
  "_WIN32_WINNT 0x500";
  "CAML_NAME_SPACE";
  ]

let config_includes = [
  "caml/memory.h";
  "caml/fail.h";
  "caml/unixsupport.h";
  "caml/signals.h";
  "caml/alloc.h";
  "caml/custom.h";
  ]

let build_code args =
  let b = Buffer.create 10 in
  let pr fmt = ksprintf (fun s -> Buffer.add_string b (s^"\n")) fmt in
  let fresh = let n = ref 0 in fun () -> incr n; !n in
  List.iter (print_define b) config_defines;
  List.iter (print_define b) (get_defines args);
  List.iter (print_include b) config_includes;
  List.iter (print_include b) (get_includes args);
(*  pr "#include <stddef.h>"; (* size_t *)*)
  List.iter begin function
    | I s -> ()
    | T s -> pr "%s var_%d;" s (fresh ())
    | DEFINE s -> ()
    | D s -> pr "#ifndef %s" s; pr "#error %s not defined" s; pr "#endif"
    | S s -> pr "size_t var_%d = (size_t)&%s;" (fresh ()) s
    | V s -> pr "int var_%d = (0 == %s);" (fresh ()) s
    end args;
  pr "int main() { return 0; }";
  Buffer.contents b

let execute code =
  let (tmp,ch) = Filename.open_temp_file "discover" ".c" in
  output_string ch code;
  flush ch;
  close_out ch;
  let cmd = sprintf "%s -c %s" !ocamlc (Filename.quote tmp) in
  let ret = Sys.command cmd in
  Sys.remove tmp;
  (* assumption: C compiler puts object file in current directory *)
  let base = Filename.chop_extension (Filename.basename tmp) in
  begin try Sys.remove (base ^ !ext_obj) with Sys_error _ -> () end;
  ret = 0

let discover (name,test) =
  print_string ("checking " ^ name ^ (String.make (20 - String.length name) '.'));
  let rec loop args other =
    let code = build_code args in
    match execute code, other with
    | false, [] -> 
        if !verbose then prerr_endline code;
        print_endline "failed"; NO name
    | false, (x::xs) -> loop x xs
    | true, _ -> print_endline "ok"; YES (name,args)
  in
  match test with
  | L l -> loop l []
  | ANY (x::xs) -> loop x xs
  | ANY [] -> assert false

let show_c file result =
  let b = Buffer.create 10 in
  let pr fmt = ksprintf (fun s -> Buffer.add_string b (s^"\n")) fmt in
  pr "";
  List.iter (print_define b) config_defines;
  List.iter begin function
    | NO _ -> ();
    | YES (name,args) ->
        match get_defines args with
        | [] -> ()
        | l ->
          pr "";
          pr "#if defined(EXTUNIX_WANT_%s)" name;
          List.iter (print_define b) l;
          pr "#endif";
  end result;
  pr "";
  List.iter (print_include b) config_includes;
  List.iter begin function
    | NO name ->
      pr "";
      pr "#undef EXTUNIX_HAVE_%s" name;
    | YES (name,args) ->
        pr "";
        pr "#define EXTUNIX_HAVE_%s" name;
        match get_includes args with
        | [] -> ()
        | l ->
          pr "#if defined(EXTUNIX_WANT_%s)" name;
          List.iter (print_include b) l;
          pr "#endif";
  end result;
  pr "";
  let ch = open_out file in
  Buffer.output_buffer ch b;
  close_out ch

let show_ml file result =
  let ch = open_out file in
  let pr fmt = ksprintf (fun s -> output_string ch (s^"\n")) fmt in
  pr "let have = function";
  List.iter (function
  | YES (name,_) -> pr "| %S -> Some true" name
  | NO name -> pr "| %S -> Some false" name) result;
  pr "| _ -> None";
  close_out ch

let main config =
  let result = List.map discover config in
  show_c "src/config.h" result;
  show_ml "src/config.ml" result

let () = 
  main 
  [
    "EVENTFD", L[
      I "sys/eventfd.h";
      T "eventfd_t";
      S "eventfd"; S "eventfd_read"; S "eventfd_write";
    ];
    "ATFILE", L[
      DEFINE "_ATFILE_SOURCE";
      I "fcntl.h";
      I "sys/types.h"; I "sys/stat.h";
      I "unistd.h"; I "stdio.h";
      D "S_IFREG";
      S "fstatat"; S "openat"; S "unlinkat"; S "renameat"; S "mkdirat"; S "linkat"; S "symlinkat";
    ];
    "DIRFD", L[
      I "sys/types.h";
      I "dirent.h";
      S "dirfd";
    ];
    "STATVFS", L[
      I "sys/statvfs.h";
      T "struct statvfs";
      S "statvfs"; S "fstatvfs";
    ];
    "SIOCGIFCONF", L[
      I "sys/ioctl.h";
      I "net/if.h";
      D "SIOCGIFCONF";
      S "ioctl";
      T "struct ifconf"; T "struct ifreq";
    ];
    "INET_NTOA", L[
      I "sys/socket.h";
      I "netinet/in.h";
      I "arpa/inet.h";
      S "inet_ntoa";
    ];
    "UNAME", L[
      I "sys/utsname.h";
      T "struct utsname";
      S "uname";
    ];
    "FADVISE", L[
      I "fcntl.h";
      S "posix_fadvise"; S "posix_fadvise64";
      D "POSIX_FADV_NORMAL";
    ];
    "FALLOCATE", ANY[
      [I "fcntl.h"; S "posix_fallocate"; S" posix_fallocate64"; ];
      [D "WIN32"; S "GetFileSizeEx"; ];
    ];
    "TTY_IOCTL", L[
      I "termios.h"; I "sys/ioctl.h";
      S "ioctl"; S "tcsetattr"; S "tcgetattr";
      D "CRTSCTS"; D "TCSANOW"; D "TIOCMGET"; D "TIOCMSET"; D "TIOCMBIC"; D "TIOCMBIS";
    ];
    "TTYNAME", L[ I "unistd.h"; S "ttyname"; ];
    "CTERMID", L[ I "stdio.h"; S "ctermid"; V "L_ctermid"; ];
    "PGID", L[ I "unistd.h"; S "getpgid"; S "setpgid"; S "getsid"; ];
    "SETREUID", L[ I "sys/types.h"; I "unistd.h"; S "setreuid"; S "setregid" ];
    "FSYNC", ANY[
      [I "unistd.h"; S "fsync";];
      [D "WIN32"; S "FlushFileBuffers"; ];
    ];
    "FDATASYNC", ANY[
      [I "unistd.h"; S "fdatasync";];
      [D "WIN32"; S "FlushFileBuffers"; ];
    ];
    "REALPATH", L[ I "limits.h"; I "stdlib.h"; S "realpath"; ];
    "SIGNALFD", L[ I "sys/signalfd.h"; S "signalfd"; I "signal.h"; S "sigemptyset"; S "sigaddset"; I "errno.h"; D "EINVAL"; ];
    "PTRACE", L[ I "sys/ptrace.h"; S "ptrace"; V "PTRACE_TRACEME"; V "PTRACE_ATTACH"; ];
    "RESOURCE", L[
      I "sys/time.h"; I "sys/resource.h";
      S "getpriority"; S "setpriority"; S "getrlimit"; S "setrlimit";
      V "PRIO_PROCESS"; V "RLIMIT_NOFILE"; V "RLIM_INFINITY";
      ];
    "MLOCKALL", L[ I "sys/mman.h"; S "mlockall"; S "munlockall"; V "MCL_CURRENT"; V "MCL_FUTURE"; ];
    "STRTIME", L[ I "time.h"; S"strptime"; S"strftime"; S"asctime_r"; S"tzname"; ];
    "PTS", L[
      I "fcntl.h"; I "stdlib.h";
      S "posix_openpt"; S "grantpt"; S "unlockpt"; S "ptsname";
    ];
    "FCNTL", L[ I"unistd.h"; I"fcntl.h"; S"fcntl"; V"F_GETFL"; ];
    "TCPGRP", L[ I"unistd.h"; S"tcgetpgrp"; S"tcsetpgrp"; ];
    "EXECINFO", L[ I"execinfo.h"; S"backtrace"; S"backtrace_symbols"; ];
    "SETENV", L[ I"stdlib.h"; S"setenv"; S"unsetenv"; ];
    "CLEARENV", L[ I"stdlib.h"; S"clearenv"; ];
    "MKDTEMP", L[ I"stdlib.h"; S"mkdtemp"; ];
    "TIMEGM", L[ I"time.h"; S"timegm"; ];
  ]

