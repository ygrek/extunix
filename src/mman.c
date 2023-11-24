#define EXTUNIX_WANT_MLOCKALL
#include "config.h"

#if defined(EXTUNIX_HAVE_MLOCKALL)

static const int mlockall_flags_table[] = { MCL_CURRENT, MCL_FUTURE };

CAMLprim value caml_extunix_mlockall(value v_flags)
{
  CAMLparam1(v_flags);
  int flags = caml_convert_flag_list(v_flags, mlockall_flags_table);
  int ret = 0;

  caml_enter_blocking_section();
  ret = mlockall(flags);
  caml_leave_blocking_section();

  if (ret != 0) uerror("mlockall", Nothing);

  CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_munlockall(value v_unit)
{
  CAMLparam1(v_unit);
  int ret = 0;

  caml_enter_blocking_section();
  ret = munlockall();
  caml_leave_blocking_section();

  if (ret != 0) uerror("munlockall", Nothing);

  CAMLreturn(Val_unit);
}

#endif

