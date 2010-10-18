
#define WANT_FSYNC
#include "config.h"

#if defined(WINDOWS)

CAMLprim value caml_extunix_fsync(value v)
{
   CAMLparam1(v);
   HANDLE h = INVALID_HANDLE_VALUE;
   int r = 0;
   if (KIND_HANDLE != Descr_kind_val(v))
     caml_invalid_argument("fsync");
   h = Handle_val(v);
   caml_enter_blocking_section();
   r = FlushFileBuffers(h);
   caml_leave_blocking_section();
   if (0 == r)
     uerror("fsync",Nothing);
   CAMLreturn(Val_unit); 
}

CAMLprim value caml_extunix_fdatasync(value v)
{
  return caml_extunix_fsync(v);
}

#else

#if defined(HAVE_FSYNC)

CAMLprim value caml_extunix_fsync(value v_fd)
{
    CAMLparam1(v_fd);
    int r = 0;
    caml_enter_blocking_section();
    r = fsync(Int_val(v_fd));
    caml_leave_blocking_section();
    if (0 != r)
      uerror("fsync",Nothing);
    CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_fdatasync(value v_fd)
{
    CAMLparam1(v_fd);
    int r = 0;
    caml_enter_blocking_section();
    r = fdatasync(Int_val(v_fd));
    caml_leave_blocking_section();
    if (0 != r)
      uerror("fdatasync",Nothing);
    CAMLreturn(Val_unit);
}

#endif /* HAVE_FSYNC */
#endif /* WINDOWS */

