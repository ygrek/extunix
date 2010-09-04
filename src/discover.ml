(** *)

open Printf

type arg = 
  | I of string (* check #include available *)
  | T of string (* check type available *)
  | D of string (* define *)
  | S of string (* check symbol available *)
  | IFDEF of string (* check #ifdef *)

type t = YES of (string * arg list) | NO of string

let cc = ref "gcc -Wall -o /dev/null"
let null = ref "/dev/null"

let build_code args =
  let b = Buffer.create 10 in
  let fresh = let n = ref 0 in fun () -> incr n; !n in
  List.iter begin function
    | I s -> bprintf b "#include <%s>\n" s
    | T s -> bprintf b "%s var_%d;\n" s (fresh ())
    | D s -> bprintf b "#define %s\n" s
    | IFDEF s -> bprintf b "#ifndef %s\nabort, %s not defined\n#endif\n" s s
    | S s -> bprintf b "void* var_%d = &%s;\n" (fresh ()) s
    end args;
  bprintf b "int main() { return 0; }\n";
  Buffer.contents b

let discover (name,args) =
  let code = build_code args in
  let (tmp,ch) = Filename.open_temp_file "discover" ".c" in
  output_string ch code;
  flush ch;
  let cmd = sprintf "%s %s > %s" !cc (Filename.quote tmp) !null in
  let ret = Sys.command cmd in
  close_out ch;
  Sys.remove tmp;
  if ret = 0 then YES (name,args) else (prerr_endline code; NO name)

let show_c file result =
  let ch = open_out file in
  let pr fmt = ksprintf (fun s -> output_string ch (s^"\n")) fmt in
  pr "/* start discover */";
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
    "EVENTFD", [
      I "sys/eventfd.h";
      T "eventfd_t";
      S "eventfd"; S "eventfd_read"; S "eventfd_write";
    ];
    "ATFILE", [
      D "_ATFILE_SOURCE";
      I "fcntl.h";
      I "sys/stat.h";
      I "unistd.h";
      S "fstatat"; S "openat"; S "unlinkat";
    ];
    "DIRFD", [
      D "_BSD_SOURCE";
      I "sys/types.h";
      I "dirent.h";
      S "dirfd";
    ];
    "STATVFS", [
      I "sys/statvfs.h";
      T "struct statvfs";
      S "statvfs"; S "fstatvfs";
    ];
    "SIOCGIFCONF", [
      I "sys/ioctl.h";
      I "net/if.h";
      IFDEF "SIOCGIFCONF";
      S "ioctl";
      T "struct ifconf"; T "struct ifreq";
    ];
    "INET_NTOA", [
      I "sys/socket.h";
      I "netinet/in.h";
      I "arpa/inet.h";
      S "inet_ntoa";
    ];
  ]

