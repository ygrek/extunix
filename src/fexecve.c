#define EXTUNIX_WANT_FEXECVE

#include "config.h"

#if defined(EXTUNIX_HAVE_FEXECVE)

/*  Copyright © 2012 Andre Nathan <andre@digirati.com.br>   */

static char **
array_of_value(value v)
{
  CAMLparam1(v);
  char **arr;
  mlsize_t size, i;

  size = Wosize_val(v);
  arr = caml_stat_alloc((size + 1) * sizeof(char *));
  for (i = 0; i < size; i++)
    arr[i] = (char *)String_val(Field(v, i));
  arr[size] = NULL;

  CAMLreturnT (char **, arr);
}

CAMLprim value caml_extunix_fexecve(value fd_val, value argv_val, value envp_val)
{
  CAMLparam3(fd_val, argv_val, envp_val);
  char **argv;
  char **envp;

  argv = array_of_value(argv_val);
  envp = array_of_value(envp_val);

  fexecve(Int_val(fd_val), argv, envp);

  caml_stat_free(argv);
  caml_stat_free(envp);
  caml_uerror("fexecve", Nothing);

  CAMLreturn (Val_unit); /* not reached */
}

#endif /* EXTUNIX_HAVE_FEXECVE */
