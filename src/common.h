#define UNUSED(x) (void)(x)

#include <caml/version.h>
#if OCAML_VERSION < 41200
#define Val_none Val_int(0)
#define Some_val(v) Field(v,0)
#endif

int extunix_open_flags(value);
