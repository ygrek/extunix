#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/callback.h>

CAMLprim value caml_uname (value u)
{
  CAMLparam1(u);
  CAMLlocal1(result);
 
  caml_raise_constant(*caml_named_value("caml_uname_no_os_support"));

  CAMLreturn(result);
}
