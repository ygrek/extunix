
#define WANT_UNAME
#include "config.h"

#if defined(HAVE_UNAME)

#include <string.h>

CAMLprim value caml_extunix_uname(value u)
{
  struct utsname uname_data;

  CAMLparam1(u);
  CAMLlocal2(result, domainname);
 
  memset(&uname_data, 0, sizeof(uname_data));

  if (uname(&uname_data) == 0)
  {
    result = caml_alloc(5, 0);
    Store_field(result, 0, caml_copy_string(&(uname_data.sysname[0])));
    Store_field(result, 1, caml_copy_string(&(uname_data.nodename[0])));
    Store_field(result, 2, caml_copy_string(&(uname_data.release[0])));
    Store_field(result, 3, caml_copy_string(&(uname_data.version[0])));
    Store_field(result, 4, caml_copy_string(&(uname_data.machine[0])));
  }
  else
  {
    uerror("uname",Nothing);
  }

  CAMLreturn(result);
}

#endif

