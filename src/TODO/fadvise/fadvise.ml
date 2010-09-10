
(** Binding to posix_fadvice 
    @author Sylvain Le Gall
  *)

type advice =
  | POSIX_FADV_NORMAL     (** Indicates that the application has no advice to
                              give about its access pattern for the specified
                              data.
                            *)

  | POSIX_FADV_SEQUENTIAL (** The application expects to access the specified
                              data sequentially.
                            *)

  | POSIX_FADV_RANDOM     (** The specified data will be accessed in random
                              order.
                            *)

  | POSIX_FADV_NOREUSE    (** The specified data will be accessed only once.
                            *)

  | POSIX_FADV_WILLNEED   (** The specified data will be accessed in the near
                              future.
                            *)

  | POSIX_FADV_DONTNEED   (** The specified data will not be accessed in the
                              near future.
                            *)
;;

external fadvise: UnixExt.file_descr_in -> int -> int -> advice -> unit =
  "caml_filescale_fadvise"
;;

module LargeFile =
struct
  external fadvise: UnixExt.file_descr_in -> int64 -> int64 -> advice -> unit =
    "caml_filescale_fadvise64"
end
;;
