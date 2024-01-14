#define EXTUNIX_WANT_RENAMEAT2
#include "config.h"

#if defined(EXTUNIX_HAVE_RENAMEAT2)

#ifndef RENAME_WHITEOUT
#define RENAME_WHITEOUT 0
#endif

static const int rename_flags_table[] = {
  RENAME_NOREPLACE, /* 0 */
  RENAME_EXCHANGE, /* 1 */
  RENAME_WHITEOUT, /* 2 */
};

#define RENAME_WHITEOUT_INDEX 2

static void check_flag_list(value list)
{
  for (/*nothing*/; list != Val_emptylist; list = Field(list, 1))
  {
#if !defined(EXTUNIX_HAVE_RENAME_WHITEOUT)
    if (RENAME_WHITEOUT_INDEX == Int_val(Field(list, 0)))
      caml_raise_with_string(*caml_named_value("ExtUnix.Not_available"), "renameat2 RENAME_WHITEOUT");
#endif
  }
}

CAMLprim value caml_extunix_renameat2(value v_oldfd, value v_oldname, value v_newfd, value v_newname, value v_flags)
{
  CAMLparam5(v_oldfd, v_oldname, v_newfd, v_newname, v_flags);
  check_flag_list(v_flags);
  int flags = caml_convert_flag_list(v_flags, rename_flags_table);
  caml_enter_blocking_section();
  int ret = renameat2(Int_val(v_oldfd), String_val(v_oldname), Int_val(v_newfd), String_val(v_newname), flags);
  caml_leave_blocking_section();
  if (ret != 0) uerror("renameat2", v_oldname);
  CAMLreturn(Val_unit);
}
#endif
