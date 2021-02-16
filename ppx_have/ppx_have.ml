open Migrate_parsetree

(********************)

(* Define the rewriter on OCaml 4.05 AST *)
let ocaml_version = Versions.ocaml_405

(********************)

let all = ref false
let funcs = Hashtbl.create 16

let args_spec = [
    "--gen-all", Arg.Set all,
    " generate values from all [%%have ...] sections"
  ]

let reset_args () = Hashtbl.clear funcs

(********************)

let check name = match Config.feature name with
  | None -> failwith ("Unregistered feature : " ^ name)
  | Some have -> have

open Ast_405
open Parsetree
open Asttypes
open Ast_helper

(* Helpers *)

let ident x =
  Location.mknoloc (Longident.Lident x)

let incl x =
  {pincl_mod = x; pincl_loc = !default_loc; pincl_attributes = []}

let case pc_lhs pc_rhs =
  {pc_lhs; pc_guard = None; pc_rhs}

(* Core of the preprocessing *)

let rec make_dummy_f body typ =
  match typ.ptyp_desc with
  | Ptyp_arrow (l, arg, ret) ->
     let arg =
       match l with
       | Optional _ -> Typ.constr (ident "option") [arg]
       | _ -> arg
     in
     Exp.fun_ l None (Pat.constraint_ (Pat.any ()) arg)
       (make_dummy_f body ret)
  | _ -> Exp.constraint_ body typ

let raise_not_available x =
  Exp.apply (Exp.ident (ident "raise"))
    [
      Nolabel,
      Exp.construct (ident "Not_available")
        (Some (Exp.constant (Const.string x)))
    ]

let invalid_external_mapper =
  let open Ast_mapper in
  let structure_item mapper x =
    match x.pstr_desc with
    | Pstr_primitive p ->
       let body = raise_not_available p.pval_name.txt in
       let pattern = Pat.var p.pval_name in
       let vb = Vb.mk pattern (make_dummy_f body p.pval_type) in
       Str.value Nonrecursive [vb]
    | _ -> default_mapper.structure_item mapper x
  in
  {default_mapper with structure_item}

let invalid_external x =
  invalid_external_mapper.Ast_mapper.structure_item invalid_external_mapper x

let record_external_mapper have =
  let open Ast_mapper in
  let structure_item mapper x =
    match x.pstr_desc with
    | Pstr_primitive p -> Hashtbl.replace funcs p.pval_name.txt have; x
    | _ -> default_mapper.structure_item mapper x
  in
  {default_mapper with structure_item}

let record_external have x =
  let mapper = record_external_mapper have in
  ignore (mapper.Ast_mapper.structure_item mapper x)

let make_have () =
  Hashtbl.fold
    (fun func have acc ->
      (case (Pat.constant (Const.string func))
         (Exp.construct (ident "Some")
            (Some (Exp.construct (ident (string_of_bool have)) None))))
      :: acc)
    funcs
    [case (Pat.any ()) (Exp.construct (ident "None") None)]

(* Evaluating conditions *)

let atom_of_expr expr =
  match expr.pexp_desc with
  | Pexp_construct ({txt = Longident.Lident x; _}, None) -> x
  | _ -> failwith "have: atom_of_expr"

let conj_of_expr expr =
  match expr.pexp_desc with
  | Pexp_construct ({Location.txt = Longident.Lident x; _}, None) -> [x]
  | Pexp_tuple args -> List.map atom_of_expr args
  | _ -> failwith "have: conj_of_expr"

let disj_of_expr expr =
  match expr.pexp_desc with
  | Pexp_construct ({Location.txt = Longident.Lident x; _}, None) -> [[x]]
  | Pexp_tuple args -> List.map conj_of_expr args
  | _ -> failwith "have: disj_of_expr"

let eval_cond cond =
  match cond.pstr_desc with
  | Pstr_eval (expr, _attributes) ->
     List.exists (List.for_all check) (disj_of_expr expr)
  | _ -> failwith "have: eval_cond"

(* The rewriter itself *)

let mapper _config _cookies =
  let open Ast_mapper in
  let structure_item mapper pstr =
    match pstr.pstr_desc with
    | Pstr_extension (({txt = "have"; loc}, payload), _) ->
       (match payload with
        | PStr (cond :: items) ->
           let have = eval_cond cond in
           List.iter (record_external have) items;
           let items =
             match have, !all with
             | true, _ -> items
             | false, true -> List.map invalid_external items
             | false, false -> []
           in
           Str.include_ ~loc (incl (Mod.structure items))
        | _ -> failwith "have: structure_item"
       )
    | Pstr_extension (({txt = "show_me_the_money"; loc}, _), _) ->
       let items =
         if !all then
           let body = Exp.function_ (make_have ()) in
           let pattern = Pat.var (Location.mknoloc "have") in
           let vb = Vb.mk pattern body in
           [Str.value Nonrecursive [vb]]
         else
           []
       in
       Str.include_ ~loc (incl (Mod.structure items))
    | _ -> default_mapper.structure_item mapper pstr
  in
  {default_mapper with structure_item}

(********************)

(* Registration *)

let () =
  Driver.register
    ~name:"ppx_have" ~args:args_spec ~reset_args
    ocaml_version mapper

let () = Driver.run_main ()
