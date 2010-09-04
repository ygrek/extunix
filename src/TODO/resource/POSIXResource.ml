(******************************************************************************)
(*  ocaml-posix-resource: POSIX resource operations                           *)
(*                                                                            *)
(*  Copyright (C) 2009 Sylvain Le Gall <sylvain@le-gall.net>                  *)
(*                                                                            *)
(*  This library is free software; you can redistribute it and/or modify it   *)
(*  under the terms of the GNU Lesser General Public License as published by  *)
(*  the Free Software Foundation; either version 2.1 of the License, or (at   *)
(*  your option) any later version; with the OCaml static compilation         *)
(*  exception.                                                                *)
(*                                                                            *)
(*  This library is distributed in the hope that it will be useful, but       *)
(*  WITHOUT ANY WARRANTY; without even the implied warranty of                *)
(*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser  *)
(*  General Public License for more details.                                  *)
(*                                                                            *)
(*  You should have received a copy of the GNU Lesser General Public License  *)
(*  along with this library; if not, write to the Free Software Foundation,   *)
(*  Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA               *)
(******************************************************************************)

(** Main interface of ocaml-posix-resource.
    @author Sylvain Le Gall <sylvain@le-gall.net>
  *)

(** {2 Types} *)

exception NotImplemented of string;; (* Function or limit is not implemented on the
                              running platform *)

let string_of_exception exc =
  match exc with
    NotImplemented s ->
      Printf.sprintf "%s not implemented" s
  | _ ->
      raise exc
;;

type which_prio_t =
  | PRIO_PROCESS of int (* Priority for a process id *)
  | PRIO_PGRP of int    (* Priority for a process group id *)
  | PRIO_USER of int    (* Priority for a user id *)
;;

type priority_t = int;;

type 'a change_limit_t =
  | No_change
  | Limit of 'a
;;

type resource_t = 
  | RLIMIT_CORE   (* Limit on size of core dump file. *)
  | RLIMIT_CPU    (* Limit on CPU time per process. *)
  | RLIMIT_DATA   (* Limit on data segment size. *)
  | RLIMIT_FSIZE  (* Limit on file size. *)
  | RLIMIT_NOFILE (* Limit on number of open files. *)
  | RLIMIT_STACK  (* Limit on stack size. *)
  | RLIMIT_AS     (* Limit on address space size. *)
;;

(** {2 Limits} *)

module Limit = 
struct

  type t = int64 option

  let to_string ?(resource) =
    function
      | None -> "none"
      | Some l -> 
          (
            let string_of_byte l =
              let sz, acc =  
                List.fold_left
                  (fun (sz, acc) e ->
                     let q =
                       Int64.div sz 1024L
                     in
                     let r = 
                       Int64.rem sz 1024L
                     in
                     let acc =
                       if r <> 0L then
                         (Printf.sprintf "%Ld %s" r e) :: acc
                       else
                         acc
                     in
                       (q, acc))
                  (l, [])
                  ["B"; "KB"; "MB"; "GB"] 
              in
              let acc =
                if sz <> 0L then
                  (Printf.sprintf "%Ld TB" sz) :: acc
                else
                  acc
              in
                if acc <> [] then
                  String.concat " " acc
                else
                  "0 B"
            in

            match resource with 
              | None ->
                  Int64.to_string l
              | Some RLIMIT_CORE  
              | Some RLIMIT_DATA 
              | Some RLIMIT_FSIZE
              | Some RLIMIT_STACK
              | Some RLIMIT_AS ->
                  string_of_byte l
              | Some RLIMIT_NOFILE ->
                  Int64.to_string l
              | Some RLIMIT_CPU ->
                  Printf.sprintf "%Ld s" l
          )

  let compare l1 l2 =
    match l1, l2 with
      | Some l1, Some l2 ->
          Int64.compare l1 l2
      | None, None ->
          0
      | Some _, None ->
          -1
      | None, Some _ ->
          1

  let equal l1 l2 =
    (compare l1 l2) = 0
end
;;

module SoftLimit = Limit;;
module HardLimit = Limit;;

(** {2 Functions} *)

let string_of_resource =
  function
    | RLIMIT_CORE -> "Size of core dump file" 
    | RLIMIT_CPU -> "CPU time per process"
    | RLIMIT_DATA -> "Data segment size"
    | RLIMIT_FSIZE -> "File size"
    | RLIMIT_NOFILE -> "Number of open file"
    | RLIMIT_STACK  -> "Stack size"
    | RLIMIT_AS -> "Address space size"
;;

let string_of_change_limit ?(resource) =
  function
    | No_change -> "same as before"
    | Limit lmt -> Limit.to_string ?resource lmt 
;;

let _ =
  Callback.register_exception "POSIXResource.NotImplemented" (NotImplemented "nothing")
;;

(** Get nice value
  *)
external getpriority: which_prio_t -> priority_t = 
  "caml_resource_getpriority_stub";;

(** Set nice value
  *)
external setpriority: which_prio_t -> priority_t -> unit = 
  "caml_resource_setpriority_stub";;

(** Get maximum resource consumption
  *)
external getrlimit: resource_t -> SoftLimit.t * HardLimit.t =
  "caml_resource_getrlimit_stub";;

(** Set maximum resource consumption
  *)
external setrlimit: 
  resource_t -> 
  SoftLimit.t change_limit_t -> 
  HardLimit.t change_limit_t -> unit =
  "caml_resource_setrlimit_stub";;

(** [getrusage] is not implemented because the only meaningful information it
    provides are [ru_utime] and [ru_stime] which can be accessed through 
    [Unix.times].
  *)

(** Library version 
  *)
let version =
  POSIXResourceConfig.version
;;
