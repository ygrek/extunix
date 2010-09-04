
(** Truncate file 
    @author Sylvain Le Gall
  *)

(**/**)
let is_win32 = 
  Sys.os_type = "Win32"
;;

external win32_ftruncate: Unix.file_descr -> int -> unit = 
 "caml_ftruncate_win32"
;;
(**/**)

let ftruncate =
  if is_win32 then
    win32_ftruncate 
  else
    Unix.ftruncate 
;;

module LargeFile =
struct 
  (**/**)
  external win32_ftruncate: Unix.file_descr -> int64 -> unit = 
   "caml_ftruncate64_win32"
  (**/**)

  let ftruncate = 
    if is_win32 then
      win32_ftruncate 
    else
      Unix.LargeFile.ftruncate
end;;
