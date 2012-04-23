#define EXTUNIX_WANT_READ_CREDENTIALS

#include "config.h"

#if defined(EXTUNIX_HAVE_READ_CREDENTIALS)

/*  Copyright © 2012 Andre Nathan <andre@digirati.com.br>   */

CAMLprim value caml_extunix_read_credentials(value fd_val)
{
  CAMLparam1(fd_val);
  CAMLlocal1(res);
  struct ucred crd;
  socklen_t crdlen = sizeof crd;
  int fd = Int_val(fd_val);

  if (getsockopt(fd, SOL_SOCKET, SO_PEERCRED, &crd, &crdlen) == -1)
    uerror("read_credentials", Nothing);

  res = caml_alloc_tuple(3);
  Store_field(res, 0, Val_int(crd.pid));
  Store_field(res, 1, Val_int(crd.uid));
  Store_field(res, 2, Val_int(crd.gid));
  CAMLreturn (res);
}
#endif /* EXTUNIX_HAVE_READ_CREDENTIALS */
