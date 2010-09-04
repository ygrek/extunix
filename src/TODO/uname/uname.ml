
(** Main interface of uname.
    @author Sylvain Le Gall <sylvain@le-gall.net>
  *)

open UnameConfig;;

(** {1 Type and exception}
  *)

type t =
    {
      sysname:    string;
      nodename:   string;
      release:    string;
      version:    string;
      machine:    string;
    }
;;

(** OS doesn't support uname syscall
  *)
exception NoOSSupport;;

(** {1 Interface } 
  *)

let version = version
;;

let string_of_exception exc =
  match exc with
    NoOSSupport ->
      "Uname syscall not supported on this OS"
  | _ ->
      raise exc
;;

let to_string t = 
  String.concat " "
    [
      t.sysname;
      t.nodename;
      t.release;
      t.version;
      t.machine
    ]
;;

let _ = 
  (* Register exception for callback *)
  Callback.register_exception 
    "caml_uname_no_os_support" 
    NoOSSupport
;;

external uname: unit -> t = "caml_uname"
;;


