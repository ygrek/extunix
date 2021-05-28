#define EXTUNIX_WANT_SETENV
#define EXTUNIX_WANT_CLEARENV
#define EXTUNIX_WANT_MKDTEMP
#include "config.h"

#if defined(EXTUNIX_HAVE_SETENV)

CAMLprim value caml_extunix_setenv(value v_name, value v_val, value v_overwrite)
{
  CAMLparam3(v_name, v_val, v_overwrite);

  if (0 != setenv(String_val(v_name), String_val(v_val), Bool_val(v_overwrite)))
  {
    uerror("setenv",v_name);
  }

  CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_unsetenv(value v_name)
{
  CAMLparam1(v_name);

  if (0 != unsetenv(String_val(v_name)))
  {
    uerror("unsetenv",v_name);
  }

  CAMLreturn(Val_unit);
}

#endif

#if defined(EXTUNIX_HAVE_CLEARENV)

CAMLprim value caml_extunix_clearenv(value v_unit)
{
  UNUSED(v_unit);
  if (0 != clearenv())
  {
    uerror("clearenv", Nothing);
  }

  return Val_unit;
}

#endif
