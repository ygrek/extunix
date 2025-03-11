
#define EXTUNIX_WANT_EVENTFD
#include "config.h"

#if defined(EXTUNIX_HAVE_EVENTFD)

CAMLprim value caml_extunix_eventfd(value v_init)
{
  CAMLparam1(v_init);
  int fd = eventfd(Int_val(v_init), 0);
  if (-1 == fd) caml_uerror("eventfd",Nothing);
  CAMLreturn(Val_int(fd));
}

CAMLprim value caml_extunix_eventfd_read(value v_fd)
{
  CAMLparam1(v_fd);
  eventfd_t v;
  if (-1 == eventfd_read(Int_val(v_fd), &v))
    caml_uerror("eventfd_read",Nothing);
  CAMLreturn(caml_copy_int64(v));
}

CAMLprim value caml_extunix_eventfd_write(value v_fd, value v_val)
{
  CAMLparam2(v_fd, v_val);
  if (-1 == eventfd_write(Int_val(v_fd), Int64_val(v_val)))
    caml_uerror("eventfd_write",Nothing);
  CAMLreturn(Val_unit);
}

#endif

