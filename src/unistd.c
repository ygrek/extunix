
#define WANT_TTYNAME
#define WANT_PGID
#define WANT_SETREUID
#include "config.h"

#if defined(HAVE_TTYNAME)

/*  Copyright © 2010 Stéphane Glondu <steph@glondu.net>                   */

CAMLprim value caml_extunix_ttyname(value v_fd) 
{
  CAMLparam1(v_fd);
  char *r = ttyname(Int_val(v_fd));
  if (r) {
    CAMLreturn(caml_copy_string(r));
  } else {
    uerror("ttyname", Nothing);
  }
}

#endif

#if defined(HAVE_PGID)

CAMLprim value caml_extunix_setpgid(value v_pid, value v_pgid)
{
  CAMLparam2(v_pid, v_pgid);
  if (0 != setpgid(Int_val(v_pid), Int_val(v_pgid)))
    uerror("setpgid",Nothing);
  CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_getpgid(value v_pid)
{
  CAMLparam1(v_pid);
  int pgid = getpgid(Int_val(v_pid));
  if (pgid < 0)
    uerror("getpgid",Nothing);
  CAMLreturn(Val_int(pgid));
}

#endif

#if defined(HAVE_SETREUID)

CAMLprim value caml_extunix_setreuid(value v_ruid, value v_euid)
{
  CAMLparam2(v_ruid,v_euid);
  int r = setreuid(Int_val(v_ruid), Int_val(v_euid));
  if (r < 0)
    uerror("setreuid", Nothing);
  CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_setregid(value v_rgid, value v_egid)
{
  CAMLparam2(v_rgid,v_egid);
  int r = setregid(Int_val(v_rgid), Int_val(v_egid));
  if (r < 0)
    uerror("setregid", Nothing);
  CAMLreturn(Val_unit);
}

#endif

