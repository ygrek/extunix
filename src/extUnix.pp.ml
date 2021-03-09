(** ExtUnix

These functions are thin wrappers for underlying system API, consult
the corresponding man pages and/or system documentation for details.
*)

(** [Not_available "symbol"] may be raised by functions in {!ExtUnix.All}
    if the wrapped C function or constant is not available on this platform.

    {!ExtUnix.Specific} includes only functions available on the current
    platform and will not raise [Not_available].
    Note that libc wrappers underlying {!ExtUnix.Specific} functions may still raise
    [ENOSYS] (Not implemented) error even though the function is available. *)
exception Not_available of string

(** type of bigarray used by BA submodules that read from files into
    bigarrays or write bigarrays into files.  The only constraint here
    is [Bigarray.c_layout].

    Naming: "bigarray with C layout" -> "carray". *)
type ('a, 'b) carray =
    ('a, 'b, Bigarray.c_layout) Bigarray.Array1.t

(** type of bigarray used by BA submodules that work with endianness
    and memory.  Constraints are:
    + [Bigarray.c_layout],
    + bigarray contains 8-bit integers.

    Naming: "bigarray with C layout and 8-bit elements" -> "carray8". *)
type 'a carray8 =
    ('a, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t

type open_flag = Unix.open_flag
(*
  = O_RDONLY | O_WRONLY | O_RDWR | O_NONBLOCK | O_APPEND | O_CREAT
  | O_TRUNC | O_EXCL | O_NOCTTY | O_DSYNC | O_SYNC | O_RSYNC
  | O_SHARE_DELETE | O_CLOEXEC
*)

[%%have EVENTFD
external eventfd : int -> Unix.file_descr = "caml_extunix_eventfd"
external eventfd_read : Unix.file_descr -> int64 = "caml_extunix_eventfd_read"
external eventfd_write : Unix.file_descr -> int64 -> unit = "caml_extunix_eventfd_write"
]

[%%have SYSLOG
module Syslog : sig
type options = LOG_PID | LOG_CONS | LOG_NDELAY | LOG_ODELAY | LOG_NOWAIT
type facility = LOG_KERN | LOG_USER | LOG_MAIL | LOG_NEWS | LOG_UUCP
    | LOG_DAEMON | LOG_AUTH | LOG_CRON | LOG_LPR | LOG_LOCAL0 | LOG_LOCAL1
    | LOG_LOCAL2 | LOG_LOCAL3 | LOG_LOCAL4 | LOG_LOCAL5 | LOG_LOCAL6
    | LOG_LOCAL7
type level = LOG_EMERG | LOG_ALERT | LOG_CRIT | LOG_ERR | LOG_WARNING
    | LOG_NOTICE | LOG_INFO | LOG_DEBUG
val setlogmask : level list -> level list
val openlog : ?ident:string -> options list -> facility -> unit
val closelog : unit -> unit
val syslog : ?facility:facility -> level -> ('a, unit, string, unit) format4 -> 'a
val log_upto : level -> level list
end = struct
type options = LOG_PID | LOG_CONS | LOG_NDELAY | LOG_ODELAY | LOG_NOWAIT
type facility = LOG_KERN | LOG_USER | LOG_MAIL | LOG_NEWS | LOG_UUCP
    | LOG_DAEMON | LOG_AUTH | LOG_CRON | LOG_LPR | LOG_LOCAL0 | LOG_LOCAL1
    | LOG_LOCAL2 | LOG_LOCAL3 | LOG_LOCAL4 | LOG_LOCAL5 | LOG_LOCAL6
    | LOG_LOCAL7
type level = LOG_EMERG | LOG_ALERT | LOG_CRIT | LOG_ERR | LOG_WARNING
    | LOG_NOTICE | LOG_INFO | LOG_DEBUG
external setlogmask : level list -> level list = "caml_extunix_setlogmask"
external openlog : ?ident:string -> options list -> facility -> unit = "caml_extunix_openlog"
external closelog : unit -> unit = "caml_extunix_closelog"
external ext_syslog : facility option -> level -> string -> unit = "caml_extunix_syslog"
let syslog ?facility lvl = Printf.ksprintf (ext_syslog facility lvl)
let log_upto lvl =
  let rec f = function
    | [] -> assert false
    | x::xs -> if x=lvl then x::xs else f xs
  in
  f [LOG_DEBUG; LOG_INFO; LOG_NOTICE; LOG_WARNING; LOG_ERR; LOG_CRIT;
      LOG_ALERT; LOG_EMERG]
end
]

[%%have UNAME

(** @author Sylvain Le Gall <sylvain@le-gall.net> *)
module Uname = struct
type t =
    {
      sysname:    string;
      nodename:   string;
      release:    string;
      version:    string;
      machine:    string;
    }

let to_string t =
  String.concat " " [ t.sysname; t.nodename; t.release; t.version; t.machine ]
end

external uname : unit -> Uname.t = "caml_extunix_uname"

]

(** {2 Filesystem} *)

[%%have FSYNC

(** synchronize a file's in-core state with storage device *)
external fsync : Unix.file_descr -> unit = "caml_extunix_fsync"
]

[%%have FDATASYNC
external fdatasync : Unix.file_descr -> unit = "caml_extunix_fdatasync"
]

[%%have SYNC

(** causes all buffered modifications to file metadata and data to be written to the underlying file systems *)
external sync : unit -> unit = "caml_extunix_sync"
]

[%%have SYNCFS

(** like {!sync}, but synchronizes just the file system containing file referred to by the open file descriptor [fd] *)
external syncfs : Unix.file_descr -> unit = "caml_extunix_syncfs"
]

[%%have DIRFD
external dirfd : Unix.dir_handle -> Unix.file_descr = "caml_extunix_dirfd"
]

[%%have STATVFS

(** file system flags *)
type st_flag =
  | ST_RDONLY       (** Mount read-only. *)
  | ST_NOSUID       (** Ignore suid and sgid bits. *)
  | ST_NODEV        (** Disallow access to device special files. *)
  | ST_NOEXEC       (** Disallow program execution. *)
  | ST_SYNCHRONOUS  (** Writes are synced at once. *)
  | ST_MANDLOCK     (** Allow mandatory locks on an FS. *)
  | ST_WRITE        (** Write on file/directory/symlink. *)
  | ST_APPEND       (** Append-only file. *)
  | ST_IMMUTABLE    (** Immutable file. *)
  | ST_NOATIME      (** Do not update access times. *)
  | ST_NODIRATIME   (** Do not update directory access times. *)
  | ST_RELATIME     (** Update atime relative to mtime/ctime. *)

type statvfs = {
  f_bsize : int; (** file system block size *)
  f_blocks : int64; (** size of file system in blocks *)
  f_bfree : int64; (** free blocks *)
  f_bavail : int64; (** free blocks for unprivileged users *)
  f_files : int64; (** inodes *)
  f_ffree : int64; (** free inodes *)
  f_favail : int64; (** free inodes for unprivileged users *)
  f_fsid : int64; (** file system ID *)
  f_flag : int; (** mount flags (raw value) *)
  f_flags : st_flag list; (** mount flags (decoded) *)
  f_namemax : int; (** maximum filename length *)
}
external statvfs : string -> statvfs = "caml_extunix_statvfs"
external fstatvfs : Unix.file_descr -> statvfs = "caml_extunix_fstatvfs"
]

[%%have ATFILE
(*
external at_fdcwd : unit -> Unix.file_descr

(** Pseudo file descriptor denoting current directory *)
let at_fdcwd = at_fdcwd ()
*)

type at_flag = AT_EACCESS | AT_SYMLINK_NOFOLLOW | AT_REMOVEDIR | AT_SYMLINK_FOLLOW | AT_NO_AUTOMOUNT

external openat : Unix.file_descr -> string -> open_flag list -> Unix.file_perm -> Unix.file_descr = "caml_extunix_openat"

(** Supported flags : [AT_SYMLINK_NOFOLLOW AT_NO_AUTOMOUNT] *)
external fstatat : Unix.file_descr -> string -> at_flag list -> Unix.stats = "caml_extunix_fstatat"

(** Supported flags : [AT_REMOVEDIR] *)
external unlinkat : Unix.file_descr -> string -> at_flag list -> unit = "caml_extunix_unlinkat"

external renameat : Unix.file_descr -> string -> Unix.file_descr -> string -> unit = "caml_extunix_renameat"

external mkdirat : Unix.file_descr -> string -> int -> unit = "caml_extunix_mkdirat"

(** Supported flags : [AT_SYMLINK_FOLLOW] *)
external linkat : Unix.file_descr -> string -> Unix.file_descr -> string -> at_flag list -> unit = "caml_extunix_linkat"

external symlinkat : string -> Unix.file_descr -> string -> unit = "caml_extunix_symlinkat"

external readlinkat : Unix.file_descr -> string -> string = "caml_extunix_readlinkat"

external fchownat : Unix.file_descr -> string -> int -> int -> at_flag list -> unit = "caml_extunix_fchownat"

external fchmodat : Unix.file_descr -> string -> int -> at_flag list -> unit = "caml_extunix_fchmodat"
]

(** @raise Not_available if OS does not represent file descriptors as numbers *)
let int_of_file_descr : Unix.file_descr -> int =
  if Obj.is_block (Obj.repr Unix.stdin) then
    fun _ -> raise (Not_available "int_of_file_descr")
  else
    Obj.magic

(** @raise Not_available if OS does not represent file descriptors as numbers *)
let file_descr_of_int : int -> Unix.file_descr =
  if Obj.is_block (Obj.repr Unix.stdin) then
    fun _ -> raise (Not_available "file_descr_of_int")
  else
    Obj.magic

[%%have FCNTL

(** @return whether file descriptor is open *)
external is_open_descr : Unix.file_descr -> bool = "caml_extunix_is_open_descr"
]

[%%have REALPATH

(** [realpath path]
    @return the canonicalized absolute pathname of [path]
*)
external realpath : string -> string = "caml_extunix_realpath"
]


[%%have FADVISE

(** {3 posix_fadvise}

@author Sylvain Le Gall *)

(** access pattern *)
type advice =
  | POSIX_FADV_NORMAL     (** Indicates that the application has no advice to
                              give about its access pattern for the specified
                              data.  *)
  | POSIX_FADV_SEQUENTIAL (** The application expects to access the specified
                              data sequentially.  *)
  | POSIX_FADV_RANDOM     (** The specified data will be accessed in random
                              order.  *)
  | POSIX_FADV_NOREUSE    (** The specified data will be accessed only once.  *)
  | POSIX_FADV_WILLNEED   (** The specified data will be accessed in the near
                              future.  *)
  | POSIX_FADV_DONTNEED   (** The specified data will not be accessed in the
                              near future.  *)

(** predeclare an access pattern for file data *)
external fadvise: Unix.file_descr -> int -> int -> advice -> unit = "caml_extunix_fadvise"

]

[%%have FALLOCATE

(** {3 posix_fallocate} *)
(** Allocate disk space for file

    @author Sylvain Le Gall
  *)

(** [fallocate fd off len] allocates disk space to ensure that subsequent writes
    between [off] and [off + len] in [fd] will not fail because of lack of disk
    space. The file size is modified if [off + len] is bigger than the current size.
  *)
external fallocate: Unix.file_descr -> int -> int -> unit = "caml_extunix_fallocate"

]

[%%have PREAD

(** {3 pread}

    @author Goswin von Brederlow *)

(** [all_pread fd off buf ofs len] reads up to [len] bytes from file
    descriptor [fd] at offset [off] (from the start of the file) into
    the string [buf] at offset [ofs]. The file offset is not changed.

    [all_pread] repeats the read operation until all characters have
    been read or an error occurs. Returns less than the number of
    characters requested on EAGAIN, EWOULDBLOCK or End-of-file but
    only ever returns 0 on End-of-file. Continues the read operation
    on EINTR. Raises an Unix.Unix_error exception in all other
    cases. *)
external unsafe_all_pread: Unix.file_descr -> int -> Bytes.t -> int -> int -> int = "caml_extunix_all_pread"

let all_pread fd off buf ofs len =
  if off < 0 || ofs < 0 || len < 0 || ofs > Bytes.length buf - len
  then invalid_arg "ExtUnix.all_pread"
  else unsafe_all_pread fd off buf ofs len

(** [single_pread fd off buf ifs len] reads up to [len] bytes from
    file descriptor [fd] at offset [off] (from the start of the file)
    into the string [buf] at offset [ofs]. The file offset is not
    changed.

    [single_pread] attempts to read only once. Returns the number of
    characters read or raises an Unix.Unix_error exception. *)
external unsafe_single_pread: Unix.file_descr -> int -> Bytes.t -> int -> int -> int = "caml_extunix_single_pread"

let single_pread fd off buf ofs len =
  if off < 0 || ofs < 0 || len < 0 || ofs > Bytes.length buf - len
  then invalid_arg "ExtUnix.single_pread"
  else unsafe_single_pread fd off buf ofs len

(** [pread fd off buf ofs len] reads up to [len] bytes from file
    descriptor [fd] at offset [off] (from the start of the file) into
    the string [buf] at offset [ofs]. The file offset is not changed.

    [pread] repeats the read operation until all characters have
    been read or an error occurs. Raises an Unix.Unix_error exception
    if 0 characters could be read before an error occurs. Continues
    the read operation on EINTR. Returns the number of characters
    written in all other cases. *)
external unsafe_pread: Unix.file_descr -> int -> Bytes.t -> int -> int -> int = "caml_extunix_pread"

let pread fd off buf ofs len =
  if off < 0 || ofs < 0 || len < 0 || ofs > Bytes.length buf - len
  then invalid_arg "ExtUnix.pread"
  else unsafe_pread fd off buf ofs len

(** [intr_pread fd off buf ofs len] reads up to [len] bytes from file
    descriptor [fd] at offset [off] (from the start of the file) into
    the string [buf] at offset [ofs]. The file offset is not changed.

    [intr_pread] repeats the read operation until all characters have
    been read or an error occurs. Raises an Unix.Unix_error exception
    if 0 characters could be read before an error occurs. Does NOT
    continue on EINTR. Returns the number of characters written in all
    other cases. *)
external unsafe_intr_pread: Unix.file_descr -> int -> Bytes.t -> int -> int -> int = "caml_extunix_intr_pread"

let intr_pread fd off buf ofs len =
  if off < 0 || ofs < 0 || len < 0 || ofs > Bytes.length buf - len
  then invalid_arg "ExtUnix.intr_pread"
  else unsafe_intr_pread fd off buf ofs len
]

[%%have PWRITE

(** {3 pwrite}

    @author Goswin von Brederlow *)

(** [all_pwrite fd off buf ofs len] writes up to [len] bytes from file
    descriptor [fd] at offset [off] (from the start of the file) into
    the string [buf] at offset [ofs]. The file offset is not changed.

    [all_pwrite] repeats the write operation until all characters have
    been written or an error occurs. Returns less than the number of
    characters requested on EAGAIN, EWOULDBLOCK but never 0. Continues
    the write operation on EINTR. Raises an Unix.Unix_error exception
    in all other cases. *)
external unsafe_all_pwrite: Unix.file_descr -> int -> string -> int -> int -> int = "caml_extunix_all_pwrite"

let all_pwrite fd off buf ofs len =
  if off < 0 || ofs < 0 || len < 0 || ofs > String.length buf - len
  then invalid_arg "ExtUnix.all_pwrite"
  else unsafe_all_pwrite fd off buf ofs len

(** [single_pwrite fd off buf ofs len] writes up to [len] bytes from
    file descriptor [fd] at offset [off] (from the start of the file)
    into the string [buf] at offset [ofs]. The file offset is not
    changed.

    [single_pwrite] attempts to write only once. Returns the number of
    characters written or raises an Unix.Unix_error exception. *)
external unsafe_single_pwrite: Unix.file_descr -> int -> string -> int -> int -> int = "caml_extunix_single_pwrite"

let single_pwrite fd off buf ofs len =
  if off < 0 || ofs < 0 || len < 0 || ofs > String.length buf - len
  then invalid_arg "ExtUnix.single_pwrite"
  else unsafe_single_pwrite fd off buf ofs len

(** [pwrite fd off buf ofs len] writes up to [len] bytes from file
    descriptor [fd] at offset [off] (from the start of the file) into
    the string [buf] at offset [ofs]. The file offset is not changed.

    [pwrite] repeats the write operation until all characters have
    been written or an error occurs. Raises an Unix.Unix_error exception
    if 0 characters could be written before an error occurs. Continues
    the write operation on EINTR. Returns the number of characters
    written in all other cases. *)
external unsafe_pwrite: Unix.file_descr -> int -> string -> int -> int -> int = "caml_extunix_pwrite"

let pwrite fd off buf ofs len =
  if off < 0 || ofs < 0 || len < 0 || ofs > String.length buf - len
  then invalid_arg "ExtUnix.pwrite"
  else unsafe_pwrite fd off buf ofs len

(** [intr_pwrite fd off buf ofs len] writes up to [len] bytes from
    file descriptor [fd] at offset [off] (from the start of the file)
    into the string [buf] at offset [ofs]. The file offset is not
    changed.

    [intr_pwrite] repeats the write operation until all characters have
    been written or an error occurs. Raises an Unix.Unix_error exception
    if 0 characters could be written before an error occurs. Does NOT
    continue on EINTR. Returns the number of characters written in all
    other cases. *)
external unsafe_intr_pwrite: Unix.file_descr -> int -> string -> int -> int -> int = "caml_extunix_intr_pwrite"

let intr_pwrite fd off buf ofs len =
  if off < 0 || ofs < 0 || len < 0 || ofs > String.length buf - len
  then invalid_arg "ExtUnix.intr_pwrite"
  else unsafe_intr_pwrite fd off buf ofs len
]

[%%have READ

(** {3 read}

    @author Goswin von Brederlow *)

(** [all_read fd buf ofs len] reads up to [len] bytes from file
    descriptor [fd] into the string [buf] at offset [ofs].

    [all_read] repeats the read operation until all characters have
    been read or an error occurs. Returns less than the number of
    characters requested on EAGAIN, EWOULDBLOCK or End-of-file but
    only ever returns 0 on End-of-file. Continues the read operation
    on EINTR. Raises an Unix.Unix_error exception in all other
    cases. *)
external unsafe_all_read: Unix.file_descr -> Bytes.t -> int -> int -> int = "caml_extunix_all_read"

let all_read fd buf ofs len =
  if ofs < 0 || len < 0 || ofs > Bytes.length buf - len
  then invalid_arg "ExtUnix.all_read"
  else unsafe_all_read fd buf ofs len

(** [single_read fd buf ifs len] reads up to [len] bytes from file
    descriptor [fd] into the string [buf] at offset [ofs].

    [single_read] attempts to read only once. Returns the number of
    characters read or raises an Unix.Unix_error exception. *)
external unsafe_single_read: Unix.file_descr -> Bytes.t -> int -> int -> int = "caml_extunix_single_read"

let single_read fd buf ofs len =
  if ofs < 0 || len < 0 || ofs > Bytes.length buf - len
  then invalid_arg "ExtUnix.single_read"
  else unsafe_single_read fd buf ofs len

(** [read fd buf ofs len] reads up to [len] bytes from file descriptor
    [fd] into the string [buf] at offset [ofs].

    [read] repeats the read operation until all characters have
    been read or an error occurs. Raises an Unix.Unix_error exception
    if 0 characters could be read before an error occurs. Continues
    the read operation on EINTR. Returns the number of characters
    written in all other cases. *)
external unsafe_read: Unix.file_descr -> Bytes.t -> int -> int -> int = "caml_extunix_read"

let read fd buf ofs len =
  if ofs < 0 || len < 0 || ofs > Bytes.length buf - len
  then invalid_arg "ExtUnix.read"
  else unsafe_read fd buf ofs len

(** [intr_read fd buf ofs len] reads up to [len] bytes from file
    descriptor [fd] into the string [buf] at offset [ofs].

    [intr_read] repeats the read operation until all characters have
    been read or an error occurs. Raises an Unix.Unix_error exception
    if 0 characters could be read before an error occurs. Does NOT
    continue on EINTR. Returns the number of characters written in all
    other cases. *)
external unsafe_intr_read: Unix.file_descr -> Bytes.t -> int -> int -> int = "caml_extunix_intr_read"

let intr_read fd buf ofs len =
  if ofs < 0 || len < 0 || ofs > Bytes.length buf - len
  then invalid_arg "ExtUnix.intr_read"
  else unsafe_intr_read fd buf ofs len
]

[%%have WRITE

(** {3 write}

    @author Goswin von Brederlow *)

(** [all_write fd buf ofs len] writes up to [len] bytes from file
    descriptor [fd] into the string [buf] at offset [ofs].

    [all_write] repeats the write operation until all characters have
    been written or an error occurs. Returns less than the number of
    characters requested on EAGAIN, EWOULDBLOCK but never 0. Continues
    the write operation on EINTR. Raises an Unix.Unix_error exception
    in all other cases. *)
external unsafe_all_write: Unix.file_descr -> string -> int -> int -> int = "caml_extunix_all_write"

let all_write fd buf ofs len =
  if ofs < 0 || len < 0 || ofs > String.length buf - len
  then invalid_arg "ExtUnix.all_write"
  else unsafe_all_write fd buf ofs len

(** [single_write fd buf ofs len] writes up to [len] bytes from file
    descriptor [fd] into the string [buf] at offset [ofs].

    [single_write] attempts to write only once. Returns the number of
    characters written or raises an Unix.Unix_error exception. *)
external unsafe_single_write: Unix.file_descr -> string -> int -> int -> int = "caml_extunix_single_write"

let single_write fd buf ofs len =
  if ofs < 0 || len < 0 || ofs > String.length buf - len
  then invalid_arg "ExtUnix.single_write"
  else unsafe_single_write fd buf ofs len

(** [write fd buf ofs len] writes up to [len] bytes from file
    descriptor [fd] into the string [buf] at offset [ofs].

    [write] repeats the write operation until all characters have
    been written or an error occurs. Raises an Unix.Unix_error exception
    if 0 characters could be written before an error occurs. Continues
    the write operation on EINTR. Returns the number of characters
    written in all other cases. *)
external unsafe_write: Unix.file_descr -> string -> int -> int -> int = "caml_extunix_write"

let write fd buf ofs len =
  if ofs < 0 || len < 0 || ofs > String.length buf - len
  then invalid_arg "ExtUnix.write"
  else unsafe_write fd buf ofs len

(** [intr_write fd buf ofs len] writes up to [len] bytes from file
    descriptor [fd] into the string [buf] at offset [ofs].

    [intr_write] repeats the write operation until all characters have
    been written or an error occurs. Raises an Unix.Unix_error exception
    if 0 characters could be written before an error occurs. Does NOT
    continue on EINTR. Returns the number of characters written in all
    other cases. *)
external unsafe_intr_write: Unix.file_descr -> string -> int -> int -> int = "caml_extunix_intr_write"

let intr_write fd buf ofs len =
  if ofs < 0 || len < 0 || ofs > String.length buf - len
  then invalid_arg "ExtUnix.intr_write"
  else unsafe_intr_write fd buf ofs len
]

(** {2 File operations on large files} *)

(** File operations on large files. This sub-module provides 64-bit
    variants of the functions [ExtUnix.fadvise] (for predeclaring an
    access pattern for file data), [ExtUnix.fallocate] (for allocating
    disk space for a file), [ExtUnix.all_pread], [ExtUnix.single_pread],
    [ExtUnix.pread], [ExtUnix.intr_pread], [ExtUnix.all_pwrite],
    [ExtUnix.single_pwrite], [ExtUnix.pwrite] and [ExtUnix.intr_pwrite]
    (for reading from or writing to a file descriptor at a given
    offset). These alternate functions represent positions and sizes
    by 64-bit integers (type int64) instead of regular integers
    (type int), thus allowing operating on files whose sizes are
    greater than max_int. *)
module LargeFile =
struct

  [%%have FADVISE
  external fadvise: Unix.file_descr -> int64 -> int64 -> advice -> unit = "caml_extunix_fadvise64"
  ]

  [%%have FALLOCATE
  external fallocate: Unix.file_descr -> int64 -> int64 -> unit = "caml_extunix_fallocate64"
  ]

  [%%have PREAD
  external unsafe_all_pread: Unix.file_descr -> int64 -> Bytes.t -> int -> int -> int = "caml_extunix_all_pread64"

  let all_pread fd off buf ofs len =
    if off < Int64.zero
    then invalid_arg "ExtUnix.LargeFile.all_pread"
    else unsafe_all_pread fd off buf ofs len

  external unsafe_single_pread: Unix.file_descr -> int64 -> Bytes.t -> int -> int -> int = "caml_extunix_single_pread64"

  let single_pread fd off buf ofs len =
    if off < Int64.zero
    then invalid_arg "ExtUnix.LargeFile.single_pread"
    else unsafe_single_pread fd off buf ofs len

  external unsafe_pread: Unix.file_descr -> int64 -> Bytes.t -> int -> int -> int = "caml_extunix_pread64"

  let pread fd off buf ofs len =
    if off < Int64.zero
    then invalid_arg "ExtUnix.LargeFile.pread"
    else unsafe_pread fd off buf ofs len

  external unsafe_intr_pread: Unix.file_descr -> int64 -> Bytes.t -> int -> int -> int = "caml_extunix_intr_pread64"

  let intr_pread fd off buf ofs len =
    if off < Int64.zero
    then invalid_arg "ExtUnix.LargeFile.intr_pread"
    else unsafe_intr_pread fd off buf ofs len
  ]

  [%%have PWRITE
  external unsafe_all_pwrite: Unix.file_descr -> int64 -> string -> int -> int -> int = "caml_extunix_all_pwrite64"

  let all_pwrite fd off buf ofs len =
    if off < Int64.zero
    then invalid_arg "ExtUnix.LargeFile.all_pwrite"
    else unsafe_all_pwrite fd off buf ofs len

  external unsafe_single_pwrite: Unix.file_descr -> int64 -> string -> int -> int -> int = "caml_extunix_single_pwrite64"

  let single_pwrite fd off buf ofs len =
    if off < Int64.zero
    then invalid_arg "ExtUnix.LargeFile.single_pwrite"
    else unsafe_single_pwrite fd off buf ofs len

  external unsafe_pwrite: Unix.file_descr -> int64 -> string -> int -> int -> int = "caml_extunix_pwrite64"

  let pwrite fd off buf ofs len =
    if off < Int64.zero
    then invalid_arg "ExtUnix.LargeFile.pwrite"
    else unsafe_pwrite fd off buf ofs len

  external unsafe_intr_pwrite: Unix.file_descr -> int64 -> string -> int -> int -> int = "caml_extunix_intr_pwrite64"

  let intr_pwrite fd off buf ofs len =
    if off < Int64.zero
    then invalid_arg "ExtUnix.LargeFile.intr_pwrite"
    else unsafe_intr_pwrite fd off buf ofs len
  ]

  (** {2 Bigarray variants} *)

  (** *)
  module BA = struct

  [%%have PREAD
  external unsafe_all_pread: Unix.file_descr -> int64 -> ('a, 'b) carray -> int = "caml_extunixba_all_pread64"

  let all_pread fd off buf =
    if off < Int64.zero
    then invalid_arg "ExtUnix.LargeFile.all_pread"
    else unsafe_all_pread fd off buf

  external unsafe_single_pread: Unix.file_descr -> int64 -> ('a, 'b) carray -> int = "caml_extunixba_single_pread64"

  let single_pread fd off buf =
    if off < Int64.zero
    then invalid_arg "ExtUnix.LargeFile.single_pread"
    else unsafe_single_pread fd off buf

  external unsafe_pread: Unix.file_descr -> int64 -> ('a, 'b) carray -> int = "caml_extunixba_pread64"

  let pread fd off buf =
    if off < Int64.zero
    then invalid_arg "ExtUnix.LargeFile.pread"
    else unsafe_pread fd off buf

  external unsafe_intr_pread: Unix.file_descr -> int64 -> ('a, 'b) carray -> int = "caml_extunixba_intr_pread64"

  let intr_pread fd off buf =
    if off < Int64.zero
    then invalid_arg "ExtUnix.LargeFile.intr_pread"
    else unsafe_intr_pread fd off buf
  ]

  [%%have PWRITE
  external unsafe_all_pwrite: Unix.file_descr -> int64 -> ('a, 'b) carray -> int = "caml_extunixba_all_pwrite64"

  let all_pwrite fd off buf =
    if off < Int64.zero
    then invalid_arg "ExtUnix.LargeFile.all_pwrite"
    else unsafe_all_pwrite fd off buf

  external unsafe_single_pwrite: Unix.file_descr -> int64 -> ('a, 'b) carray -> int = "caml_extunixba_single_pwrite64"

  let single_pwrite fd off buf =
    if off < Int64.zero
    then invalid_arg "ExtUnix.LargeFile.single_pwrite"
    else unsafe_single_pwrite fd off buf

  external unsafe_pwrite: Unix.file_descr -> int64 -> ('a, 'b) carray -> int = "caml_extunixba_pwrite64"

  let pwrite fd off buf =
    if off < Int64.zero
    then invalid_arg "ExtUnix.LargeFile.pwrite"
    else unsafe_pwrite fd off buf

  external unsafe_intr_pwrite: Unix.file_descr -> int64 -> ('a, 'b) carray -> int = "caml_extunixba_intr_pwrite64"

  let intr_pwrite fd off buf =
    if off < Int64.zero
    then invalid_arg "ExtUnix.LargeFile.intr_pwrite"
    else unsafe_intr_pwrite fd off buf
  ]

  end (* module BA *)

end (* module LargeFile *)

[%%have MOUNT

(** {3 mount system call} *)

type mount_flag =
  | MS_RDONLY | MS_NOSUID | MS_NODEV | MS_NOEXEC | MS_SYNCHRONOUS | MS_REMOUNT
  | MS_MANDLOCK | MS_DIRSYNC | MS_NOATIME | MS_NODIRATIME | MS_BIND | MS_MOVE
  | MS_REC | MS_SILENT | MS_POSIXACL | MS_UNBINDABLE | MS_PRIVATE | MS_SLAVE
  | MS_SHARED | MS_RELATIME | MS_KERNMOUNT | MS_I_VERSION | MS_STRICTATIME
  | MS_NOUSER

external mount: source:string -> target:string -> fstype:string ->
  mount_flag list -> data:string -> unit = "caml_extunix_mount"

type umount2_flag =
  | MNT_FORCE | MNT_DETACH | MNT_EXPIRE | UMOUNT_NOFOLLOW

external umount2: string -> umount2_flag list -> unit = "caml_extunix_umount2"

]

[%%have CHROOT

(** {3 chroot system call} *)

external chroot: string -> unit = "caml_extunix_chroot"

]

(** {2 namespace} *)

[%%have UNSHARE

type clone_flag =
  | CLONE_FS | CLONE_FILES | CLONE_NEWNS | CLONE_SYSVSEM | CLONE_NEWUTS
  | CLONE_NEWIPC | CLONE_NEWUSER | CLONE_NEWPID | CLONE_NEWNET

external unshare: clone_flag list -> unit = "caml_extunix_unshare"

]


(** {2 ioctl} *)

(** Control the underlying device parameters of special files *)
module Ioctl = struct

[%%have SIOCGIFCONF

(** [siocgifconf sock], where [sock] is any socket, e.g. [socket PF_INET SOCK_DGRAM 0]
  @return the list of interfaces and corresponding addresses ({b FIXME max 32}) ({b may change}) *)
external siocgifconf : sock:Unix.file_descr -> (string * string) list = "caml_extunix_ioctl_siocgifconf"
]

[%%have TTY_IOCTL

(** Enable RTS/CTS (hardware) flow control. See CRTSCTS in tcsetattr(3).
    {b FIXME this is likely to disappear when separate interface for [tcsetattr] and [tcgetattr] gets implemented} *)
external crtscts : Unix.file_descr -> int = "caml_extunix_crtscts"

(** Get the status of modem bits. See TIOCMGET in tty_ioctl(4). *)
external tiocmget : Unix.file_descr -> int = "caml_extunix_ioctl_TIOCMGET"

(** Set the status of modem bits. See TIOCMSET in tty_ioctl(4). *)
external tiocmset : Unix.file_descr -> int -> unit = "caml_extunix_ioctl_TIOCMSET"

(** Clear the indicated modem bits. See TIOCMBIC in tty_ioctl(4). *)
external tiocmbic : Unix.file_descr -> int -> unit = "caml_extunix_ioctl_TIOCMBIC"

(** Set the indicated modem bits. See TIOCMBIS in tty_ioctl(4). *)
external tiocmbis : Unix.file_descr -> int -> unit = "caml_extunix_ioctl_TIOCMBIS"

]

end (* module Ioctl *)

(** {2 Miscellaneous} *)

[%%have TTYNAME

(** @return name of terminal *)
external ttyname : Unix.file_descr -> string = "caml_extunix_ttyname"
]

[%%have CTERMID

(** Get controlling terminal name *)
external ctermid : unit -> string = "caml_extunix_ctermid"
]

[%%have GETTID

(** @return thread id *)
external gettid : unit -> int = "caml_extunix_gettid"
]

[%%have PGID

(** [setpgid pid pgid] sets the process group of the process specified by [pid] to [pgid].
    If [pid] is zero, then the process ID of the calling process is used. If
    [pgid] is zero, then the PGID of the process specified by [pid] is made the same as its process ID. *)
external setpgid : int -> int -> unit = "caml_extunix_setpgid"

(** [getpgid pid] returns the PGID of the process specified by [pid].
    If [pid] is zero, the process ID of the calling process is used. *)
external getpgid : int -> int = "caml_extunix_getpgid"

(** [getsid pid] returns the session ID of the process specified by [pid].
    If [pid] is zero, the process ID of the calling process is used. *)
external getsid : int -> int = "caml_extunix_getsid"

]

[%%have SETREUID

(** [setreuid ruid euid] sets real and effective user IDs of the calling process.
    Supplying a value of -1 for either the real or effective user ID forces the system to leave that ID unchanged.
*)
external setreuid : int -> int -> unit = "caml_extunix_setreuid"

(** [setregid rgid egid] sets real and effective group IDs of the calling process.
    Supplying a value of -1 for either the real or effective group ID forces the system to leave that ID unchanged.
*)
external setregid : int -> int -> unit = "caml_extunix_setregid"

]

[%%have SETRESUID

(** [setresuid ruid euid suid] sets real, effective and saved user IDs of the calling process.
    Supplying a value of -1 for either the real or effective user ID forces the system to leave that ID unchanged.
*)
external setresuid: int -> int -> int -> unit = "caml_extunix_setresuid"

(** [setresgid rgid egid sgid] sets real, effective and saved group IDs of the calling process.
    Supplying a value of -1 for either the real or effective group ID forces the system to leave that ID unchanged.
*)
external setresgid: int -> int -> int -> unit = "caml_extunix_setresgid"

]

[%%have TCPGRP
external tcgetpgrp : Unix.file_descr -> int = "caml_extunix_tcgetpgrp"
external tcsetpgrp : Unix.file_descr -> int -> unit = "caml_extunix_tcsetpgrp"
]

(** Exit process without running any [at_exit] hooks (implemented in Pervasives) *)
external sys_exit : int -> 'a = "caml_sys_exit"

[%%have SYSINFO

(** NB all memory fields in this structure are the multiplies of [mem_unit] bytes *)
type sysinfo = {
  uptime : int; (** Seconds since boot *)
  loads : (float * float * float); (** 1, 5, and 15 minute load averages *)
  totalram : int;  (** Total usable main memory size *)
  freeram : int;   (** Available memory size *)
  sharedram : int; (** Amount of shared memory *)
  bufferram : int; (** Memory used by buffers *)
  totalswap : int; (** Total swap space size *)
  freeswap : int;  (** swap space still available *)
  procs : int;    (** Number of current processes *)
  totalhigh : int; (** Total high memory size *)
  freehigh : int;  (** Available high memory size *)
  mem_unit : int;   (** Memory unit size in bytes *)
}

(** @return overall system statistics *)
external sysinfo : unit -> sysinfo = "caml_extunix_sysinfo"

(** @return seconds since boot *)
external uptime : unit -> int = "caml_extunix_uptime"
]

(** {2 Network} *)

[%%have IFADDRS

(** @return the list of [AF_INET] and [AF_INET6] interfaces and corresponding addresses ({b may change}) *)
external getifaddrs : unit -> (string * string) list = "caml_extunix_getifaddrs"

]

[%%have SOCKOPT

type socket_int_option_ =
| TCP_KEEPCNT_
| TCP_KEEPIDLE_
| TCP_KEEPINTVL_
| SO_REUSEPORT_
| SO_ATTACH_BPF_
| SO_ATTACH_REUSEPORT_EBPF_
| SO_DETACH_FILTER_
| SO_DETACH_BPF_
| SO_LOCK_FILTER_

let string_of_socket_int_option_ = function
| TCP_KEEPCNT_ -> "TCP_KEEPCNT"
| TCP_KEEPIDLE_ -> "TCP_KEEPIDLE"
| TCP_KEEPINTVL_ -> "TCP_KEEPINTVL"
| SO_REUSEPORT_ -> "SO_REUSEPORT"
| SO_ATTACH_BPF_ -> "SO_ATTACH_BPF"
| SO_ATTACH_REUSEPORT_EBPF_ -> "SO_ATTACH_REUSEPORT_EBPF"
| SO_DETACH_FILTER_ -> "SO_DETACH_FILTER"
| SO_DETACH_BPF_ -> "SO_DETACH_BPF"
| SO_LOCK_FILTER_ -> "SO_LOCK_FILTER"

external setsockopt_int : Unix.file_descr -> socket_int_option_ -> int -> unit = "caml_extunix_setsockopt_int"
external getsockopt_int : Unix.file_descr -> socket_int_option_ -> int = "caml_extunix_getsockopt_int"
external have_sockopt_int : socket_int_option_ -> bool = "caml_extunix_have_sockopt"

(** Extra socket options with integer value not covered in {!Unix} module.
  NB Not all options available on all platforms, use {!have_sockopt} to check at runtime
  (even when function is defined in [Specific] module)
*)
type socket_int_option =
| TCP_KEEPCNT (** The maximum number of keepalive probes TCP should send before dropping the connection *)
| TCP_KEEPIDLE (** The  time  (in  seconds)  the connection needs to remain idle before TCP starts sending
                   keepalive probes, if the socket option SO_KEEPALIVE has been set on this socket *)
| TCP_KEEPINTVL (** The time (in seconds) between individual keepalive probes *)
| SO_ATTACH_BPF (** file descriptor returned by the bpf(2), with program of type [BPF_PROG_TYPE_SOCKET_FILTER] *)
| SO_ATTACH_REUSEPORT_EBPF (** same as for SO_ATTACH_BPF *)

type socket_bool_option =
| SO_REUSEPORT (** Permits multiple AF_INET or AF_INET6 sockets to be bound to an identical socket address. *)
| SO_LOCK_FILTER (** Prevent changing the filters associated with the socket *)

type socket_unit_option =
| SO_DETACH_FILTER (** Remove classic or extended BPF program attached to a socket *)
| SO_DETACH_BPF (** same *)

let make_socket_int_option = function
| TCP_KEEPCNT -> TCP_KEEPCNT_
| TCP_KEEPIDLE -> TCP_KEEPIDLE_
| TCP_KEEPINTVL -> TCP_KEEPINTVL_
| SO_ATTACH_BPF -> SO_ATTACH_BPF_
| SO_ATTACH_REUSEPORT_EBPF -> SO_ATTACH_REUSEPORT_EBPF_

let make_socket_bool_option = function
| SO_REUSEPORT -> SO_REUSEPORT_
| SO_LOCK_FILTER -> SO_LOCK_FILTER_

let make_socket_unit_option = function
| SO_DETACH_FILTER -> SO_DETACH_FILTER_
| SO_DETACH_BPF -> SO_DETACH_BPF_

let have_sockopt_unit x = have_sockopt_int (make_socket_unit_option x)
let have_sockopt_bool x = have_sockopt_int (make_socket_bool_option x)
let have_sockopt_int x = have_sockopt_int (make_socket_int_option x)

(** obsolete, compatibility *)
let have_sockopt = have_sockopt_int

let setsockopt_int sock opt v = try setsockopt_int sock opt v with Not_found -> raise (Not_available ("setsockopt " ^ string_of_socket_int_option_ opt))
let getsockopt_int sock opt = try getsockopt_int sock opt with Not_found -> raise (Not_available ("getsockopt " ^ string_of_socket_int_option_ opt))

(** Set the option without value on the given socket *)
let setsockopt_unit sock opt = setsockopt_int sock (make_socket_unit_option opt) 0

(** Set a boolean-valued option in the given socket *)
let setsockopt sock opt v = setsockopt_int sock (make_socket_bool_option opt) (if v then 1 else 0)

(** Get the current value for the boolean-valued option in the given socket *)
let getsockopt sock opt = 0 <> getsockopt_int sock (make_socket_bool_option opt)

(** Set an integer-valued option in the given socket *)
let setsockopt_int sock opt v = setsockopt_int sock (make_socket_int_option opt) v

(** Get the current value for the integer-valued option in the given socket *)
let getsockopt_int sock opt = getsockopt_int sock (make_socket_int_option opt)


]

[%%have POLL

module Poll : sig

type t = private int

(** [is_set flags flag]
  @return whether [flag] is set in [flags] *)
val is_set : t -> t -> bool

(** [is_inter flags1 flags2]
  @return whether [flags1] and [flags2] have non-empty intersection *)
val is_inter : t -> t -> bool

(** @return intersection of two flags (AND) *)
val inter : t -> t -> t

(** @return union of two flags (OR) *)
val union : t -> t -> t

(** @return union of several flags (OR) *)
val join : t list -> t

(** equivalent to [union] *)
val (+) : t -> t -> t

val pollin : t
val pollpri : t
val pollout : t
val pollerr : t
val pollhup : t
val pollnval : t

(** may not be present on all platforms (=0) *)
val pollrdhup : t

(** no poll flags (=0) *)
val none : t

end = struct

type t = int
external poll_constants : unit -> (int*int*int*int*int*int*int) = "caml_extunix_poll_constants"
let (pollin,pollpri,pollout,pollerr,pollhup,pollnval,pollrdhup) = try poll_constants () with Not_available _ -> (0,0,0,0,0,0,0)
let none = 0

let is_set xs x = xs land x = x
let inter x y = x land y
let is_inter x y = x land y <> 0
let union a b = a lor b
let (+) = union
let join = List.fold_left (lor) 0

end

external poll : (Unix.file_descr * Poll.t) array -> int -> float -> (Unix.file_descr * Poll.t) list = "caml_extunix_poll"

let poll a ?(n=Array.length a) t = poll a n t

]

[%%have SIGNALFD

(** {2 signalfd} *)

(** OCaml bindings for signalfd(2) and related functions

    @author Kaustuv Chaudhuri <kaustuv.chaudhuri@inria.fr>
*)

(******************************************************************************)
(* signalfd bindings                                                          *)
(*                                                                            *)
(* NO COPYRIGHT -- RELEASED INTO THE PUBLIC DOMAIN                            *)
(*                                                                            *)
(* Author: Kaustuv Chaudhuri <kaustuv.chaudhuri@inria.fr>                     *)
(******************************************************************************)

(** [signalfd ?fd sigs flags ()]
    If the first optional argument is omitted, then a new file descriptor is allocated.
    Otherwise, the given file descriptor is modified (in which case it
    must have been created with [signalfd] previously). When you are
    done with the fd, remember to {!Unix.close} it. Do not forget
    to block [sigs] with {!Unix.sigprocmask} to prevent signal handling
    according to default dispositions.
    *)
external signalfd : ?fd:Unix.file_descr -> sigs:int list -> flags:int list -> unit -> Unix.file_descr ="caml_extunix_signalfd"

(** This type represents signal information that is read(2) from the
    signalfd. *)
type ssi

(** Blocking read(2) on a signalfd. Has undefined behaviour on
    non-signalfds. Every successful read consumes a pending signal. *)
external signalfd_read    : Unix.file_descr -> ssi = "caml_extunix_signalfd_read"

(** {3 Functions to query the signal information structure.} *)

(** Get the signal value. This form is compatible with the signal
    values defined in the standard {!Sys} module.

    See signalfd(2) for the details of the remaining functions. Most
    of these integers are actually unsigned. *)
external ssi_signo_sys    : ssi -> int   = "caml_extunix_ssi_signo_sys"

external ssi_signo        : ssi -> int32 = "caml_extunix_ssi_signo"
external ssi_errno        : ssi -> int32 = "caml_extunix_ssi_errno"
external ssi_code         : ssi -> int32 = "caml_extunix_ssi_code"
external ssi_pid          : ssi -> int32 = "caml_extunix_ssi_pid"
external ssi_uid          : ssi -> int32 = "caml_extunix_ssi_uid"
external ssi_fd           : ssi -> Unix.file_descr = "caml_extunix_ssi_fd"
external ssi_tid          : ssi -> int32 = "caml_extunix_ssi_tid"
external ssi_band         : ssi -> int32 = "caml_extunix_ssi_band"
external ssi_overrun      : ssi -> int32 = "caml_extunix_ssi_overrun"
external ssi_trapno       : ssi -> int32 = "caml_extunix_ssi_trapno"
external ssi_status       : ssi -> int32 = "caml_extunix_ssi_status"
external ssi_int          : ssi -> int32 = "caml_extunix_ssi_int"
external ssi_ptr          : ssi -> int64 = "caml_extunix_ssi_ptr"
external ssi_utime        : ssi -> int64 = "caml_extunix_ssi_utime"
external ssi_stime        : ssi -> int64 = "caml_extunix_ssi_stime"
external ssi_addr         : ssi -> int64 = "caml_extunix_ssi_addr"

]

[%%have RESOURCE

(**
  {2 POSIX resource operations}

  @author Sylvain Le Gall <sylvain@le-gall.net>
*)

(** priority target *)
type which_prio_t =
  | PRIO_PROCESS of int (** Priority for a process id *)
  | PRIO_PGRP of int    (** Priority for a process group id *)
  | PRIO_USER of int    (** Priority for a user id *)

type priority = int

type resource =
  | RLIMIT_CORE   (** Limit on size of core dump file. *)
  | RLIMIT_CPU    (** Limit on CPU time per process. *)
  | RLIMIT_DATA   (** Limit on data segment size. *)
  | RLIMIT_FSIZE  (** Limit on file size. *)
  | RLIMIT_NOFILE (** Limit on number of open files. *)
  | RLIMIT_STACK  (** Limit on stack size. *)
  | RLIMIT_AS     (** Limit on address space size. *)

(** get resource name *)
let string_of_resource = function
  | RLIMIT_CORE   -> "RLIMIT_CORE"
  | RLIMIT_CPU    -> "RLIMIT_CPU"
  | RLIMIT_DATA   -> "RLIMIT_DATA"
  | RLIMIT_FSIZE  -> "RLIMIT_FSIZE"
  | RLIMIT_NOFILE -> "RLIMIT_NOFILE"
  | RLIMIT_STACK  -> "RLIMIT_STACK"
  | RLIMIT_AS     -> "RLIMIT_AS"

(** Limits *)
module Rlimit = struct

  type t = int64 option (** [Some limit] is fixed limit, [None] is RLIM_INFINITY *)

  let string_of_bytes n =
    let sz, acc = List.fold_left (fun (sz, acc) e ->
      let q = Int64.div sz 1024L in
      let r = Int64.rem sz 1024L in
      let acc = if r <> 0L then Printf.sprintf "%Ld %s" r e :: acc else acc in
      (q, acc)) (n, []) ["B"; "KB"; "MB"; "GB"]
    in
    let acc = if sz <> 0L then Printf.sprintf "%Ld TB" sz :: acc else acc in
    match acc with
    | [] -> "0 B"
    | _ -> String.concat " " acc

  let to_string ?r = function
  | None -> "infinity"
  | Some l ->
    match r with
    | None -> Int64.to_string l
    | Some RLIMIT_CORE
    | Some RLIMIT_DATA
    | Some RLIMIT_FSIZE
    | Some RLIMIT_STACK
    | Some RLIMIT_AS -> string_of_bytes l
    | Some RLIMIT_NOFILE -> Int64.to_string l
    | Some RLIMIT_CPU -> Printf.sprintf "%Ld s" l

  let compare l1 l2 =
    match l1, l2 with
    | Some l1, Some l2 -> Int64.compare l1 l2
    | None, None -> 0
    | Some _, None -> -1
    | None, Some _ -> 1

  let eq l1 l2 = compare l1 l2 = 0
  let gt l1 l2 = compare l1 l2 > 0
  let ge l1 l2 = compare l1 l2 >= 0
  let lt l1 l2 = compare l1 l2 < 0
  let le l1 l2 = compare l1 l2 <= 0

end (* Rlimit *)

(** Get nice value *)
external getpriority : which_prio_t -> priority = "caml_extunix_getpriority"

(** Set nice value *)
external setpriority : which_prio_t -> priority -> unit = "caml_extunix_setpriority"

(** Get maximum resource consumption.
    @return [(soft,hard)] limits *)
external getrlimit : resource -> Rlimit.t * Rlimit.t = "caml_extunix_getrlimit"

(** Set maximum resource consumption *)
external setrlimit : resource -> soft:Rlimit.t -> hard:Rlimit.t -> unit = "caml_extunix_setrlimit"

(* let unlimit_soft r = let (_,hard) = getrlimit r in setrlimit r ~soft:hard ~hard *)

(** [getrusage] is not implemented because the only meaningful information it
    provides are [ru_utime] and [ru_stime] which can be accessed through
    [Unix.times].
  *)

]

(** {2 Memory management} *)

[%%have MLOCKALL

(** mlockall flag *)
type mlockall_flag = MCL_CURRENT | MCL_FUTURE

(** Lock all pages mapped into the address space of the calling process. *)
external mlockall : mlockall_flag list -> unit = "caml_extunix_mlockall"

(** Unlock all pages mapped into the address space of the calling process. *)
external munlockall : unit -> unit = "caml_extunix_munlockall"

]

[%%have MEMALIGN

(** [memalign alignment size] creates a {!Bigarray.Array1.t} of [size] bytes,
    which data is aligned to [alignment] (must be a power of 2)

    @author Goswin von Brederlow
*)
external memalign: int -> int -> Bigarray.int8_unsigned_elt carray8 = "caml_extunix_memalign"

]

(** {2 Time conversion} *)

[%%have STRPTIME

(** This function is the converse of the {!strftime} function.
  [strptime fmt data] convert a string containing time information [data]
  into a [tm] struct according to the format specified by [fmt]. *)
external strptime: string -> string -> Unix.tm = "caml_extunix_strptime"

]

[%%have STRTIME

(** Return the ascii representation of a given [tm] argument. The
  ascii time is returned in the form of a string like
  'Wed Jun 30, 21:21:21 2005\n' *)
external asctime: Unix.tm -> string = "caml_extunix_asctime"

(** This functions is the converse of the {!strptime} function.
  [strftime fmt data] converts a [tm] structure [data] into a string
  according to the format specified by [fmt]. *)
external strftime: string -> Unix.tm -> string = "caml_extunix_strftime"

(** [tzname isdst]
  @param isdst specifies whether daylight saving is in effect
  @return abbreviated name of the current timezone
*)
external tzname : bool -> string = "caml_extunix_tzname"

]

[%%have TIMEZONE

(** @return timezone (seconds  West  of UTC) and daylight (whether there is time during
  the year when daylight saving time applies in this timezone) *)
external timezone : unit -> int * bool = "caml_extunix_timezone"

]

[%%have TIMEGM

(** Inverse of [Unix.gmtime] *)
external timegm : Unix.tm -> float = "caml_extunix_timegm"

]

[%%have PTS

(**
  {2 Pseudo terminal management}

  @author Niki Yoshiuchi <aplusbi@gmail.com>
*)

(** This function opens a pseudo-terminal device. *)
external posix_openpt : open_flag list ->
  Unix.file_descr = "caml_extunix_posix_openpt"

(** This function grants access to the slave pseudo-terminal. *)
external grantpt: Unix.file_descr -> unit = "caml_extunix_grantpt"

(** This function unlock a pseudo-terminal master/slave pair. *)
external unlockpt: Unix.file_descr -> unit = "caml_extunix_unlockpt"

(** This function get the name of the slave pseudo-terminal. *)
external ptsname: Unix.file_descr -> string = "caml_extunix_ptsname"

]

(** {2 Application self-debugging and diagnostics} *)

[%%have EXECINFO

(** @return a backtrace for the calling program

  {b NB} native function [backtrace] may fail to unwind the OCaml callstack
  correctly or even segfault. Do not use lightly.

  See {{:https://forge.ocamlcore.org/tracker/index.php?func=detail&aid=1290}bug #1290},
  {{:http://caml.inria.fr/mantis/view.php?id=5334}PR#5344}
  and {{:http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=637360}Debian bug #637380} for details.
*)
external backtrace : unit -> string array = "caml_extunix_backtrace"

]

[%%have MALLOC_STATS

(** Print brief heap summary statistics on stderr *)
external malloc_stats : unit -> unit = "caml_extunix_malloc_stats"

]

[%%have MALLOC_INFO

(** @return the information about state of allocator *)
external malloc_info : unit -> string = "caml_extunix_malloc_info"

]

[%%have MCHECK

external mtrace : unit -> unit = "caml_extunix_mtrace"
external muntrace : unit -> unit = "caml_extunix_muntrace"

]

[%%have PTRACE

external ptrace_traceme : unit -> unit = "caml_extunix_ptrace_traceme"
external ptrace_peekdata : int -> nativeint -> nativeint = "caml_extunix_ptrace_peekdata"
external ptrace_peektext : int -> nativeint -> nativeint = "caml_extunix_ptrace_peektext"

type ptrace_request =
  | PTRACE_ATTACH
  | PTRACE_DETACH

external ptrace : int -> ptrace_request -> unit = "caml_extunix_ptrace"

]

(** {2 Environment manipulation} *)

[%%have SETENV

(** [setenv name value overwrite] adds the variable [name] to the environment with the value [value], if [name]
does not already exist or [overwrite] is true *)
external setenv : string -> string -> bool -> unit = "caml_extunix_setenv"

(** [unsetenv name] removes variable [name] from the environment. If [name] does not exist in the environment, then the function
succeeds, and the environment is unchanged. *)
external unsetenv : string -> unit = "caml_extunix_unsetenv"

]

[%%have CLEARENV

(** Clear the environment of all name-value pairs *)
external clearenv : unit -> unit = "caml_extunix_clearenv"

]

(** {2 Temporary directories} *)

[%%have MKDTEMP

(** [mkdtemp template] creates a unique temporary directory (with permissions 0700).
  Last six characters of [template] must be "XXXXXX". *)
external mkdtemp : string -> string = "caml_extunix_mkdtemp"

]

[%%have MKSTEMPS

(**/**)

(** internal use only *)
external internal_mkstemps : bytes -> int -> Unix.file_descr = "caml_extunix_internal_mkstemps"

(**/**)

(** [mkstemp ?(suffix="") prefix] generates a unique temporary
    filename in the form [prefix]XXXXXX[suffix], creates and opens the
    file, and returns an open file descriptor and name for the
    file. *)
let mkstemp ?(suffix="") prefix =
  let s = Bytes.of_string (prefix ^ "XXXXXX" ^ suffix) in
  let fd = internal_mkstemps s (String.length suffix) in
  (fd, Bytes.to_string s)
]

[%%have MKOSTEMPS

(**/**)

(** internal use only *)
external internal_mkostemps : bytes -> int -> open_flag list -> Unix.file_descr = "caml_extunix_internal_mkostemps"

(**/**)

(** [mkostemp ?(suffix="") ?(flags=[]) prefix] generates a unique temporary
    filename in the form [prefix]XXXXXX[suffix], creates and opens the
    file with [flags], and returns an open file descriptor and name
    for the file. *)
let mkostemp ?(suffix="") ?(flags=[]) prefix =
  let s = Bytes.of_string (prefix ^ "XXXXXX" ^ suffix) in
  let fd = internal_mkostemps s (String.length suffix) flags in
  (fd, Bytes.to_string s)

]

(** {2 Byte order conversion} *)

(** {2 big endian functions}

    @author Goswin von Brederlow *)
module BigEndian = struct

[%%have ENDIAN

  (** Conversion functions from host to big endian byte order and back *)

  (** Conversion of 16bit integers *)

  (** [uint16_from_host u16] converts an unsigned 16bit integer from host to
      big endian byte order *)
  external uint16_from_host : int -> int = "caml_extunix_htobe16" [@@noalloc]

  (** [int16_from_host i16] converts a signed 16bit integer from host to
      big endian byte order *)
  external int16_from_host : int -> int = "caml_extunix_htobe16_signed" [@@noalloc]

  (** [uint16_to_host u16] converts an unsigned 16bit integer from big
      endian to host byte order *)
  external uint16_to_host : int -> int = "caml_extunix_be16toh" [@@noalloc]

  (** [int16_to_host i16] converts a signed 16bit integer from big
      endian to host byte order *)
  external int16_to_host : int -> int = "caml_extunix_be16toh_signed" [@@noalloc]

  (** Conversion of 31bit integeres
      On 64bit platforms this actualy converts 32bit integers without
      the need to allocate a new int32. On 32bit platforms it produces
      garbage. For use on 64bit platforms only! *)

  (** [uint31_from_host u31] converts an unsigned 31bit integer from
      host to big endian byte order *)
  external uint31_from_host : int -> int = "caml_extunix_htobe31" [@@noalloc]

  (** [int31_from_host i31] converts a signed 31bit integer from host to
      big endian byte order *)
  external int31_from_host : int -> int = "caml_extunix_htobe31_signed" [@@noalloc]

  (** [uint31_to_host u31] converts an unsigned 31bit integer from big
      endian to host byte order *)
  external uint31_to_host : int -> int = "caml_extunix_be31toh" [@@noalloc]

  (** [int31_to_host i31] converts a signed 31bit integer from big
      endian to host byte order *)
  external int31_to_host : int -> int = "caml_extunix_be31toh_signed" [@@noalloc]

  (** Conversion of 32bit integers *)

  (** [int32_from_host int32] converts a 32bit integer from host to big
      endian byte order *)
  external int32_from_host : int32 -> int32 = "caml_extunix_htobe32"

  (** [int32_to_host int32] converts a 32bit integer from big endian to
      host byte order *)
  external int32_to_host : int32 -> int32 = "caml_extunix_be32toh"

  (** Conversion of 64bit integers *)

  (** [int64_from_host int64] converts a 64bit integer from host to big
      endian byte order *)
  external int64_from_host : int64 -> int64 = "caml_extunix_htobe64"

  (** [int64_to_host int64] converts a 64bit integer from big endian to
      host byte order *)
  external int64_to_host : int64 -> int64 = "caml_extunix_be64toh"

  (** [unsafe_get_X str off] extract integer of type [X] from string
      [str] starting at offset [off]. Unsigned types are 0 extended
      and signed types are sign extended to fill the ocaml type.
      Bounds checking is not performed. Use with caution and only when
      the program logic guarantees that the access is within bounds.

      Note: The 31bit functions extract a 32bit integer and return it
      as ocaml int. On 32bit platforms this can overflow as ocaml
      integers are 31bit signed there. No error is reported if this
      occurs. Use with care.
      Note: The same applies to 63bit functions.
  *)
  external unsafe_get_uint8  : string -> int -> int = "caml_extunix_get_u8" [@@noalloc]
  external unsafe_get_int8   : string -> int -> int = "caml_extunix_get_s8" [@@noalloc]
  external unsafe_get_uint16 : string -> int -> int = "caml_extunix_get_bu16" [@@noalloc]
  external unsafe_get_int16  : string -> int -> int = "caml_extunix_get_bs16" [@@noalloc]
  external unsafe_get_uint31 : string -> int -> int = "caml_extunix_get_bu31" [@@noalloc]
  external unsafe_get_int31  : string -> int -> int = "caml_extunix_get_bs31" [@@noalloc]
  external unsafe_get_int32  : string -> int -> int32 = "caml_extunix_get_bs32"
  external unsafe_get_uint63 : string -> int -> int = "caml_extunix_get_bu63" [@@noalloc]
  external unsafe_get_int63  : string -> int -> int = "caml_extunix_get_bs63" [@@noalloc]
  external unsafe_get_int64  : string -> int -> int64 = "caml_extunix_get_bs64"

  (** [get_X str off] same as [unsafe_get_X] but with bounds checking. *)
  let get_uint8 str off =
    if off < 0 || off >= String.length str
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_uint8 str off

  let get_int8 str off =
    if off < 0 || off >= String.length str
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_int8 str off

  let get_uint16 str off =
    if off < 0 || off > String.length str - 2
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_uint16 str off

  let get_int16 str off =
    if off < 0 || off > String.length str - 2
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_int16 str off

  let get_uint31 str off =
    if off < 0 || off > String.length str - 4
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_uint31 str off

  let get_int31 str off =
    if off < 0 || off > String.length str - 4
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_int31 str off

  let get_int32 str off =
    if off < 0 || off > String.length str - 4
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_int32 str off

  let get_uint63 str off =
    if off < 0 || off > String.length str - 8
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_uint63 str off

  let get_int63 str off =
    if off < 0 || off > String.length str - 8
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_int63 str off

  let get_int64 str off =
    if off < 0 || off > String.length str - 8
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_int64 str off

  (** [unsafe_set_X buf off v] stores the integer [v] as type [X] in
      the buffer [buf] starting at offset [off]. Bounds checking is not
      performed. Use with caution and only when the program logic
      guarantees that the access is within bounds.

      Note: The 31bit functions store an ocaml int as 32bit
      integer. On 32bit platforms ocaml integers are 31bit signed and
      will be sign extended to 32bit first. Use with care.
      Note: The same applies to 63bit functions.
  *)
  external unsafe_set_uint8  : Bytes.t -> int -> int -> unit = "caml_extunix_set_8" [@@noalloc]
  external unsafe_set_int8   : Bytes.t -> int -> int -> unit = "caml_extunix_set_8" [@@noalloc]
  external unsafe_set_uint16 : Bytes.t -> int -> int -> unit = "caml_extunix_set_b16" [@@noalloc]
  external unsafe_set_int16  : Bytes.t -> int -> int -> unit = "caml_extunix_set_b16" [@@noalloc]
  external unsafe_set_uint31 : Bytes.t -> int -> int -> unit = "caml_extunix_set_b31" [@@noalloc]
  external unsafe_set_int31  : Bytes.t -> int -> int -> unit = "caml_extunix_set_b31" [@@noalloc]
  external unsafe_set_int32  : Bytes.t -> int -> int32 -> unit = "caml_extunix_set_b32" [@@noalloc]
  external unsafe_set_uint63 : Bytes.t -> int -> int -> unit = "caml_extunix_set_b63" [@@noalloc]
  external unsafe_set_int63  : Bytes.t -> int -> int -> unit = "caml_extunix_set_b63" [@@noalloc]
  external unsafe_set_int64  : Bytes.t -> int -> int64 -> unit = "caml_extunix_set_b64" [@@noalloc]

  (** [set_X buf off v] same as [unsafe_set_X] but with bounds checking. *)
  let set_uint8 str off v =
    if off < 0 || off >= Bytes.length str
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_uint8 str off v

  let set_int8 str off v =
    if off < 0 || off >= Bytes.length str
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_int8 str off v

  let set_uint16 str off v =
    if off < 0 || off > Bytes.length str - 2
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_uint16 str off v

  let set_int16 str off v =
    if off < 0 || off > Bytes.length str - 2
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_int16 str off v

  let set_uint31 str off v =
    if off < 0 || off > Bytes.length str - 4
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_uint31 str off v

  let set_int31 str off v =
    if off < 0 || off > Bytes.length str - 4
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_int31 str off v

  let set_int32 str off v =
    if off < 0 || off > Bytes.length str - 4
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_int32 str off v

  let set_uint63 str off v =
    if off < 0 || off > Bytes.length str - 8
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_uint63 str off v

  let set_int63 str off v =
    if off < 0 || off > Bytes.length str - 8
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_int63 str off v

  let set_int64 str off v =
    if off < 0 || off > Bytes.length str - 8
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_int64 str off v

]

end

(** {2 little endian functions}

    @author Goswin von Brederlow *)
module LittleEndian = struct

[%%have ENDIAN

  (** Conversion functions from host to little endian byte order and back *)

  (** Conversion of 16bit integers *)

  (** [uint16_from_host u16] converts an unsigned 16bit integer from host to
      little endian byte order *)
  external uint16_from_host : int -> int = "caml_extunix_htole16" [@@noalloc]

  (** [int16_from_host i16] converts a signed 16bit integer from host to
      little endian byte order *)
  external int16_from_host : int -> int = "caml_extunix_htole16_signed" [@@noalloc]

  (** [uint16_to_host u16] converts an unsigned 16bit integer from little
      endian to host byte order *)
  external uint16_to_host : int -> int = "caml_extunix_le16toh" [@@noalloc]

  (** [int16_to_host i16] converts a signed 16bit integer from little
      endian to host byte order *)
  external int16_to_host : int -> int = "caml_extunix_le16toh_signed" [@@noalloc]

  (** Conversion of 31bit integeres
      On 64bit platforms this actualy converts 32bit integers without
      the need to allocate a new int32. On 32bit platforms it produces
      garbage. For use on 64bit platforms only! *)

  (** [uint31_from_host u31] converts an unsigned 31bit integer from
      host to little endian byte order *)
  external uint31_from_host : int -> int = "caml_extunix_htole31" [@@noalloc]

  (** [int31_from_host i31] converts a signed 31bit integer from host to
      little endian byte order *)
  external int31_from_host : int -> int = "caml_extunix_htole31_signed" [@@noalloc]

  (** [uint31_to_host u31] converts an unsigned 31bit integer from little
      endian to host byte order *)
  external uint31_to_host : int -> int = "caml_extunix_le31toh" [@@noalloc]

  (** [int31_to_host i31] converts a signed 31bit integer from little
      endian to host byte order *)
  external int31_to_host : int -> int = "caml_extunix_le31toh_signed" [@@noalloc]

  (** Conversion of 32bit integers *)

  (** [int32_from_host int32] converts a 32bit integer from host to little
      endian byte order *)
  external int32_from_host : int32 -> int32 = "caml_extunix_htole32"

  (** [int32_to_host int32] converts a 32bit integer from little endian to
      host byte order *)
  external int32_to_host : int32 -> int32 = "caml_extunix_le32toh"

  (** Conversion of 64bit integers *)

  (** [int64_from_host int64] converts a 64bit integer from host to little
      endian byte order *)
  external int64_from_host : int64 -> int64 = "caml_extunix_htole64"

  (** [int64_to_host int64] converts a 64bit integer from little endian to
      host byte order *)
  external int64_to_host : int64 -> int64 = "caml_extunix_le64toh"

  (** [unsafe_get_X str off] extract integer of type [X] from string
      [str] starting at offset [off]. Unsigned types are 0 extended
      and signed types are sign extended to fill the ocaml type.
      Bounds checking is not performed. Use with caution and only when
      the program logic guarantees that the access is within bounds.

      Note: The 31bit functions extract a 32bit integer and return it
      as ocaml int. On 32bit platforms this can overflow as ocaml
      integers are 31bit signed there. No error is reported if this
      occurs. Use with care. *)
  external unsafe_get_uint8  : string -> int -> int = "caml_extunix_get_u8" [@@noalloc]
  external unsafe_get_int8   : string -> int -> int = "caml_extunix_get_s8" [@@noalloc]
  external unsafe_get_uint16 : string -> int -> int = "caml_extunix_get_lu16" [@@noalloc]
  external unsafe_get_int16  : string -> int -> int = "caml_extunix_get_ls16" [@@noalloc]
  external unsafe_get_uint31 : string -> int -> int = "caml_extunix_get_lu31" [@@noalloc]
  external unsafe_get_int31  : string -> int -> int = "caml_extunix_get_ls31" [@@noalloc]
  external unsafe_get_int32  : string -> int -> int32 = "caml_extunix_get_ls32"
  external unsafe_get_uint63 : string -> int -> int = "caml_extunix_get_lu63" [@@noalloc]
  external unsafe_get_int63  : string -> int -> int = "caml_extunix_get_ls63" [@@noalloc]
  external unsafe_get_int64  : string -> int -> int64 = "caml_extunix_get_ls64"

  (** [get_X str off] same as [unsafe_get_X] but with bounds checking. *)
  let get_uint8 str off =
    if off < 0 || off >= String.length str
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_uint8 str off

  let get_int8 str off =
    if off < 0 || off >= String.length str
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_int8 str off

  let get_uint16 str off =
    if off < 0 || off > String.length str - 2
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_uint16 str off

  let get_int16 str off =
    if off < 0 || off > String.length str - 2
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_int16 str off

  let get_uint31 str off =
    if off < 0 || off > String.length str - 4
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_uint31 str off

  let get_int31 str off =
    if off < 0 || off > String.length str - 4
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_int31 str off

  let get_int32 str off =
    if off < 0 || off > String.length str - 4
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_int32 str off

  let get_uint63 str off =
    if off < 0 || off > String.length str - 8
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_uint63 str off

  let get_int63 str off =
    if off < 0 || off > String.length str - 8
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_int63 str off

  let get_int64 str off =
    if off < 0 || off > String.length str - 8
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_int64 str off

  (** [unsafe_set_X buf off v] stores the integer [v] as type [X] in
      the buffer [buf] starting at offset [off]. Bounds checking is not
      performed. Use with caution and only when the program logic
      guarantees that the access is within bounds.

      Note: The 31bit functions store an ocaml int as 32bit
      integer. On 32bit platforms ocaml integers are 31bit signed and
      will be sign extended to 32bit first. Use with care. *)
  external unsafe_set_uint8  : Bytes.t -> int -> int -> unit = "caml_extunix_set_8" [@@noalloc]
  external unsafe_set_int8   : Bytes.t -> int -> int -> unit = "caml_extunix_set_8" [@@noalloc]
  external unsafe_set_uint16 : Bytes.t -> int -> int -> unit = "caml_extunix_set_l16" [@@noalloc]
  external unsafe_set_int16  : Bytes.t -> int -> int -> unit = "caml_extunix_set_l16" [@@noalloc]
  external unsafe_set_uint31 : Bytes.t -> int -> int -> unit = "caml_extunix_set_l31" [@@noalloc]
  external unsafe_set_int31  : Bytes.t -> int -> int -> unit = "caml_extunix_set_l31" [@@noalloc]
  external unsafe_set_int32  : Bytes.t -> int -> int32 -> unit = "caml_extunix_set_l32" [@@noalloc]
  external unsafe_set_uint63 : Bytes.t -> int -> int -> unit = "caml_extunix_set_l63" [@@noalloc]
  external unsafe_set_int63  : Bytes.t -> int -> int -> unit = "caml_extunix_set_l63" [@@noalloc]
  external unsafe_set_int64  : Bytes.t -> int -> int64 -> unit = "caml_extunix_set_l64" [@@noalloc]

  (** [set_X buf off v] same as [unsafe_set_X] but with bounds checking. *)
  let set_uint8 str off v =
    if off < 0 || off >= Bytes.length str
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_uint8 str off v

  let set_int8 str off v =
    if off < 0 || off >= Bytes.length str
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_int8 str off v

  let set_uint16 str off v =
    if off < 0 || off > Bytes.length str - 2
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_uint16 str off v

  let set_int16 str off v =
    if off < 0 || off > Bytes.length str - 2
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_int16 str off v

  let set_uint31 str off v =
    if off < 0 || off > Bytes.length str - 4
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_uint31 str off v

  let set_int31 str off v =
    if off < 0 || off > Bytes.length str - 4
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_int31 str off v

  let set_int32 str off v =
    if off < 0 || off > Bytes.length str - 4
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_int32 str off v

  let set_uint63 str off v =
    if off < 0 || off > Bytes.length str - 8
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_uint63 str off v

  let set_int63 str off v =
    if off < 0 || off > Bytes.length str - 8
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_int63 str off v

  let set_int64 str off v =
    if off < 0 || off > Bytes.length str - 8
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_int64 str off v

]

end

(** {2 host endian functions}

    @author Goswin von Brederlow *)
module HostEndian = struct

  (** [unsafe_get_X str off] extract integer of type [X] from string
      [str] starting at offset [off]. Unsigned types are 0 extended
      and signed types are sign extended to fill the ocaml type.
      Bounds checking is not performed. Use with caution and only when
      the program logic guarantees that the access is within bounds.

      Note: The 31bit functions extract a 32bit integer and return it
      as ocaml int. On 32bit platforms this can overflow as ocaml
      integers are 31bit signed there. No error is reported if this
      occurs. Use with care.
      Note: The same applies to 63bit functions.
  *)
  external unsafe_get_uint8  : string -> int -> int = "caml_extunix_get_u8" [@@noalloc]
  external unsafe_get_int8   : string -> int -> int = "caml_extunix_get_s8" [@@noalloc]
  external unsafe_get_uint16 : string -> int -> int = "caml_extunix_get_hu16" [@@noalloc]
  external unsafe_get_int16  : string -> int -> int = "caml_extunix_get_hs16" [@@noalloc]
  external unsafe_get_uint31 : string -> int -> int = "caml_extunix_get_hu31" [@@noalloc]
  external unsafe_get_int31  : string -> int -> int = "caml_extunix_get_hs31" [@@noalloc]
  external unsafe_get_int32  : string -> int -> int32 = "caml_extunix_get_hs32"
  external unsafe_get_uint63 : string -> int -> int = "caml_extunix_get_hu63" [@@noalloc]
  external unsafe_get_int63  : string -> int -> int = "caml_extunix_get_hs63" [@@noalloc]
  external unsafe_get_int64  : string -> int -> int64 = "caml_extunix_get_hs64"

  (** [get_X str off] same as [unsafe_get_X] but with bounds checking. *)
  let get_uint8 str off =
    if off < 0 || off >= String.length str
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_uint8 str off

  let get_int8 str off =
    if off < 0 || off >= String.length str
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_int8 str off

  let get_uint16 str off =
    if off < 0 || off > String.length str - 2
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_uint16 str off

  let get_int16 str off =
    if off < 0 || off > String.length str - 2
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_int16 str off

  let get_uint31 str off =
    if off < 0 || off > String.length str - 4
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_uint31 str off

  let get_int31 str off =
    if off < 0 || off > String.length str - 4
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_int31 str off

  let get_int32 str off =
    if off < 0 || off > String.length str - 4
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_int32 str off

  let get_uint63 str off =
    if off < 0 || off > String.length str - 8
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_uint63 str off

  let get_int63 str off =
    if off < 0 || off > String.length str - 8
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_int63 str off

  let get_int64 str off =
    if off < 0 || off > String.length str - 8
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_int64 str off

  (** [unsafe_set_X buf off v] stores the integer [v] as type [X] in
      the buffer [buf] starting at offset [off]. Bounds checking is not
      performed. Use with caution and only when the program logic
      guarantees that the access is within bounds.

      Note: The 31bit functions store an ocaml int as 32bit
      integer. On 32bit platforms ocaml integers are 31bit signed and
      will be sign extended to 32bit first. Use with care.
      Note: The same applies to 63bit functions.
  *)
  external unsafe_set_uint8  : Bytes.t -> int -> int -> unit = "caml_extunix_set_8" [@@noalloc]
  external unsafe_set_int8   : Bytes.t -> int -> int -> unit = "caml_extunix_set_8" [@@noalloc]
  external unsafe_set_uint16 : Bytes.t -> int -> int -> unit = "caml_extunix_set_h16" [@@noalloc]
  external unsafe_set_int16  : Bytes.t -> int -> int -> unit = "caml_extunix_set_h16" [@@noalloc]
  external unsafe_set_uint31 : Bytes.t -> int -> int -> unit = "caml_extunix_set_h31" [@@noalloc]
  external unsafe_set_int31  : Bytes.t -> int -> int -> unit = "caml_extunix_set_h31" [@@noalloc]
  external unsafe_set_int32  : Bytes.t -> int -> int32 -> unit = "caml_extunix_set_h32" [@@noalloc]
  external unsafe_set_uint63 : Bytes.t -> int -> int -> unit = "caml_extunix_set_h63" [@@noalloc]
  external unsafe_set_int63  : Bytes.t -> int -> int -> unit = "caml_extunix_set_h63" [@@noalloc]
  external unsafe_set_int64  : Bytes.t -> int -> int64 -> unit = "caml_extunix_set_h64" [@@noalloc]

  (** [set_X buf off v] same as [unsafe_set_X] but with bounds checking. *)
  let set_uint8 str off v =
    if off < 0 || off >= Bytes.length str
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_uint8 str off v

  let set_int8 str off v =
    if off < 0 || off >= Bytes.length str
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_int8 str off v

  let set_uint16 str off v =
    if off < 0 || off > Bytes.length str - 2
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_uint16 str off v

  let set_int16 str off v =
    if off < 0 || off > Bytes.length str - 2
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_int16 str off v

  let set_uint31 str off v =
    if off < 0 || off > Bytes.length str - 4
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_uint31 str off v

  let set_int31 str off v =
    if off < 0 || off > Bytes.length str - 4
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_int31 str off v

  let set_int32 str off v =
    if off < 0 || off > Bytes.length str - 4
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_int32 str off v

  let set_uint63 str off v =
    if off < 0 || off > Bytes.length str - 8
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_uint63 str off v

  let set_int63 str off v =
    if off < 0 || off > Bytes.length str - 8
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_int63 str off v

  let set_int64 str off v =
    if off < 0 || off > Bytes.length str - 8
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_int64 str off v

end

[%%have READ_CREDENTIALS

(** {2 read_credentials }

      @author Andre Nathan *)

(** Reads sender credentials from a file descriptor, returning a 3-element
    tuple containing the sender process' PID, UID and GID. *)
external read_credentials : Unix.file_descr -> int * int * int = "caml_extunix_read_credentials"

]

[%%have FEXECVE

(** {2 fexecve }

    @author Andre Nathan *)

(** [fexecve fd args env] executes the program in file represented by
    file descriptor [fd] with arguments [args] and environment
    variables given by [env]. As with the [execv*] functions, on
    success [fexecve] never returns; the current process is replaced
    by the new one.
*)
external fexecve: Unix.file_descr -> string array -> string array -> 'a = "caml_extunix_fexecve"

]

[%%have SENDMSG

(** {2 sendmsg / recvmsg }

    @author Andre Nathan *)

(** Send a message and optionally a file descriptor through a socket. Passing
    file descriptors requires UNIX domain sockets and a non-empty message. *)
external sendmsg: Unix.file_descr -> ?sendfd:Unix.file_descr -> string -> unit = "caml_extunix_sendmsg"

(** Recieve a message and possibly a file descriptor from a socket. *)
external recvmsg_fd: Unix.file_descr -> Unix.file_descr option * string = "caml_extunix_recvmsg"

(** [sendfd sock fd] sends a file descriptor [fd] through a UNIX domain socket [sock].
    This will send a sentinel message at the same time, otherwise {!sendmsg} will not pass the file descriptor. *)
let sendfd ~sock ~fd =
  sendmsg sock ~sendfd:fd "\001"

(** Receive a file descriptor sent through a UNIX domain socket, ignoring the message. *)
let recvfd fd =
  match recvmsg_fd fd with
  | (Some recvfd, _) -> recvfd
  | _ -> raise (Unix.Unix_error (Unix.EINVAL, "recvfd", "no descriptor"))

(** Receive a message sent through a UNIX domain socket. Raises
    Recvfd(fd, msg) if a file descriptor is recieved. *)
exception Recvfd of Unix.file_descr * string
let recvmsg fd =
  match recvmsg_fd fd with
  | (None, msg) -> msg
  | (Some fd, msg) -> raise (Recvfd (fd, msg))

(** Receive a message sent through a UNIX domain socket. Closes and
    ignores file descriptors. *)
let recvmsg_nofd fd =
  match recvmsg_fd fd with
  | (Some fd, msg) -> Unix.close fd; msg
  | (None, msg) -> msg

]

[%%have SYSCONF

(** {2 sysconf}

@author Roman Vorobets *)

(** name of the variable *)
type sysconf_name =
  | ARG_MAX               (** The maximum length of the arguments to the exec(3)
                              family of functions.  *)
  | CHILD_MAX             (** The max number of simultaneous processes per user
                              ID.  *)
  | HOST_NAME_MAX         (** Max length of a hostname, not including the
                              terminating null byte, as returned by
                              gethostname(2).  *)
  | LOGIN_NAME_MAX        (** Maximum length of a login name, including the
                              terminating null byte.  *)
  | CLK_TCK               (** The number of clock ticks per second.  *)
  | OPEN_MAX              (** The maximum number of files that a process can
                              have open at any time.  *)
  | PAGESIZE              (** Size of a page in bytes.  *)
  | RE_DUP_MAX            (** The number of repeated occurrences of a BRE
                              permitted by regexec(3) and regcomp(3).  *)
  | STREAM_MAX            (** The  maximum number of streams that a process can
                              have open at any time.  *)
  | SYMLOOP_MAX           (** The maximum number of symbolic links seen in a
                              pathname before resolution returns ELOOP.  *)
  | TTY_NAME_MAX          (** The maximum length of terminal device name,
                              including the terminating null byte.  *)
  | TZNAME_MAX            (** The maximum number of bytes in a timezone name.  *)
  | POSIX_VERSION         (** Indicates the year and month the POSIX.1 standard
                              was approved in the format YYYYMML; the value
                              199009L indicates the Sept. 1990 revision.  *)
  | LINE_MAX              (** The maximum length of a utility's input line,
                              either from standard input or from a file.  This
                              includes space for a trailing newline.  *)
  | POSIX2_VERSION        (** Indicates the version of the POSIX.2 standard in
                              the format of YYYYMML.  *)
  | PHYS_PAGES            (** The number of pages of physical memory.  Note that
                              it is possible for the product of this value and the
                              value of [PAGE_SIZE] to overflow. Non-standard, may be not available *)
  | AVPHYS_PAGES          (** The number of currently available pages of physical memory. Non-standard, may be not available *)
  | NPROCESSORS_CONF      (** The number of processors configured. Non-standard, may be not available *)
  | NPROCESSORS_ONLN      (** The number of processors currently online (available). Non-standard, may be not available *)

external sysconf: sysconf_name -> int64 = "caml_extunix_sysconf"

(** get configuration information at runtime, may raise [Not_available] for non-standard options (see above)
  even in [Specific] module *)
let sysconf sc =
  try
    sysconf sc
  with
    Not_found -> raise (Not_available "sysconf")

]

[%%have (SPLICE, TEE, VMSPLICE)

(**
  {2 splice}

  @author Pierre Chambart <pierre.chambart@ocamlpro.com>
*)

(** splice functions flags *)
type splice_flag =
  | SPLICE_F_MOVE     (** Attempt to move pages instead of copying. Only a hint
                          to the kernel *)
  | SPLICE_F_NONBLOCK (** Do not block on I/O *)
  | SPLICE_F_MORE     (** Announce that more data will be coming. Hint used by
                          sockets *)
  | SPLICE_F_GIFT     (** The user pages are a gift to the kernel. The
                          application may not modify this memory ever, or page
                          cache and on-disk data may differ. Gifting pages to
                          the kernel means that a subsequent splice(2)
                          SPLICE_F_MOVE can successfully move the pages; if
                          this flag is not specified, then a subsequent
                          splice(2) SPLICE_F_MOVE must copy the pages. Data
                          must also be properly page aligned, both in memory
                          and length.

                          Only use for [vmsplice]. *)

]

[%%have SPLICE

(** [splice fd_in off_in fd_out off_out len flags] moves data between two file
    descriptors without copying between kernel address space and user address
    space. It transfers up to [len] bytes of data from the file descriptor
    [fd_in] to the file descriptor [fd_out], where one of the descriptors
    must refer to a pipe.

    If [fd_in] refers to a pipe, then [off_in] must be [None]. If [fd_in] does
    not refer to a pipe and [off_in] is [None], then bytes are read from [fd_in]
    starting from the current file offset, and the current file offset is
    adjusted appropriately. If [fd_in] does not refer to a pipe and [off_in]
    is [Some n], then [n] mspecifies the starting offset from which bytes will
    be read from [fd_in]; in this case, the current file offset of [fd_in] is not
    changed. Analogous statements apply for [fd_out] and [off_out].

    @return the number of bytes spliced to or from the pipe. A return value of 0
    means that there was no data to transfer, and it would not make sense to
    block, because there are no writers connected to the write end of the pipe
    referred to by fd_in.
*)
external splice : Unix.file_descr -> int option -> Unix.file_descr -> int option -> int -> splice_flag list -> int = "caml_extunix_splice_bytecode" "caml_extunix_splice"
]

[%%have TEE

(** [tee fd_in fd_out len flags] duplicates up to [len] bytes of data from the
    pipe [fd_in] to the pipe [fd_out]. It does not consume the data that is
    duplicated from [fd_in]; therefore, that data can be copied by a subsequent
    splice.

    @return the number of bytes that were duplicated between the input and
    output. A return value of 0 means that there was no data to transfer, and
    it would not make sense to block, because there are no writers connected
    to the write end of the pipe referred to by fd_in.
*)
external tee : Unix.file_descr -> Unix.file_descr -> int -> splice_flag list -> int = "caml_extunix_tee"
]

(** {2 Bigarray variants} *)

(** *)
module BA = struct

[%%have PREAD

(** {2 pread}

    @author Goswin von Brederlow *)

(** [all_pread fd off buf] reads up to [size of buf] bytes from file
    descriptor [fd] at offset [off] (from the start of the file) into
    the buffer [buf]. The file offset is not changed.

    [all_pread] repeats the read operation until all characters have
    been read or an error occurs. Returns less than the number of
    characters requested on EAGAIN, EWOULDBLOCK or End-of-file but
    only ever returns 0 on End-of-file. Continues the read operation
    on EINTR. Raises an Unix.Unix_error exception in all other
    cases. *)
external unsafe_all_pread: Unix.file_descr -> int -> ('a, 'b) carray -> int = "caml_extunixba_all_pread"

let all_pread fd off buf =
  if off < 0
  then invalid_arg "ExtUnix.all_pread"
  else unsafe_all_pread fd off buf

(** [single_pread fd off buf] reads up to [size of buf] bytes from file
    descriptor [fd] at offset [off] (from the start of the file) into
    the buffer [buf]. The file offset is not changed.

    [single_pread] attempts to read only once. Returns the number of
    characters read or raises an Unix.Unix_error exception. Unlike the
    string variant of the same name there is no limit on the number of
    characters read. *)
external unsafe_single_pread: Unix.file_descr -> int -> ('a, 'b) carray -> int = "caml_extunixba_single_pread"

let single_pread fd off buf =
  if off < 0
  then invalid_arg "ExtUnix.single_pread"
  else unsafe_single_pread fd off buf

(** [pread fd off buf] reads up to [size of buf] bytes from file
    descriptor [fd] at offset [off] (from the start of the file) into
    the buffer [buf]. The file offset is not changed.

    [pread] repeats the read operation until all characters have
    been read or an error occurs. Raises an Unix.Unix_error exception
    if 0 characters could be read before an error occurs. Continues
    the read operation on EINTR. Returns the number of characters
    written in all other cases. *)
external unsafe_pread: Unix.file_descr -> int -> ('a, 'b) carray -> int = "caml_extunixba_pread"

let pread fd off buf =
  if off < 0
  then invalid_arg "ExtUnix.pread"
  else unsafe_pread fd off buf

(** [intr_pread fd off buf] reads up to [size of buf] bytes from file
    descriptor [fd] at offset [off] (from the start of the file) into
    the buffer [buf]. The file offset is not changed.

    [intr_pread] repeats the read operation until all characters have
    been read or an error occurs. Raises an Unix.Unix_error exception
    if 0 characters could be read before an error occurs. Does NOT
    continue on EINTR. Returns the number of characters written in all
    other cases. *)
external unsafe_intr_pread: Unix.file_descr -> int -> ('a, 'b) carray -> int = "caml_extunixba_intr_pread"

let intr_pread fd off buf =
  if off < 0
  then invalid_arg "ExtUnix.intr_pread"
  else unsafe_intr_pread fd off buf
]

[%%have PWRITE

(** {2 pwrite}

    @author Goswin von Brederlow *)

(** [all_pwrite fd off buf] writes up to [size of buf] bytes from file
    descriptor [fd] at offset [off] (from the start of the file) into
    the buffer [buf]. The file offset is not changed.

    [all_pwrite] repeats the write operation until all characters have
    been written or an error occurs. Returns less than the number of
    characters requested on EAGAIN, EWOULDBLOCK but never 0. Continues
    the write operation on EINTR. Raises an Unix.Unix_error exception
    in all other cases. *)
external unsafe_all_pwrite: Unix.file_descr -> int -> ('a, 'b) carray -> int = "caml_extunixba_all_pwrite"

let all_pwrite fd off buf =
  if off < 0
  then invalid_arg "ExtUnix.all_pwrite"
  else unsafe_all_pwrite fd off buf

(** [single_pwrite fd off buf] writes up to [size of buf] bytes from file
    descriptor [fd] at offset [off] (from the start of the file) into
    the buffer [buf]. The file offset is not changed.

    [single_pwrite] attempts to write only once. Returns the number of
    characters written or raises an Unix.Unix_error exception. Unlike
    the string variant of the same name there is no limit on the
    number of characters written. *)
external unsafe_single_pwrite: Unix.file_descr -> int -> ('a, 'b) carray -> int = "caml_extunixba_single_pwrite"

let single_pwrite fd off buf =
  if off < 0
  then invalid_arg "ExtUnix.single_pwrite"
  else unsafe_single_pwrite fd off buf

(** [pwrite fd off buf] writes up to [size of buf] bytes from file
    descriptor [fd] at offset [off] (from the start of the file) into
    the buffer [buf]. The file offset is not changed.

    [pwrite] repeats the write operation until all characters have
    been written or an error occurs. Raises an Unix.Unix_error exception
    if 0 characters could be written before an error occurs. Continues
    the write operation on EINTR. Returns the number of characters
    written in all other cases. *)
external unsafe_pwrite: Unix.file_descr -> int -> ('a, 'b) carray -> int = "caml_extunixba_pwrite"

let pwrite fd off buf =
  if off < 0
  then invalid_arg "ExtUnix.pwrite"
  else unsafe_pwrite fd off buf

(** [intr_pwrite fd off buf] writes up to [size of buf] bytes from file
    descriptor [fd] at offset [off] (from the start of the file) into
    the buffer [buf]. The file offset is not changed.

    [intr_pwrite] repeats the write operation until all characters have
    been written or an error occurs. Raises an Unix.Unix_error exception
    if 0 characters could be written before an error occurs. Does NOT
    continue on EINTR. Returns the number of characters written in all
    other cases. *)
external unsafe_intr_pwrite: Unix.file_descr -> int -> ('a, 'b) carray -> int = "caml_extunixba_intr_pwrite"

let intr_pwrite fd off buf =
  if off < 0
  then invalid_arg "ExtUnix.intr_pwrite"
  else unsafe_intr_pwrite fd off buf
]

[%%have READ

(** {2 read}

    @author Goswin von Brederlow *)

(** [all_read fd buf] reads up to [size of buf] bytes from file
    descriptor [fd] into the buffer [buf].

    [all_read] repeats the read operation until all characters have
    been read or an error occurs. Returns less than the number of
    characters requested on EAGAIN, EWOULDBLOCK or End-of-file but
    only ever returns 0 on End-of-file. Continues the read operation
    on EINTR. Raises an Unix.Unix_error exception in all other
    cases. *)
external all_read: Unix.file_descr -> ('a, 'b) carray -> int = "caml_extunixba_all_read"

(** [single_read fd buf] reads up to [size of buf] bytes from file
    descriptor [fd] into the buffer [buf].

    [single_read] attempts to read only once. Returns the number of
    characters read or raises an Unix.Unix_error exception. Unlike the
    string variant of the same name there is no limit on the number of
    characters read. *)
external single_read: Unix.file_descr -> ('a, 'b) carray -> int = "caml_extunixba_single_read"

(** [read fd buf] reads up to [size of buf] bytes from file descriptor
    [fd] into the buffer [buf].

    [read] repeats the read operation until all characters have
    been read or an error occurs. Raises an Unix.Unix_error exception
    if 0 characters could be read before an error occurs. Continues
    the read operation on EINTR. Returns the number of characters
    written in all other cases. *)
external read: Unix.file_descr -> ('a, 'b) carray -> int = "caml_extunixba_read"

(** [intr_read fd buf] reads up to [size of buf] bytes from file
    descriptor [fd] into the buffer [buf].

    [intr_read] repeats the read operation until all characters have
    been read or an error occurs. Raises an Unix.Unix_error exception
    if 0 characters could be read before an error occurs. Does NOT
    continue on EINTR. Returns the number of characters written in all
    other cases. *)
external intr_read: Unix.file_descr -> ('a, 'b) carray -> int = "caml_extunixba_intr_read"
]

[%%have WRITE

(** {2 write}

    @author Goswin von Brederlow *)

(** [all_write fd buf] writes up to [size of buf] bytes from file
    descriptor [fd] into the buffer [buf].

    [all_write] repeats the write operation until all characters have
    been written or an error occurs. Returns less than the number of
    characters requested on EAGAIN, EWOULDBLOCK but never 0. Continues
    the write operation on EINTR. Raises an Unix.Unix_error exception
    in all other cases. *)
external all_write: Unix.file_descr -> ('a, 'b) carray -> int = "caml_extunixba_all_write"

(** [single_write fd buf] writes up to [size of buf] bytes from file
    descriptor [fd] into the buffer [buf].

    [single_write] attempts to write only once. Returns the number of
    characters written or raises an Unix.Unix_error exception. Unlike
    the string variant of the same name there is no limit on the
    number of characters written. *)
external single_write: Unix.file_descr -> ('a, 'b) carray -> int = "caml_extunixba_single_write"

(** [write fd buf] writes up to [size of buf] bytes from file
    descriptor [fd] into the buffer [buf].

    [write] repeats the write operation until all characters have
    been written or an error occurs. Raises an Unix.Unix_error exception
    if 0 characters could be written before an error occurs. Continues
    the write operation on EINTR. Returns the number of characters
    written in all other cases. *)
external write: Unix.file_descr -> ('a, 'b) carray -> int = "caml_extunixba_write"

(** [intr_write fd buf] writes up to [size of buf] bytes from file
    descriptor [fd] into the buffer [buf].

    [intr_write] repeats the write operation until all characters have
    been written or an error occurs. Raises an Unix.Unix_error exception
    if 0 characters could be written before an error occurs. Does NOT
    continue on EINTR. Returns the number of characters written in all
    other cases. *)
external intr_write: Unix.file_descr -> ('a, 'b) carray -> int = "caml_extunixba_intr_write"
]

(** {2 Byte order conversion} *)

(** {2 big endian functions}

    @author Goswin von Brederlow *)
module BigEndian = struct

[%%have ENDIAN

  (** [unsafe_get_X buf off] extract integer of type [X] from a
      buffer [buf] starting at offset [off]. Unsigned types are 0
      extended and signed types are sign extended to fill the ocaml
      type.  Bounds checking is not performed. Use with caution and
      only when the program logic guarantees that the access is within
      bounds.

      Note: The 31bit functions extract a 32bit integer and return it
      as ocaml int. On 32bit platforms this can overflow as ocaml
      integers are 31bit signed there. No error is reported if this
      occurs. Use with care.
      Note: The same applies to 63bit functions.
  *)
  external unsafe_get_uint8  : 'a carray8 -> int -> int = "caml_extunixba_get_u8" [@@noalloc]
  external unsafe_get_int8   : 'a carray8 -> int -> int = "caml_extunixba_get_s8" [@@noalloc]
  external unsafe_get_uint16 : 'a carray8 -> int -> int = "caml_extunixba_get_bu16" [@@noalloc]
  external unsafe_get_int16  : 'a carray8 -> int -> int = "caml_extunixba_get_bs16" [@@noalloc]
  external unsafe_get_uint31 : 'a carray8 -> int -> int = "caml_extunixba_get_bu31" [@@noalloc]
  external unsafe_get_int31  : 'a carray8 -> int -> int = "caml_extunixba_get_bs31" [@@noalloc]
  external unsafe_get_int32  : 'a carray8 -> int -> int32 = "caml_extunixba_get_bs32"
  external unsafe_get_uint63 : 'a carray8 -> int -> int = "caml_extunixba_get_bu63" [@@noalloc]
  external unsafe_get_int63  : 'a carray8 -> int -> int = "caml_extunixba_get_bs63" [@@noalloc]
  external unsafe_get_int64  : 'a carray8 -> int -> int64 = "caml_extunixba_get_bs64"

  (** [get_X buf off] same as [unsafe_get_X] but with bounds checking. *)
  let get_uint8 buf off =
    if off < 0 || off >= Bigarray.Array1.dim buf
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_uint8 buf off

  let get_int8 buf off =
    if off < 0 || off >= Bigarray.Array1.dim buf
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_int8 buf off

  let get_uint16 buf off =
    if off < 0 || off > Bigarray.Array1.dim buf - 2
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_uint16 buf off

  let get_int16 buf off =
    if off < 0 || off > Bigarray.Array1.dim buf - 2
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_int16 buf off

  let get_uint31 buf off =
    if off < 0 || off > Bigarray.Array1.dim buf - 4
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_uint31 buf off

  let get_int31 buf off =
    if off < 0 || off > Bigarray.Array1.dim buf - 4
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_int31 buf off

  let get_int32 buf off =
    if off < 0 || off > Bigarray.Array1.dim buf - 4
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_int32 buf off

  let get_uint63 buf off =
    if off < 0 || off > Bigarray.Array1.dim buf - 8
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_uint63 buf off

  let get_int63 buf off =
    if off < 0 || off > Bigarray.Array1.dim buf - 8
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_int63 buf off

  let get_int64 buf off =
    if off < 0 || off > Bigarray.Array1.dim buf - 8
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_int64 buf off

  (** [unsafe_set_X buf off v] stores the integer [v] as type [X] in a
      buffer [buf] starting at offset [off]. Bounds checking is not
      performed. Use with caution and only when the program logic
      guarantees that the access is within bounds.

      Note: The 31bit functions store an ocaml int as 32bit
      integer. On 32bit platforms ocaml integers are 31bit signed and
      will be sign extended to 32bit first. Use with care.
      Note: The same applies to 63bit function.
  *)
  external unsafe_set_uint8  : 'a carray8 -> int -> int -> unit = "caml_extunixba_set_8" [@@noalloc]
  external unsafe_set_int8   : 'a carray8 -> int -> int -> unit = "caml_extunixba_set_8" [@@noalloc]
  external unsafe_set_uint16 : 'a carray8 -> int -> int -> unit = "caml_extunixba_set_b16" [@@noalloc]
  external unsafe_set_int16  : 'a carray8 -> int -> int -> unit = "caml_extunixba_set_b16" [@@noalloc]
  external unsafe_set_uint31 : 'a carray8 -> int -> int -> unit = "caml_extunixba_set_b31" [@@noalloc]
  external unsafe_set_int31  : 'a carray8 -> int -> int -> unit = "caml_extunixba_set_b31" [@@noalloc]
  external unsafe_set_int32  : 'a carray8 -> int -> int32 -> unit = "caml_extunixba_set_b32" [@@noalloc]
  external unsafe_set_uint63 : 'a carray8 -> int -> int -> unit = "caml_extunixba_set_b63" [@@noalloc]
  external unsafe_set_int63  : 'a carray8 -> int -> int -> unit = "caml_extunixba_set_b63" [@@noalloc]
  external unsafe_set_int64  : 'a carray8 -> int -> int64 -> unit = "caml_extunixba_set_b64" [@@noalloc]

  (** [set_X buf off v] same as [unsafe_set_X] but with bounds checking. *)
  let set_uint8 buf off v =
    if off < 0 || off >= Bigarray.Array1.dim buf
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_uint8 buf off v

  let set_int8 buf off v =
    if off < 0 || off >= Bigarray.Array1.dim buf
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_int8 buf off v

  let set_uint16 buf off v =
    if off < 0 || off > Bigarray.Array1.dim buf - 2
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_uint16 buf off v

  let set_int16 buf off v =
    if off < 0 || off > Bigarray.Array1.dim buf - 2
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_int16 buf off v

  let set_uint31 buf off v =
    if off < 0 || off > Bigarray.Array1.dim buf - 4
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_uint31 buf off v

  let set_int31 buf off v =
    if off < 0 || off > Bigarray.Array1.dim buf - 4
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_int31 buf off v

  let set_int32 buf off v =
    if off < 0 || off > Bigarray.Array1.dim buf - 4
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_int32 buf off v

  let set_uint63 buf off v =
    if off < 0 || off > Bigarray.Array1.dim buf - 8
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_uint63 buf off v

  let set_int63 buf off v =
    if off < 0 || off > Bigarray.Array1.dim buf - 8
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_int63 buf off v

  let set_int64 buf off v =
    if off < 0 || off > Bigarray.Array1.dim buf - 8
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_int64 buf off v

]

end (* module BigEndian *)

(** {2 little endian functions}

    @author Goswin von Brederlow *)
module LittleEndian = struct

[%%have ENDIAN

  (** [unsafe_get_X buf off] extract integer of type [X] from a
      buffer [buf] starting at offset [off]. Unsigned types are 0
      extended and signed types are sign extended to fill the ocaml
      type.  Bounds checking is not performed. Use with caution and
      only when the program logic guarantees that the access is within
      bounds.

      Note: The 31bit functions extract a 32bit integer and return it
      as ocaml int. On 32bit platforms this can overflow as ocaml
      integers are 31bit signed there. No error is reported if this
      occurs. Use with care.
      Note: The same applies to 63bit functions.
  *)
  external unsafe_get_uint8  : 'a carray8 -> int -> int = "caml_extunixba_get_u8" [@@noalloc]
  external unsafe_get_int8   : 'a carray8 -> int -> int = "caml_extunixba_get_s8" [@@noalloc]
  external unsafe_get_uint16 : 'a carray8 -> int -> int = "caml_extunixba_get_lu16" [@@noalloc]
  external unsafe_get_int16  : 'a carray8 -> int -> int = "caml_extunixba_get_ls16" [@@noalloc]
  external unsafe_get_uint31 : 'a carray8 -> int -> int = "caml_extunixba_get_lu31" [@@noalloc]
  external unsafe_get_int31  : 'a carray8 -> int -> int = "caml_extunixba_get_ls31" [@@noalloc]
  external unsafe_get_int32  : 'a carray8 -> int -> int32 = "caml_extunixba_get_ls32"
  external unsafe_get_uint63 : 'a carray8 -> int -> int = "caml_extunixba_get_lu63" [@@noalloc]
  external unsafe_get_int63  : 'a carray8 -> int -> int = "caml_extunixba_get_ls63" [@@noalloc]
  external unsafe_get_int64  : 'a carray8 -> int -> int64 = "caml_extunixba_get_ls64"

  (** [get_X buf off] same as [unsafe_get_X] but with bounds checking. *)
  let get_uint8 buf off =
    if off < 0 || off >= Bigarray.Array1.dim buf
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_uint8 buf off

  let get_int8 buf off =
    if off < 0 || off >= Bigarray.Array1.dim buf
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_int8 buf off

  let get_uint16 buf off =
    if off < 0 || off > Bigarray.Array1.dim buf - 2
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_uint16 buf off

  let get_int16 buf off =
    if off < 0 || off > Bigarray.Array1.dim buf - 2
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_int16 buf off

  let get_uint31 buf off =
    if off < 0 || off > Bigarray.Array1.dim buf - 4
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_uint31 buf off

  let get_int31 buf off =
    if off < 0 || off > Bigarray.Array1.dim buf - 4
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_int31 buf off

  let get_int32 buf off =
    if off < 0 || off > Bigarray.Array1.dim buf - 4
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_int32 buf off

  let get_uint63 buf off =
    if off < 0 || off > Bigarray.Array1.dim buf - 8
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_uint63 buf off

  let get_int63 buf off =
    if off < 0 || off > Bigarray.Array1.dim buf - 8
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_int63 buf off

  let get_int64 buf off =
    if off < 0 || off > Bigarray.Array1.dim buf - 8
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_int64 buf off

  (** [unsafe_set_X buf off v] stores the integer [v] as type [X] in a
      buffer [buf] starting at offset [off]. Bounds checking is not
      performed. Use with caution and only when the program logic
      guarantees that the access is within bounds.

      Note: The 31bit functions store an ocaml int as 32bit
      integer. On 32bit platforms ocaml integers are 31bit signed and
      will be sign extended to 32bit first. Use with care.
      Note: The same applies to 63bit functions.
  *)
  external unsafe_set_uint8  : 'a carray8 -> int -> int -> unit = "caml_extunixba_set_8" [@@noalloc]
  external unsafe_set_int8   : 'a carray8 -> int -> int -> unit = "caml_extunixba_set_8" [@@noalloc]
  external unsafe_set_uint16 : 'a carray8 -> int -> int -> unit = "caml_extunixba_set_l16" [@@noalloc]
  external unsafe_set_int16  : 'a carray8 -> int -> int -> unit = "caml_extunixba_set_l16" [@@noalloc]
  external unsafe_set_uint31 : 'a carray8 -> int -> int -> unit = "caml_extunixba_set_l31" [@@noalloc]
  external unsafe_set_int31  : 'a carray8 -> int -> int -> unit = "caml_extunixba_set_l31" [@@noalloc]
  external unsafe_set_int32  : 'a carray8 -> int -> int32 -> unit = "caml_extunixba_set_l32" [@@noalloc]
  external unsafe_set_uint63 : 'a carray8 -> int -> int -> unit = "caml_extunixba_set_l63" [@@noalloc]
  external unsafe_set_int63  : 'a carray8 -> int -> int -> unit = "caml_extunixba_set_l63" [@@noalloc]
  external unsafe_set_int64  : 'a carray8 -> int -> int64 -> unit = "caml_extunixba_set_l64" [@@noalloc]

  (** [set_X buf off v] same as [unsafe_set_X] but with bounds checking. *)
  let set_uint8 buf off v =
    if off < 0 || off >= Bigarray.Array1.dim buf
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_uint8 buf off v

  let set_int8 buf off v =
    if off < 0 || off >= Bigarray.Array1.dim buf
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_int8 buf off v

  let set_uint16 buf off v =
    if off < 0 || off > Bigarray.Array1.dim buf - 2
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_uint16 buf off v

  let set_int16 buf off v =
    if off < 0 || off > Bigarray.Array1.dim buf - 2
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_int16 buf off v

  let set_uint31 buf off v =
    if off < 0 || off > Bigarray.Array1.dim buf - 4
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_uint31 buf off v

  let set_int31 buf off v =
    if off < 0 || off > Bigarray.Array1.dim buf - 4
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_int31 buf off v

  let set_int32 buf off v =
    if off < 0 || off > Bigarray.Array1.dim buf - 4
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_int32 buf off v

  let set_uint63 buf off v =
    if off < 0 || off > Bigarray.Array1.dim buf - 8
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_uint63 buf off v

  let set_int63 buf off v =
    if off < 0 || off > Bigarray.Array1.dim buf - 8
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_int63 buf off v

  let set_int64 buf off v =
    if off < 0 || off > Bigarray.Array1.dim buf - 8
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_int64 buf off v

]

end (* module LittleEndian *)

(** {2 host endian functions}

    @author Goswin von Brederlow *)
module HostEndian = struct

  (** [unsafe_get_X buf off] extract integer of type [X] from a
      buffer [buf] starting at offset [off]. Unsigned types are 0
      extended and signed types are sign extended to fill the ocaml
      type.  Bounds checking is not performed. Use with caution and
      only when the program logic guarantees that the access is within
      bounds.

      Note: The 31bit functions extract a 32bit integer and return it
      as ocaml int. On 32bit platforms this can overflow as ocaml
      integers are 31bit signed there. No error is reported if this
      occurs. Use with care.
      Note: The same applies to 63bit functions.
  *)
  external unsafe_get_uint8  : 'a carray8 -> int -> int = "caml_extunixba_get_u8" [@@noalloc]
  external unsafe_get_int8   : 'a carray8 -> int -> int = "caml_extunixba_get_s8" [@@noalloc]
  external unsafe_get_uint16 : 'a carray8 -> int -> int = "caml_extunixba_get_hu16" [@@noalloc]
  external unsafe_get_int16  : 'a carray8 -> int -> int = "caml_extunixba_get_hs16" [@@noalloc]
  external unsafe_get_uint31 : 'a carray8 -> int -> int = "caml_extunixba_get_hu31" [@@noalloc]
  external unsafe_get_int31  : 'a carray8 -> int -> int = "caml_extunixba_get_hs31" [@@noalloc]
  external unsafe_get_int32  : 'a carray8 -> int -> int32 = "caml_extunixba_get_hs32"
  external unsafe_get_uint63 : 'a carray8 -> int -> int = "caml_extunixba_get_hu63" [@@noalloc]
  external unsafe_get_int63  : 'a carray8 -> int -> int = "caml_extunixba_get_hs63" [@@noalloc]
  external unsafe_get_int64  : 'a carray8 -> int -> int64 = "caml_extunixba_get_hs64"

  (** [get_X buf off] same as [unsafe_get_X] but with bounds checking. *)
  let get_uint8 buf off =
    if off < 0 || off >= Bigarray.Array1.dim buf
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_uint8 buf off

  let get_int8 buf off =
    if off < 0 || off >= Bigarray.Array1.dim buf
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_int8 buf off

  let get_uint16 buf off =
    if off < 0 || off > Bigarray.Array1.dim buf - 2
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_uint16 buf off

  let get_int16 buf off =
    if off < 0 || off > Bigarray.Array1.dim buf - 2
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_int16 buf off

  let get_uint31 buf off =
    if off < 0 || off > Bigarray.Array1.dim buf - 4
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_uint31 buf off

  let get_int31 buf off =
    if off < 0 || off > Bigarray.Array1.dim buf - 4
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_int31 buf off

  let get_int32 buf off =
    if off < 0 || off > Bigarray.Array1.dim buf - 4
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_int32 buf off

  let get_uint63 buf off =
    if off < 0 || off > Bigarray.Array1.dim buf - 8
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_uint63 buf off

  let get_int63 buf off =
    if off < 0 || off > Bigarray.Array1.dim buf - 8
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_int63 buf off

  let get_int64 buf off =
    if off < 0 || off > Bigarray.Array1.dim buf - 8
    then raise (Invalid_argument "index out of bounds");
    unsafe_get_int64 buf off

  (** [unsafe_set_X buf off v] stores the integer [v] as type [X] in a
      buffer [buf] starting at offset [off]. Bounds checking is not
      performed. Use with caution and only when the program logic
      guarantees that the access is within bounds.

      Note: The 31bit functions store an ocaml int as 32bit
      integer. On 32bit platforms ocaml integers are 31bit signed and
      will be sign extended to 32bit first. Use with care.
      Note: The same applies to 63bit functions.
  *)
  external unsafe_set_uint8  : 'a carray8 -> int -> int -> unit = "caml_extunixba_set_8" [@@noalloc]
  external unsafe_set_int8   : 'a carray8 -> int -> int -> unit = "caml_extunixba_set_8" [@@noalloc]
  external unsafe_set_uint16 : 'a carray8 -> int -> int -> unit = "caml_extunixba_set_h16" [@@noalloc]
  external unsafe_set_int16  : 'a carray8 -> int -> int -> unit = "caml_extunixba_set_h16" [@@noalloc]
  external unsafe_set_uint31 : 'a carray8 -> int -> int -> unit = "caml_extunixba_set_h31" [@@noalloc]
  external unsafe_set_int31  : 'a carray8 -> int -> int -> unit = "caml_extunixba_set_h31" [@@noalloc]
  external unsafe_set_int32  : 'a carray8 -> int -> int32 -> unit = "caml_extunixba_set_h32" [@@noalloc]
  external unsafe_set_uint63 : 'a carray8 -> int -> int -> unit = "caml_extunixba_set_h63" [@@noalloc]
  external unsafe_set_int63  : 'a carray8 -> int -> int -> unit = "caml_extunixba_set_h63" [@@noalloc]
  external unsafe_set_int64  : 'a carray8 -> int -> int64 -> unit = "caml_extunixba_set_h64" [@@noalloc]

  (** [set_X buf off v] same as [unsafe_set_X] but with bounds checking. *)
  let set_uint8 buf off v =
    if off < 0 || off >= Bigarray.Array1.dim buf
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_uint8 buf off v

  let set_int8 buf off v =
    if off < 0 || off >= Bigarray.Array1.dim buf
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_int8 buf off v

  let set_uint16 buf off v =
    if off < 0 || off > Bigarray.Array1.dim buf - 2
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_uint16 buf off v

  let set_int16 buf off v =
    if off < 0 || off > Bigarray.Array1.dim buf - 2
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_int16 buf off v

  let set_uint31 buf off v =
    if off < 0 || off > Bigarray.Array1.dim buf - 4
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_uint31 buf off v

  let set_int31 buf off v =
    if off < 0 || off > Bigarray.Array1.dim buf - 4
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_int31 buf off v

  let set_int32 buf off v =
    if off < 0 || off > Bigarray.Array1.dim buf - 4
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_int32 buf off v

  let set_uint63 buf off v =
    if off < 0 || off > Bigarray.Array1.dim buf - 8
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_uint63 buf off v

  let set_int63 buf off v =
    if off < 0 || off > Bigarray.Array1.dim buf - 8
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_int63 buf off v

  let set_int64 buf off v =
    if off < 0 || off > Bigarray.Array1.dim buf - 8
    then raise (Invalid_argument "index out of bounds");
    unsafe_set_int64 buf off v

end (* module HostEndian *)

(** [unsafe_get_substr buf off len] extracts the substring from buffer
    [buf] starting at offset [off] and length [len]. Bounds checking
    is not performed. Use with caution and only when the program logic
    guarantees that the access is within bounds.*)
external unsafe_get_substr : 'a carray8 -> int -> int -> string = "caml_extunixba_get_substr"

(** [get_substr buf off len] same as [unsafe_get_substr] but with
    bounds checking. *)
let get_substr buf off len =
  if off < 0 || len < 0 || off > Bigarray.Array1.dim buf - len
  then raise (Invalid_argument "index out of bounds");
  unsafe_get_substr buf off len

(** [unsafe_set_substr buf off str] stores the string in buffer [buf]
    starting at offset [off]. Bounds checking is not performed. Use
    with caution and only when the program logic guarantees that the
    access is within bounds.*)
external unsafe_set_substr : 'a carray8 -> int -> string -> unit = "caml_extunixba_set_substr"

(** [set_substr buf off str] same as [unsafe_set_substr] but with
    bounds checking. *)
let set_substr buf off str =
  if off < 0 || off > Bigarray.Array1.dim buf - String.length str
  then raise (Invalid_argument "index out of bounds");
  unsafe_set_substr buf off str

[%%have VMSPLICE

(**
  {2 splice}

  @author Pierre Chambart <pierre.chambart@ocamlpro.com>
*)

(** I/O vector. Used to send multiple data using a single system call *)
type 'a iov = {
  iov_buf : 'a carray8;
  iov_off : int;
  iov_len : int;
}

(** [vmsplice fd iovs flags] sends the data described by [iovs] to the pipe [fd]
    @return the number of bytes transferred to the pipe. *)
external vmsplice : Unix.file_descr -> 'a iov array -> splice_flag list -> int = "caml_extunixba_vmsplice"
]

end (* module BA *)

(* NB Should be after all 'external' definitions *)

(** {2 Meta} *)

[%%show_me_the_money
  [@@@ocaml.doc {|
[have name]
  @return indication whether function [name] is available
  - [Some true] if available
  - [Some false] if not available
  - [None] if not known

  e.g. [have "eventfd"]|}]]

(* vim: ft=ocaml
*)
