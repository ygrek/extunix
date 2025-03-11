
#define EXTUNIX_WANT_UNSHARE
#include "config.h"

#if defined(EXTUNIX_HAVE_UNSHARE)

static const int umountflags_table[] = {
  CLONE_FS,  CLONE_FILES, CLONE_NEWNS, CLONE_SYSVSEM, CLONE_NEWUTS,
  CLONE_NEWIPC, CLONE_NEWUSER, CLONE_NEWPID, CLONE_NEWNET
};

CAMLprim value caml_extunix_unshare(value v_cloneflags)
{
  CAMLparam1(v_cloneflags);
  int ret;

  int p_cloneflags = caml_convert_flag_list(v_cloneflags, umountflags_table);

  caml_enter_blocking_section();
  ret = unshare(p_cloneflags);
  caml_leave_blocking_section();

  if (ret != 0) caml_uerror("unshare", Nothing);
  CAMLreturn(Val_unit);
}

#endif

