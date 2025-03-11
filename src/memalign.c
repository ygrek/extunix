
#define EXTUNIX_WANT_MEMALIGN
#include "config.h"

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
    caml_unix_error(errcode, "memalign", Nothing);
  };

  CAMLreturn(caml_ba_alloc_dims(CAML_BA_UINT8 | CAML_BA_C_LAYOUT | CAML_BA_MANAGED, 1, memptr, size));
}

#endif
