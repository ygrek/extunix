
#define EXTUNIX_WANT_PTRACE
#include "config.h"

#if defined(EXTUNIX_HAVE_PTRACE)

CAMLprim value caml_extunix_ptrace_traceme(value v_unit)
{
  long r = ptrace(PTRACE_TRACEME, 0, 0, 0);
  UNUSED(v_unit);
  if (r != 0)
    caml_uerror("ptrace_traceme", Nothing);
  return Val_unit;
}

CAMLprim value caml_extunix_ptrace(value v_pid, value v_req)
{
  CAMLparam2(v_pid, v_req);
  long r = 0;
  switch (Int_val(v_req))
  {
    case 0 : r = ptrace(PTRACE_ATTACH, Int_val(v_pid), 0, 0); break;
    case 1 : r = ptrace(PTRACE_DETACH, Int_val(v_pid), 0, 0); break;
    default : caml_invalid_argument("ptrace");
  }
  if (r != 0)
    caml_uerror("ptrace", Nothing);
  CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_ptrace_peekdata(value v_pid, value v_addr)
{
  CAMLparam2(v_pid, v_addr);
  long r = ptrace(PTRACE_PEEKDATA,Int_val(v_pid), Nativeint_val(v_addr), 0);
  if (-1 == r && 0 != errno)
      caml_uerror("ptrace_peekdata",Nothing);
  CAMLreturn(caml_copy_nativeint(r));
}

CAMLprim value caml_extunix_ptrace_peektext(value v_pid, value v_addr)
{
  CAMLparam2(v_pid, v_addr);
  long r = ptrace(PTRACE_PEEKTEXT,Int_val(v_pid), Nativeint_val(v_addr), 0);
  if (-1 == r && 0 != errno)
      caml_uerror("ptrace_peektext",Nothing);
  CAMLreturn(caml_copy_nativeint(r));
}

#endif

