#define EXTUNIX_WANT_IOCTL
#include "config.h"

#if defined(EXTUNIX_HAVE_IOCTL)

CAMLprim value caml_extunix_ioctl(value v_fd, value v_cmd)
{
  CAMLparam2(v_fd, v_cmd);
  int fd = Int_val(v_fd);
  int cmd = Int_val(v_cmd);

  int rc = ioctl(fd, cmd);
  if (rc < 0) uerror("ioctl", Nothing);

  CAMLreturn(Val_int(rc));
}

#endif
