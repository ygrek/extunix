
#define EXTUNIX_WANT_REALPATH
#include "config.h"

#if defined(EXTUNIX_HAVE_REALPATH)

CAMLprim value caml_extunix_realpath(value v_path) 
{
  CAMLparam1(v_path);
  CAMLlocal1(v_s);

  char* path = realpath(String_val(v_path),NULL);
  if (NULL == path)
	{
    uerror("realpath",v_path);
	}

  v_s = caml_copy_string(path);
  free(path);

  CAMLreturn(v_s);
}

#endif

