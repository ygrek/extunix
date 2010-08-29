(** ExtUnix *)

INCLUDE "src/config.ml"

external fsync : Unix.file_descr -> unit = "caml_extunix_fsync"

IFDEF HAVE_EVENTFD THEN
external eventfd : int -> Unix.file_descr = "caml_extunix_eventfd"
external eventfd_read : Unix.file_descr -> int64 = "caml_extunix_eventfd_read"
external eventfd_write : Unix.file_descr -> int64 -> unit = "caml_extunix_eventfd_write"
ENDIF

IFDEF HAVE_DIRFD THEN
external dirfd : Unix.dir_handle -> Unix.file_descr = "caml_extunix_dirfd"
ENDIF

IFDEF HAVE_STATVFS THEN
type statvfs = { vfs_bsize : int; vfs_blocks : int64; vfs_bfree : int64; vfs_inodes : int64; vfs_ifree : int64; }
external statvfs : string -> statvfs = "caml_extunix_statvfs"
external fstatvfs : Unix.file_descr -> statvfs = "caml_extunix_fstatvfs"
ENDIF

