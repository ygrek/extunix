#define EXTUNIX_WANT_POLL
#include "config.h"

#if defined(EXTUNIX_HAVE_POLL)

CAMLprim value caml_extunix_poll_constants(value v_unit)
{
  value v = caml_alloc_tuple(7);
  UNUSED(v_unit);

  Field(v,0) = Val_int(POLLIN);
  Field(v,1) = Val_int(POLLPRI);
  Field(v,2) = Val_int(POLLOUT);
  Field(v,3) = Val_int(POLLERR);
  Field(v,4) = Val_int(POLLHUP);
  Field(v,5) = Val_int(POLLNVAL);
  Field(v,6) = Val_int(POLLRDHUP);

  return v;
}

CAMLprim value caml_extunix_poll(value v_fds, value v_n, value v_ms)
{
  CAMLparam3(v_fds, v_n, v_ms);
  CAMLlocal3(v_l,v_tuple,v_cons);
  struct pollfd* fd = NULL;
  size_t n = Int_val(v_n);
  size_t i = 0;
  int result;
  int timeout = Double_val(v_ms) * 1000.f;

  if (Wosize_val(v_fds) < n)
    caml_invalid_argument("poll");

  if (0 == n)
    CAMLreturn(Val_emptylist);

  fd = caml_stat_alloc(n * sizeof(struct pollfd));

  for (i = 0; i < n; i++)
  {
    fd[i].fd = Int_val(Field(Field(v_fds,i),0));
    fd[i].events = Int_val(Field(Field(v_fds,i),1));
    fd[i].revents = 0;
  }

  caml_enter_blocking_section();
  result = poll(fd, n, timeout);
  caml_leave_blocking_section();

  if (result < 0)
  {
    caml_stat_free(fd);
    caml_uerror("poll",Nothing);
  }

  v_l = Val_emptylist;
  for (i = 0; i < n; i++)
  {
    if (fd[i].revents != 0)
    {
      v_tuple = caml_alloc_tuple(2);
      Store_field(v_tuple,0,Val_int(fd[i].fd));
      Store_field(v_tuple,1,Val_int(fd[i].revents));
      v_cons = caml_alloc_tuple(2);
      Store_field(v_cons,0,v_tuple);
      Store_field(v_cons,1,v_l);
      v_l = v_cons;
    }
  }

  caml_stat_free(fd);

  CAMLreturn(v_l);
}

#endif
