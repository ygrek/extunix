#define EXTUNIX_WANT_FSYNC
#define EXTUNIX_WANT_FDATASYNC
#define EXTUNIX_WANT_SYNC
#define EXTUNIX_WANT_SYNCFS
#include "config.h"

#if defined(_WIN32)

#if defined(EXTUNIX_HAVE_FSYNC)
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

#if defined(EXTUNIX_HAVE_FDATASYNC)
CAMLprim value caml_extunix_fdatasync(value v)
{
  return caml_extunix_fsync(v);
}
#endif

#endif /* EXTUNIX_HAVE_FSYNC */

#else /* _WIN32 */

#if defined(EXTUNIX_HAVE_FSYNC)
CAMLprim value caml_extunix_fsync(value v_fd)
{
    CAMLparam1(v_fd);
    int fd = Int_val(v_fd);
    int r = 0;
    caml_enter_blocking_section();
    r = fsync(fd);
    caml_leave_blocking_section();
    if (0 != r)
      uerror("fsync",Nothing);
    CAMLreturn(Val_unit);
}
#endif

#if defined(EXTUNIX_HAVE_FDATASYNC)
CAMLprim value caml_extunix_fdatasync(value v_fd)
{
    CAMLparam1(v_fd);
    int fd = Int_val(v_fd);
    int r = 0;
    caml_enter_blocking_section();
    r = fdatasync(fd);
    caml_leave_blocking_section();
    if (0 != r)
      uerror("fdatasync",Nothing);
    CAMLreturn(Val_unit);
}
#endif

#if defined(EXTUNIX_HAVE_SYNC)
CAMLprim value caml_extunix_sync(value v_unit)
{
    (void)v_unit;
    caml_enter_blocking_section();
    sync();
    caml_leave_blocking_section();
    return Val_unit;
}
#endif

#if defined(EXTUNIX_HAVE_SYNCFS)
CAMLprim value caml_extunix_syncfs(value v_fd)
{
    CAMLparam1(v_fd);
    int fd = Int_val(v_fd);
    int r = 0;
    caml_enter_blocking_section();
#if defined(EXTUNIX_USE_SYS_SYNCFS)
    r = syscall(SYS_syncfs, fd);
#else
    r = syncfs(fd);
#endif
    caml_leave_blocking_section();
    if (0 != r)
      uerror("syncfs",Nothing);
    CAMLreturn(Val_unit);
}
#endif

#endif /* !_WIN32 */
