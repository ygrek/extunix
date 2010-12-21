
#define EXTUNIX_WANT_TTYNAME
#define EXTUNIX_WANT_CTERMID
#define EXTUNIX_WANT_PGID
#define EXTUNIX_WANT_SETREUID
#define EXTUNIX_WANT_FCNTL
#define EXTUNIX_WANT_TCPGRP
#include "config.h"

#if defined(EXTUNIX_HAVE_TTYNAME)

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

#if defined(EXTUNIX_HAVE_CTERMID)

CAMLprim value caml_extunix_ctermid(value v_unit) 
{
  char buf[L_ctermid + 1];
  return caml_copy_string(ctermid(buf));
}

#endif

#if defined(EXTUNIX_HAVE_PGID)

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

CAMLprim value caml_extunix_getsid(value v_pid)
{
  CAMLparam1(v_pid);
  int sid = getsid(Int_val(v_pid));
  if (sid < 0)
    uerror("getsid",Nothing);
  CAMLreturn(Val_int(sid));
}

#endif

#if defined(EXTUNIX_HAVE_SETREUID)

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

#if defined(EXTUNIX_HAVE_FCNTL)

#include <errno.h>

CAMLprim value caml_extunix_is_open_descr(value v_fd)
{
    int r = fcntl(Int_val(v_fd), F_GETFL);
    if (-1 == r)
    {
        if (EBADF == errno) return Val_false;
        uerror("fcntl", Nothing);
    };
    return Val_true;
}

#endif

#if defined(EXTUNIX_HAVE_TCPGRP)

CAMLprim value caml_extunix_tcgetpgrp(value v_fd)
{
    int pgid = tcgetpgrp(Int_val(v_fd));
    if (-1 == pgid)
      uerror("tcgetpgrp", Nothing);
    return Val_int(pgid);
}

CAMLprim value caml_extunix_tcsetpgrp(value v_fd, value v_pgid)
{
    int r = tcsetpgrp(Int_val(v_fd), Int_val(v_pgid));
    if (-1 == r)
      uerror("tcsetpgrp", Nothing);
    return Val_int(r);
}

#endif

