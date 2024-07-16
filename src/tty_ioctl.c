/*
 * Copyright : (c) 2010, Stéphane Glondu <steph@glondu.net>
 */

#define EXTUNIX_WANT_TTY_IOCTL
#include "config.h"

#if defined(EXTUNIX_HAVE_TTY_IOCTL)

/* FIXME implement separate interface for tcsetattr/tcgetattr */
CAMLprim value caml_extunix_crtscts(value mlfd)
{
  CAMLparam1(mlfd);
  struct termios t;
  int r, fd = Int_val(mlfd);

  r = tcgetattr(fd, &t);
  if (0 == r) {
    t.c_cflag |= CRTSCTS;
    r = tcsetattr(fd, TCSANOW, &t);
  }
  if (0 != r) uerror("crtscts",Nothing);
  CAMLreturn(Val_unit);
}

#define TTY_IOCTL_INT(cmd) \
CAMLprim value caml_extunix_ioctl_##cmd(value v_fd, value v_arg) \
{ \
  CAMLparam2(v_fd, v_arg); \
  int arg = Int_val(v_arg); \
  int r = ioctl(Int_val(v_fd), cmd, &arg); \
  if (r < 0) uerror("ioctl",caml_copy_string(#cmd)); \
  CAMLreturn(Val_unit); \
}

CAMLprim value caml_extunix_ioctl_TIOCGWINSZ(value v_fd)
{
    CAMLparam1(v_fd);
    CAMLlocal1(result);

    struct winsize ws;

    int r = ioctl(Int_val(v_fd), TIOCGWINSZ, &ws);
    if (r < 0) {
        uerror("ioctl", caml_copy_string("TIOCGWINSZ"));
    }

    result = caml_alloc_tuple(4);
    Store_field(result, 0, Val_int(ws.ws_col));
    Store_field(result, 1, Val_int(ws.ws_row));
    Store_field(result, 2, Val_int(ws.ws_xpixel));
    Store_field(result, 3, Val_int(ws.ws_ypixel));

    CAMLreturn(result);
}

CAMLprim value caml_extunix_ioctl_TIOCMGET(value v_fd)
{
  CAMLparam1(v_fd);
  int arg = 0;
  int r = ioctl(Int_val(v_fd), TIOCMGET, &arg);
  if (r < 0) uerror("ioctl",caml_copy_string("TIOCMGET"));
  CAMLreturn(Val_int(arg));
}

TTY_IOCTL_INT(TIOCMSET)
TTY_IOCTL_INT(TIOCMBIC)
TTY_IOCTL_INT(TIOCMBIS)

#endif
