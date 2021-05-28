
#define EXTUNIX_WANT_EXECINFO
#include "config.h"

#if defined(EXTUNIX_HAVE_EXECINFO)

CAMLprim value caml_extunix_backtrace(value unit)
{
  CAMLparam1(unit);
  CAMLlocal1(v_ret);

  void *buffer[100];
  int nptrs = backtrace(buffer, 100);
  int j;
  char **strings = backtrace_symbols(buffer, nptrs);
  if (NULL == strings)
    uerror("backtrace", Nothing);

  v_ret = caml_alloc_tuple(nptrs);
  for (j = 0; j < nptrs; j++)
    Store_field(v_ret,j,caml_copy_string(strings[j]));

  free(strings);
  CAMLreturn(v_ret);
}

#endif

