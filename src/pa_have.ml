(**
  New toplevel statement (structure item): HAVE <uident> <structure_items> END
  if (Config.have "<uident>") is true then enclosed structure items are left as is,
  otherwise:
    if -gen-all was specified then external structure items are rewritten to raise exception when called,
    otherwise they are dropped altogether
*)

module Have(Syntax : Camlp4.Sig.Camlp4Syntax) =
struct
  open Camlp4.PreCast 

  include Syntax

  let all = ref false

  let rec make_dummy_f body = function
  | <:ctyp@loc< $Ast.TyLab (_,s,t)$ -> $tl$ >> -> <:expr@loc< fun ~($s$:$t$) -> $make_dummy_f body tl$ >>
  | <:ctyp@loc< $t$ -> $tl$ >> -> <:expr@loc< fun (_:$t$) -> $make_dummy_f body tl$ >>
  | <:ctyp< $t$ >> -> let loc = Loc.ghost in <:expr@loc< ($body$ : $t$) >>

  let invalid_external = function
  | <:str_item@_loc< external $i$ : $t$ = $sl$ >> -> 
      <:str_item< let $lid:i$ = $make_dummy_f <:expr< raise (Not_available $str:i$) >> t$ >>
  | e -> e

  let invalid_external e =
    (* extra StSem wrap to match with <:str_item< >> *)
    (Ast.map_str_item invalid_external)#str_item (Ast.StSem (Loc.ghost,e,(Ast.StNil Loc.ghost)))

  EXTEND Gram
    GLOBAL: implem;
    implem:
      [ [ "HAVE"; name=UIDENT; si=str_items; (tail,x)=SELF ->
        let si = match Config.have name, !all with
        | Some true, _ -> si
        | Some false, true -> List.map invalid_external si
        | Some false, false -> []
        | None, _ -> failwith ("Unregistered feature : " ^ name)
        in
        si @ tail, x
      ] ]
    ;
    str_items:
      [ [ si=str_item; semi; sil=SELF -> si::sil
        | "END" -> []
      ] ]
    ;
  END

  ;;

  Camlp4.Options.add "-gen-all" (Arg.Set all) " generate values from all HAVE sections";;

end

module Id = struct
let version = "0"
let name = "Have"
end

module M = Camlp4.Register.OCamlSyntaxExtension(Id)(Have)

