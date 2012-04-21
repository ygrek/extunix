#define EXTUNIX_WANT_SETRESUID

#include "config.h"

#if defined(EXTUNIX_HAVE_SETRESUID)

#include <errno.h>

CAMLprim value caml_extunix_setresuid(value r, value e, value s)
{
  CAMLparam3(r, e, s);
  uid_t ruid = Int_val(r);
  uid_t euid = Int_val(e);
  uid_t suid = Int_val(s);

  if (setresuid(ruid, euid, suid) != 0)
    unix_error(errno, "setresuid", Nothing);
  CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_setresgid(value r, value e, value s)
{
  CAMLparam3(r, e, s);
  gid_t rgid = Int_val(r);
  gid_t egid = Int_val(e);
  gid_t sgid = Int_val(s);

  if (setresgid(rgid, egid, sgid) == -1)
    unix_error(errno, "setresgid", Nothing);
  CAMLreturn(Val_unit);
}

#endif /* EXTUNIX_HAVE_SETRESUID */
