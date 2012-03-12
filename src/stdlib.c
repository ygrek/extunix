
#define EXTUNIX_WANT_REALPATH
#define EXTUNIX_WANT_SETENV
#define EXTUNIX_WANT_CLEARENV
#define EXTUNIX_WANT_MKDTEMP
#define EXTUNIX_WANT_MEMALIGN
#include "config.h"

#include <string.h>

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

#if defined(EXTUNIX_HAVE_SETENV)

CAMLprim value caml_extunix_setenv(value v_name, value v_val, value v_overwrite) 
{
  CAMLparam3(v_name, v_val, v_overwrite);

  if (0 != setenv(String_val(v_name), String_val(v_val), Bool_val(v_overwrite)))
  {
    uerror("setenv",v_name);
  }

  CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_unsetenv(value v_name) 
{
  CAMLparam1(v_name);

  if (0 != unsetenv(String_val(v_name)))
  {
    uerror("unsetenv",v_name);
  }

  CAMLreturn(Val_unit);
}

#endif

#if defined(EXTUNIX_HAVE_CLEARENV)

CAMLprim value caml_extunix_clearenv(value v_unit) 
{
  if (0 != clearenv())
  {
    uerror("clearenv", Nothing);
  }

  return Val_unit;
}

#endif

#if defined(EXTUNIX_HAVE_MKDTEMP)

CAMLprim value caml_extunix_mkdtemp(value v_path)
{
  CAMLparam1(v_path);
  char* path = strdup(String_val(v_path));
  char *ret;
  caml_enter_blocking_section();
  ret = mkdtemp(path);
  caml_leave_blocking_section();
  if (NULL == ret)
  {
    free(path);
    uerror("mkdtemp", v_path);
  }
  v_path = caml_copy_string(ret);
  free(path);
  CAMLreturn(v_path);
}

#endif

#if defined(EXTUNIX_HAVE_MEMALIGN)

/*
 * Binding to posix_memalign
 *
 * Copyright 2012 Goswin von Brederlow <goswin-v-b@web.de>
 *
 * License LGPL-2.1 with OCaml linking static exception
 *
 * For more information go to: www.talend.com
 *
 * author: Goswin von Brederlow <goswin-v-b@web.de>
 *
 */

#include <caml/bigarray.h>

CAMLprim value caml_extunix_memalign(value valignment, value vsize)
{
  CAMLparam2(valignment, vsize);

  size_t alignment;
  size_t size;
  int    errcode;
  void  *memptr;

  alignment = Int_val(valignment);
  size = Int_val(vsize);

  errcode = posix_memalign(&memptr, alignment, size);

  if (errcode != 0)
  {
    unix_error(errcode, "memalign", Nothing);
  };

  CAMLreturn(caml_ba_alloc_dims(CAML_BA_UINT8 | CAML_BA_C_LAYOUT | CAML_BA_MANAGED, 1, memptr, size));
}

#endif
