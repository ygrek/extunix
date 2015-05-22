(**
  Discover features available on this platform.

  There are two stages: actual discover by means of trying to compile snippets of test code
  and generation of config file listing all the discovered features
*)

#warnings "+a-4"

open Printf

type arg = 
  | I of string (* check header file (#include) available (promoted to config) *)
  | T of string (* check type available *)
  | DEFINE of string (* define symbol prior to including header files (promoted to config) *)
  | Z of string (* define symbol to zero if not defined after the includes (promoted to config) *)
  | S of string (* check symbol available (e.g. function name) *)
  | V of string (* check value available (e.g. enum member) *)
  | D of string (* check symbol defined *)
  | F of string * string (* check structure type available and specified field present in it *)

type test =
  | L of arg list
  | ANY of arg list list

type t = YES of (string * arg list) | NO of string

let ocamlc = ref "ocamlc"
let ext_obj = ref ".o"
let verbose = ref 1
let disabled = ref []

let print_define b s = bprintf b "#define %s\n" s
let print_include b s = bprintf b "#include <%s>\n" s
let print_zdefine b s = bprintf b "#ifndef %s\n#define %s 0\n#endif\n" s s
let filter_map f l = List.rev (List.fold_left (fun acc x -> match f x with Some s -> s::acc | None -> acc) [] l)
let get_defines = filter_map (function DEFINE s -> Some s | _ -> None)
let get_zdefines = filter_map (function Z s -> Some s | _ -> None)
let get_includes = filter_map (function I s -> Some s | _ -> None)

let config_defines = [
  "_POSIX_C_SOURCE 200809L";
  "_XOPEN_SOURCE 700";
  "_BSD_SOURCE";
  "_DARWIN_C_SOURCE";
  "_LARGEFILE64_SOURCE";
  "WIN32_LEAN_AND_MEAN";
  "_WIN32_WINNT 0x500";
  "CAML_NAME_SPACE";
  "_GNU_SOURCE"
  ]

let config_includes = [
  "caml/memory.h";
  "caml/fail.h";
  "caml/unixsupport.h";
  "caml/signals.h";
  "caml/alloc.h";
  "caml/custom.h";
  "caml/bigarray.h";
  "string.h";
  "errno.h";
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
    | I _ -> ()
    | T s -> pr "%s var_%d;" s (fresh ())
    | DEFINE _ -> ()
    | Z _ -> () (* no test required *)
    | D s -> pr "#ifndef %s" s; pr "#error %s not defined" s; pr "#endif"
    | S s -> pr "size_t var_%d = (size_t)&%s;" (fresh ()) s
    | V s -> pr "int var_%d = (0 == %s);" (fresh ()) s
    | F (s,f) -> pr "size_t var_%d = (size_t)&((struct %s*)0)->%s;" (fresh ()) s f
    end args;
  pr "int main() { return 0; }";
  Buffer.contents b

let dev_null = match Sys.os_type with "Win32" -> "NUL" | _ -> "/dev/null"

let execute code =
  let (tmp,ch) = Filename.open_temp_file "discover" ".c" in
  output_string ch code;
  flush ch;
  close_out ch;
  let cmd = sprintf "%s -c %s%s" !ocamlc (Filename.quote tmp) (if !verbose >= 1 then "" else " 2> " ^ dev_null) in
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
        if !verbose >= 2 then prerr_endline code;
        print_endline "failed"; NO name
    | false, (x::xs) -> loop x xs
    | true, _ -> print_endline "ok"; YES (name,args)
  in
  match List.mem name !disabled with
  | true -> print_endline "disabled"; NO name
  | false ->
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
  pr "#include \"common.h\"";
  List.iter begin function
    | NO name ->
      pr "";
      pr "#undef EXTUNIX_HAVE_%s" name;
    | YES (name,args) ->
        pr "";
        pr "#define EXTUNIX_HAVE_%s" name;
        match get_includes args, get_zdefines args with
        | [],[] -> ()
        | includes,zdefines ->
          pr "#if defined(EXTUNIX_WANT_%s)" name;
          List.iter (print_include b) includes;
          List.iter (print_zdefine b) zdefines;
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

let features =
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
      S "fstatat"; S "openat"; S "unlinkat"; S "renameat"; S "mkdirat"; S "linkat"; S "symlinkat"; S "readlinkat";
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
      D "ST_RDONLY"; D "ST_NOSUID";
      Z "ST_NODEV"; Z "ST_NOEXEC"; Z "ST_SYNCHRONOUS"; Z "ST_MANDLOCK"; Z "ST_WRITE";
      Z "ST_APPEND"; Z "ST_IMMUTABLE"; Z "ST_NOATIME"; Z "ST_NODIRATIME"; Z "ST_RELATIME";
    ];
    "SIOCGIFCONF", L[
      I "sys/ioctl.h";
      I "net/if.h";
      D "SIOCGIFCONF";
      S "ioctl";
      T "struct ifconf"; T "struct ifreq";
    ];
    "IFADDRS", L[
      I "sys/types.h";
      I "ifaddrs.h";
      S "getifaddrs";
      S "freeifaddrs";
      T "struct ifaddrs";
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
    "GETTID", L[ I "sys/syscall.h"; S "syscall"; V "SYS_gettid"; ];
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
    "SYNC", L[ I "unistd.h"; S "sync"];
    "SYNCFS", ANY[
      [I "unistd.h"; S "syncfs"];
      [DEFINE "EXTUNIX_USE_SYS_SYNCFS"; I "unistd.h"; I "sys/syscall.h"; S"syscall"; V"SYS_syncfs"];
    ];
    "REALPATH", L[ I "limits.h"; I "stdlib.h"; S "realpath"; ];
    "SIGNALFD", L[ I "sys/signalfd.h"; S "signalfd"; I "signal.h"; S "sigemptyset"; S "sigaddset"; ];
    "PTRACE", L[ I "sys/ptrace.h"; S "ptrace"; V "PTRACE_TRACEME"; V "PTRACE_ATTACH"; ];
    "RESOURCE", L[
      I "sys/time.h"; I "sys/resource.h";
      S "getpriority"; S "setpriority"; S "getrlimit"; S "setrlimit";
      V "PRIO_PROCESS"; V "RLIMIT_NOFILE"; V "RLIM_INFINITY";
      ];
    "MLOCKALL", L[ I "sys/mman.h"; S "mlockall"; S "munlockall"; V "MCL_CURRENT"; V "MCL_FUTURE"; ];
    "STRTIME", L[ I "time.h"; S"strptime"; S"strftime"; S"asctime_r"; S"tzset"; S"tzname"; ];
    "TIMEZONE", L[ I "time.h"; S"tzset"; S"timezone"; S"daylight" ];
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
    "MALLOC_INFO", L[ I"malloc.h"; S"malloc_info"; ];
    "MALLOC_STATS", L[ I"malloc.h"; S"malloc_stats"; ];
    "MEMALIGN", L[ I "stdlib.h"; S"posix_memalign"; ];
    "ENDIAN", L[ I "endian.h";
		 D"htobe16"; D"htole16"; D"be16toh"; D"le16toh";
		 D"htobe32"; D"htole32"; D"be32toh"; D"le32toh";
		 D"htobe64"; D"htole64"; D"be64toh"; D"le64toh"; ];
    "READ_CREDENTIALS", L[ I"sys/types.h"; I"sys/socket.h"; D"SO_PEERCRED"; ];
    "FEXECVE", L[ I "unistd.h"; S"fexecve"; ];
    "SENDMSG", ANY[
      [ I"sys/types.h"; I"sys/socket.h"; S"sendmsg"; S"recvmsg"; D"CMSG_SPACE"; ];
      [ I"sys/types.h"; I"sys/socket.h"; S"sendmsg"; S"recvmsg"; F("msghdr","msg_accrights"); ];
    ];
    "PREAD", L[ I "unistd.h"; S"pread"; ];
    "PWRITE", L[ I "unistd.h"; S"pwrite"; ];
    "READ", L[ I "unistd.h"; S"read"; ];
    "WRITE", L[ I "unistd.h"; S"write"; ];
    "MKSTEMPS", L[ I "stdlib.h"; S"mkstemps"; ];
    "MKOSTEMPS", L[ I "stdlib.h"; S"mkostemps"; ];
    "SETRESUID", L[ I"sys/types.h"; I"unistd.h"; S"setresuid"; S"setresgid" ];
    "SYSCONF", L[
      I "unistd.h";
      S "sysconf";
      (* check for standard values and extensions *)
      D "_SC_VERSION"; D "_SC_2_VERSION";
      D "_SC_PHYS_PAGES"; D "_SC_AVPHYS_PAGES"; D "_SC_NPROCESSORS_CONF"; D "_SC_NPROCESSORS_ONLN";
    ];
    "SPLICE", L[ I "fcntl.h"; S"splice"; ];
    "TEE", L[ I "fcntl.h"; S"tee"; ];
    "VMSPLICE", L[ I "fcntl.h"; S"vmsplice"; ];
    "SOCKOPT", L[
      I "sys/socket.h"; I "netinet/in.h"; I"netinet/tcp.h";
      S"setsockopt"; S"getsockopt";
    ];
    "TCP_KEEPCNT", L[I"netinet/in.h"; I"netinet/tcp.h";V"TCP_KEEPCNT"];
    "TCP_KEEPIDLE", L[I"netinet/in.h"; I"netinet/tcp.h";V"TCP_KEEPIDLE"];
    "TCP_KEEPINTVL", L[I"netinet/in.h"; I"netinet/tcp.h";V"TCP_KEEPINTVL"];
    "POLL", L[ I "poll.h"; S "poll"; D "POLLIN"; D "POLLOUT"; Z "POLLRDHUP" ];
    "SYSINFO", L[ I"sys/sysinfo.h"; S"sysinfo"; F ("sysinfo","mem_unit")];
    "MCHECK", L[ I"mcheck.h"; S"mtrace"; S"muntrace" ];
  ]

let () = 
  let args0 = [
    "-ocamlc", Arg.Set_string ocamlc, "<path> ocamlc";
    "-ext_obj", Arg.Set_string ext_obj, "<ext> C object files extension";
    "-v", Arg.Unit (fun () -> verbose := 2), " Show code for failed tests";
    "-q", Arg.Unit (fun () -> verbose := 0), " Do not show stderr from children";
  ] in
  let args1 = List.map (fun (name,_) ->
    assert (not (String.contains name ' '));
    "--disable-" ^ String.lowercase name,
    Arg.Unit (fun () -> disabled := name :: !disabled),
    " disable " ^ name) features 
  in
  let args = Arg.align (args0 @ args1) in
  Arg.parse args failwith ("Options are:");
  main features

