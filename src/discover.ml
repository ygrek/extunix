(** *)

open Printf

type arg = 
  | I of string (* check #include available *)
  | T of string (* check type available *)
  | D of string (* define *)
  | S of string (* check symbol available *)
  | IFDEF of string (* check #ifdef *)

type test =
  | L of arg list
  | ANY of arg list list

type t = YES of (string * arg list) | NO of string

(* FIXME *)
let cc = ref "ocamlc -c -ccopt \"-Wall -Wextra -std=c89 -pedantic -o /dev/null\""

let build_code args =
  let b = Buffer.create 10 in
  let pr fmt = ksprintf (fun s -> Buffer.add_string b (s^"\n")) fmt in
  let fresh = let n = ref 0 in fun () -> incr n; !n in
  pr "#define _POSIX_C_SOURCE 200112L";
  pr "#define _XOPEN_SOURCE 600";
  pr "#define _BSD_SOURCE";
  pr "#define _LARGEFILE64_SOURCE";
  pr "#include <stddef.h>"; (* size_t *)
  List.iter begin function
    | I s -> pr "#include <%s>" s
    | T s -> pr "%s var_%d;" s (fresh ())
    | D s -> pr "#define %s" s
    | IFDEF s -> pr "#ifndef %s" s; pr "#error %s not defined" s; pr "#endif"
    | S s -> pr "size_t var_%d = (size_t)&%s;" (fresh ()) s
    end args;
  bprintf b "int main() { return 0; }\n";
  Buffer.contents b

let execute code =
  let (tmp,ch) = Filename.open_temp_file "discover" ".c" in
  output_string ch code;
  flush ch;
  let cmd = sprintf "%s %s" !cc (Filename.quote tmp) in
  let ret = Sys.command cmd in
  close_out ch;
  Sys.remove tmp;
  ret = 0

let discover (name,test) =
  let rec loop args other =
    let code = build_code args in
    match execute code, other with
    | false, [] -> prerr_endline code; NO name
    | false, (x::xs) -> loop x xs
    | true, _ -> YES (name,args)
  in
  match test with
  | L l -> loop l []
  | ANY (x::xs) -> loop x xs
  | ANY [] -> assert false

let show_c file result =
  let ch = open_out file in
  let pr fmt = ksprintf (fun s -> output_string ch (s^"\n")) fmt in
  pr "/* start discover */";
  pr "#define _POSIX_C_SOURCE 200112L";
  pr "#define _XOPEN_SOURCE 600";
  pr "#define _BSD_SOURCE";
  pr "#define _LARGEFILE64_SOURCE";
  pr "";
  List.iter begin function
    | YES (name,args) ->
        pr "#define HAVE_%s" name;
        pr "#if defined(WANT_%s)" name;
        List.iter (function
          | I s -> pr "#include <%s>" s
          | D s -> pr "#define %s" s
          | S _ | T _ | IFDEF _ -> ()) args;
        pr "#endif";
        pr "";
    | NO name ->
      pr "#undef HAVE_%s" name;
      pr "";
  end result;
  pr "/* discover done */";
  pr "";
  pr "#define CAML_NAME_SPACE";
  pr "#include <caml/memory.h>";
  pr "#include <caml/fail.h>";
  pr "#include <caml/unixsupport.h>";
  pr "#include <caml/signals.h>";
  pr "#include <caml/alloc.h>";
  pr "";
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
      D "_ATFILE_SOURCE";
      I "fcntl.h";
      I "sys/types.h";
      I "sys/stat.h";
      I "unistd.h";
      IFDEF "S_IFREG"; IFDEF "O_DSYNC";
      S "fstatat"; S "openat"; S "unlinkat";
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
      IFDEF "SIOCGIFCONF";
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
      IFDEF "POSIX_FADV_NORMAL";
    ];
    "FALLOCATE", ANY[
      [I "fcntl.h"; S "posix_fallocate"; S" posix_fallocate64"; ];
      [IFDEF "WINDOWS"];
    ];
    "TTY_IOCTL", L[
      I "termios.h"; I "sys/ioctl.h";
      S "ioctl"; S "tcsetattr"; S "tcgetattr";
      IFDEF "CRTSCTS"; IFDEF "TCSANOW"; IFDEF "TIOCMGET"; IFDEF "TIOCMSET"; IFDEF "TIOCMBIC"; IFDEF "TIOCMBIS";
    ];
    "TTYNAME", L[ I "unistd.h"; S "ttyname"; ];
    "PGID", L[ I "unistd.h"; S "getpgid"; S "setpgid" ];
    "SETREUID", L[ I "sys/types.h"; I "unistd.h"; S "setreuid"; S "setregid" ];
    "FSYNC", ANY[
      [I "unistd.h"; S "fsync"; S "fdatasync"; ];
      [IFDEF "WINDOWS"];
    ];
    "REALPATH", L[ I "limits.h"; I "stdlib.h"; S "realpath"; ];
  ]

