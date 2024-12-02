#define EXTUNIX_WANT_RENAMEAT2
#include "config.h"

#if defined(EXTUNIX_HAVE_RENAMEAT2)

#ifndef RENAME_WHITEOUT
#define RENAME_WHITEOUT 0
#endif

static const int rename_flags_table[] = {
  RENAME_NOREPLACE, RENAME_EXCHANGE, RENAME_WHITEOUT,
};

CAMLprim value caml_extunix_renameat2(value v_oldfd, value v_oldname, value v_newfd, value v_newname, value v_flags)
{
  CAMLparam5(v_oldfd, v_oldname, v_newfd, v_newname, v_flags);
  int oldfd = Int_val(v_oldfd), newfd = Int_val(v_newfd);
  const char *oldname = caml_stat_strdup(String_val(v_oldname)),
             *newname = caml_stat_strdup(String_val(v_newname));
  int flags = caml_convert_flag_list(v_flags, rename_flags_table);
  caml_enter_blocking_section();
  int ret = renameat2(oldfd, oldname, newfd, newname, flags);
  caml_leave_blocking_section();
  caml_stat_free(oldname);
  caml_stat_free(newname);
  if (ret != 0) uerror("renameat2", v_oldname);
  CAMLreturn(Val_unit);
}
#endif
