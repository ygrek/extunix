
#define WANT_TTYNAME
#include "config.h"

#if defined(HAVE_TTYNAME)

/*  Copyright © 2010 Stéphane Glondu <steph@glondu.net>                   */

CAMLprim value caml_extunix_ttyname(value v_fd) 
{
  CAMLparam1(v_fd);
  char *r = ttyname(Int_val(v_fd));
  if (r) {
    CAMLreturn(caml_copy_string(r));
  } else {
    uerror("ttyname", Nothing);
  }
}

#endif

