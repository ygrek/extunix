
#define EXTUNIX_WANT_REALPATH
#include "config.h"

#if defined(EXTUNIX_HAVE_REALPATH)

#ifdef __GLIBC__

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

#else

/* janest-core-0.6.0/lib/unix_ext_stubs.c */

/* Seems like a sane approach to getting a reasonable bound for the
   maximum path length */
#ifdef PATH_MAX
#define JANE_PATH_MAX ((PATH_MAX <= 0 || PATH_MAX > 65536) ? 65536 : PATH_MAX)
#else
#define JANE_PATH_MAX (65536)
#endif

CAMLprim value caml_extunix_realpath(value v_path)
{
  char *path = String_val(v_path);
  /* [realpath] is inherently broken without GNU-extension, and this
     seems like a reasonable thing to do if we do not build against
     GLIBC. */
  char resolved_path[JANE_PATH_MAX];
  if (realpath(path, resolved_path) == NULL) uerror("realpath", v_path);
  return caml_copy_string(resolved_path);
}

#endif /* __GLIBC__ */

#endif

