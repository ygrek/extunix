
(** Allocate disk space for file
    @author Sylvain Le Gall
  *)

(** This exceptionn is raise if there is no support for fallocate
    for the underlying OS or filesystem. "fallocate" system call is
    not supported on every filesystem (though it can be emulated).

    At the time of writing, only ext4 support direct fallocate call
    (2009/02/25). Other filesystem are handled using posix_fallocate.
  *)
exception NotSupported;;

let () = 
  Callback.register_exception 
    "Fallocate.NotSupported" 
    NotSupported
;;

(** [fallocate fd off len] Allocate disk space to ensure that write
    between [off] and [off + len] in [fd] will not failed. The file
    size if modified if [off + len] is bigger than the actual size.

    [off] and [len] must be strictly positive.
  *)
external fallocate: Unix.file_descr -> int -> int -> unit =
  "caml_fallocate"
;;

module LargeFile =
struct

  (* Support operation on large file, see {!fallocate}. *)
  external fallocate: Unix.file_descr -> int64 -> int64 -> unit =
    "caml_fallocate64"
end
;;

