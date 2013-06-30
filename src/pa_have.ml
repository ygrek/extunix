(**
  New toplevel statement (structure item): HAVE <uident> { OR <uident> }* <structure_items> END
  if (Config.have "<uident>") is true (for any of the uident's provided) then enclosed structure items are left as is,
  otherwise:
    if -gen-all was specified then external declarations in the scope are rewritten to raise exception when called,
    otherwise all contents is dropped altogether
*)

module Have(Syntax : Camlp4.Sig.Camlp4Syntax) =
struct
  open Camlp4.PreCast 

  include Syntax

  let all = ref false
  let verbose = ref false

  let funcs = Hashtbl.create 16

  let rec make_dummy_f body = function
  | <:ctyp@loc< ~ $s$ : $t$ -> $tl$ >> -> <:expr@loc< fun ~ $s$:(_:$t$) -> $make_dummy_f body tl$ >>
  | <:ctyp@loc< ? $s$ : $t$ -> $tl$ >> -> <:expr@loc< fun ? $s$:(_:option $t$) -> $make_dummy_f body tl$ >>
  | <:ctyp@loc< $t$ -> $tl$ >> -> <:expr@loc< fun (_:$t$) -> $make_dummy_f body tl$ >>
  | <:ctyp< $t$ >> -> let loc = Loc.ghost in <:expr@loc< ($body$ : $t$) >>

  let invalid_external = function
  | <:str_item@_loc< external $i$ : $t$ = $sl$ >> ->
      <:str_item< value $lid:i$ = $make_dummy_f <:expr< raise (Not_available $str:i$) >> t$; >>
  | e -> e

  let record_external have si =
    begin match si with
    | <:str_item@_loc< external $i$ : $t$ = $sl$ >> ->
(*       if Hashtbl.mem funcs i then failwith (Printf.sprintf "duplicate external %s" i); *)
      Hashtbl.replace funcs i have
    | _ -> () end;
    si

  let map_str_item f e = (Ast.map_str_item f)#str_item e

  let make_have loc =
    Hashtbl.fold (fun func have acc -> <:match_case@loc< $`str:func$ -> Some ($`bool:have$) | $acc$ >>)
      funcs
      <:match_case@loc< _ -> None >>

  let show name s = if !verbose then Printf.eprintf "%-20s %s\n%!" name s

  let check name = match Config.have name with
    | None -> failwith ("Unregistered feature : " ^ name)
    | Some have -> have

  EXTEND Gram
    GLOBAL: str_item;
    str_item:
      [ [ "HAVE"; names=alternatives_list; si=str_items; "END" ->
          let have = List.for_all check names in
          let name = String.concat " or " names in
          let _ = map_str_item (record_external have) <:str_item< $si$ >> in
          match have, !all with
          | true, _ -> show name "ok"; si
          | false, true -> show name "rewrite"; map_str_item invalid_external <:str_item< $si$ >>
          | false, false -> show name "drop"; <:str_item<>> ]
      | [ "SHOW"; "ME"; "THE"; "MONEY" ->
          if !all then
            <:str_item< value have = fun [ $make_have _loc$ ] >>
          else
            <:str_item<>> ]
      ];
    alternatives_list:
      [ [ name=UIDENT ->
          [ name ] ]
      | [ rest=alternatives_list; "OR"; name=UIDENT ->
          name :: rest ]
      ]
    ;
  END

  ;;

  Camlp4.Options.add "-gen-all" (Arg.Set all) " generate values from all HAVE sections";;
  Camlp4.Options.add "-gen-verbose" (Arg.Set verbose) " verbose mode";;

end

module Id = struct
let version = "0"
let name = "Have"
end

module M = Camlp4.Register.OCamlSyntaxExtension(Id)(Have)
