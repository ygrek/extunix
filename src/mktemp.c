#define EXTUNIX_WANT_MKDTEMP
#define EXTUNIX_WANT_MKSTEMPS
#define EXTUNIX_WANT_MKOSTEMPS

#include "config.h"

#if defined(EXTUNIX_HAVE_MKDTEMP)

CAMLprim value caml_extunix_mkdtemp(value v_path)
{
  CAMLparam1(v_path);
  char* path = strdup(String_val(v_path));
  char *ret;
  caml_enter_blocking_section();
  ret = mkdtemp(path);
  caml_leave_blocking_section();
  if (NULL == ret)
  {
    free(path);
    uerror("mkdtemp", v_path);
  }
  v_path = caml_copy_string(ret);
  free(path);
  CAMLreturn(v_path);
}

#endif

#if defined(EXTUNIX_HAVE_MKSTEMPS)

CAMLprim value caml_extunix_internal_mkstemps(value v_template, value v_suffixlen)
{
  CAMLparam2(v_template, v_suffixlen);
  char *template = String_val(v_template);
  int suffixlen = Int_val(v_suffixlen);
  int ret;

  ret = mkstemps(template, suffixlen);
  if (ret == -1)
  {
    uerror("mkstemps", v_template);
  }
  CAMLreturn(Val_int(ret));
}

#endif

#if defined(EXTUNIX_HAVE_MKOSTEMPS)

/* FIXME: also in atfile.c, move to common file */
#include <fcntl.h>

#ifndef O_CLOEXEC
# define O_CLOEXEC 0
#endif

CAMLprim value caml_extunix_internal_mkostemps(value v_template, value v_suffixlen, value v_flags)
{
  CAMLparam3(v_template, v_suffixlen, v_flags);
  char *template = String_val(v_template);
  int flags = extunix_open_flags(v_flags) | O_CLOEXEC;
  int suffixlen = Int_val(v_suffixlen);
  int ret;

  ret = mkostemps(template, suffixlen, flags);
  if (ret == -1)
  {
    uerror("mkostemps", v_template);
  }
  CAMLreturn(Val_int(ret));
}

#endif
