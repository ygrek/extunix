(**
  New toplevel statement (structure item): HAVE <uident> <structure_items> END
  If HAVE_<uident> is defined then enclosed structure items are left as is,
  otherwise:
    if ONLY_VALID is defined they are dropped altogether,
    if ONLY_VALID is not defined then external structure items are rewritten to raise Invalid_argument when called
*)

module Have(Syntax : Camlp4.Sig.Camlp4Syntax) =
struct
  open Camlp4.PreCast

  include Syntax

  module PP = Camlp4.Printers.OCaml.Make(Syntax)
  let pp = new PP.printer ()
  let print_str_items l =
    let b = Buffer.create 10 in 
    let f = Format.formatter_of_buffer b in
    List.iter (pp#str_item f) l;
    Format.pp_print_flush f ();
    Buffer.contents b

  let rec make_dummy_f body = function
  | <:ctyp@loc< $t$ -> $tl$ >> -> <:expr@loc< fun (_:$t$) -> $make_dummy_f body tl$ >>
  | <:ctyp< $t$ >> -> let loc = Loc.ghost in <:expr@loc< ($body$ : $t$) >>

  let invalid_external = function
  | <:str_item@_loc< external $i$ : $t$ = $sl$ >> -> 
      <:str_item< let $lid:i$ = $make_dummy_f <:expr< invalid_arg ($str:i$^" not available") >> t$ >>
  | e -> e

  let invalid_external e =
    (* extra StSem wrap to match with <:str_item< >> *)
    (Ast.map_str_item invalid_external)#str_item (Ast.StSem (Loc.ghost,e,(Ast.StNil Loc.ghost)))

  EXTEND Gram
    GLOBAL: implem;
    implem:
      [ [ "HAVE"; name=UIDENT; s1=str_items; (tail,x)=SELF ->
        let si = Gram.parse_string str_item Loc.ghost
          ("IFDEF HAVE_"^name^" THEN "^print_str_items s1^" ELSE " ^
           "IFNDEF ONLY_VALID THEN " ^ print_str_items (List.map invalid_external s1)^" ENDIF ENDIF")
        in
        si :: tail, x 
      ] ]
    ;
    str_items:
      [ [ si=str_item; semi; sil=SELF -> si::sil
        | "END" -> []
      ] ]
    ;
  END

end

module Id = struct
let version = "0"
let name = "Have"
end

module M = Camlp4.Register.OCamlSyntaxExtension(Id)(Have)

