let all = ref false

let funcs = Hashtbl.create 16

let args_spec =
  [
    ("--gen-all", Arg.Set all, "generate values from all [%%have ...] sections");
  ]

module ExtUnixConfig = Config
open Ppxlib

let check ~loc name =
  match ExtUnixConfig.feature name with
  | None -> Location.raise_errorf ~loc "Unregistered feature %s" name
  | Some have -> have

let ident x = Ocaml_common.Location.mknoloc (lident x)

(* Evaluating conditions *)

let atom_of_expr ~loc expr =
  match expr.pexp_desc with
  | Pexp_construct ({ txt = Longident.Lident x; _ }, None) -> x
  | _ -> Location.raise_errorf ~loc "have: atom_of_expr"

let conj_of_expr ~loc expr =
  match expr.pexp_desc with
  | Pexp_construct _ -> [ atom_of_expr ~loc expr ]
  | Pexp_tuple args -> List.map (atom_of_expr ~loc) args
  | _ -> Location.raise_errorf ~loc "have: conj_of_expr"

let disj_of_expr ~loc expr =
  match expr.pexp_desc with
  | Pexp_construct _ -> [ [ atom_of_expr ~loc expr ] ]
  | Pexp_tuple args -> List.map (conj_of_expr ~loc) args
  | _ -> Location.raise_errorf ~loc "have: disj_of_expr"

let eval_cond ~loc cond =
  match cond.pstr_desc with
  | Pstr_eval (expr, _attributes) ->
      List.exists (List.for_all (check ~loc)) (disj_of_expr ~loc expr)
  | _ -> Location.raise_errorf ~loc "have: eval_cond"

(* have rule *)

let invalid_external ~loc =
  let open Ast_builder.Default in
  let rec make_dummy_f ~loc body typ =
    match typ.ptyp_desc with
    | Ptyp_arrow (l, arg, ret) ->
        let arg =
          match l with Optional _ -> [%type: [%t arg] option] | _ -> arg
        in
        let e = make_dummy_f ~loc body ret in
        pexp_fun ~loc l None [%pat? (_ : [%t arg])] e
    | _ -> [%expr ([%e body] : [%t typ])]
  in
  let raise_not_available ~loc x =
    let e = pexp_constant ~loc (Pconst_string (x, loc, None)) in
    [%expr raise (Not_available [%e e])]
  in
  let externals_of =
    object
      inherit Ast_traverse.map as super

      method! structure_item x =
        match x.pstr_desc with
        | Pstr_primitive p ->
            let body = raise_not_available ~loc p.pval_name.txt in
            let expr = make_dummy_f ~loc body p.pval_type in
            let pat = ppat_var ~loc p.pval_name in
            let vb = value_binding ~loc ~pat ~expr in
            let vb =
              { vb with pvb_attributes = p.pval_attributes @ vb.pvb_attributes }
            in
            pstr_value ~loc Nonrecursive [ vb ]
        | _ -> super#structure_item x
    end
  in
  externals_of#structure_item

let record_external have =
  let externals_of =
    object
      inherit Ast_traverse.iter as super

      method! structure_item x =
        match x.pstr_desc with
        | Pstr_primitive p -> Hashtbl.replace funcs p.pval_name.txt have
        | _ -> super#structure_item x
    end
  in
  externals_of#structure_item

let have_expand ~ctxt cond items =
  let loc = Expansion_context.Extension.extension_point_loc ctxt in
  let have = eval_cond ~loc cond in
  List.iter (record_external have) items;
  match (have, !all) with
  | true, _ -> items
  | false, true -> List.map (invalid_external ~loc) items
  | false, false -> []

let have_extension =
  Extension.V3.declare_inline "have" Extension.Context.structure_item
    Ast_pattern.(pstr (__ ^:: __))
    have_expand

let have_rule = Context_free.Rule.extension have_extension

(* show_me_the_money rule *)

let show_me_the_money_expand ~ctxt doc =
  let loc = Expansion_context.Extension.extension_point_loc ctxt in
  let open Ast_builder.Default in
  let make_have () =
    Hashtbl.fold
      (fun func have acc ->
        let lhs = ppat_constant ~loc (Pconst_string (func, loc, None)) in
        let e = pexp_construct ~loc (ident (string_of_bool have)) None in
        case ~lhs ~guard:None ~rhs:[%expr Some [%e e]] :: acc)
      funcs
      [ case ~lhs:[%pat? _] ~guard:None ~rhs:[%expr None] ]
  in
  if !all then
    let expr = pexp_function ~loc (make_have ()) in
    let pat = ppat_var ~loc (Ocaml_common.Location.mknoloc "have") in
    let vb = value_binding ~loc ~pat ~expr in
    let vb = { vb with pvb_attributes = doc :: vb.pvb_attributes } in
    [ pstr_value ~loc Nonrecursive [ vb ] ]
  else []

let show_me_the_money_extension =
  Extension.V3.declare_inline "show_me_the_money"
    Extension.Context.structure_item
    Ast_pattern.(pstr (pstr_attribute __ ^:: nil))
    show_me_the_money_expand

let show_me_the_money_rule =
  Context_free.Rule.extension show_me_the_money_extension

let () =
  List.iter (fun (key, spec, doc) -> Driver.add_arg key spec ~doc) args_spec;
  let rules = [ have_rule; show_me_the_money_rule ] in
  Driver.register_transformation ~rules "ppx_have"
