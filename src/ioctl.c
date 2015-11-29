#define EXTUNIX_WANT_IOCTL
#include "config.h"

#if defined(EXTUNIX_HAVE_IOCTL)

CAMLprim value caml_extunix_ioctl(value v_fd, value v_cmd)
{
  CAMLparam2(v_fd, v_cmd);
  CAMLlocal1(v_rc);
  int fd = Int_val(v_fd);
  unsigned long cmd = Int64_val(v_cmd);

  int rc = ioctl(fd, cmd, NULL);
  if (rc == -1) uerror("ioctl", Nothing);

  v_rc = caml_copy_int32(rc);
  CAMLreturn(v_rc);
}

#endif
