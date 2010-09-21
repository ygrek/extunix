/*
 * Binding to posix_fadvise
 *
 * author: Sylvain Le Gall
 *
 */

#define WANT_FADVISE
#include "config.h"

#if defined(HAVE_FADVISE)

static int caml_advises[] =
  {
    POSIX_FADV_NORMAL,
    POSIX_FADV_SEQUENTIAL,
    POSIX_FADV_RANDOM,
    POSIX_FADV_NOREUSE,
    POSIX_FADV_WILLNEED,
    POSIX_FADV_DONTNEED
  };

CAMLprim value caml_extunix_fadvise64(value vfd, value voff, value vlen, value vadvise)
{
  int     errcode = 0;
  int     fd = -1;
  off64_t off = 0;
  off64_t len = 0;
  int     advise = 0;

  CAMLparam4(vfd, voff, vlen, vadvise);

  fd  = Int_val(vfd);
  off = Int64_val(voff);
  len = Int64_val(vlen);
  advise = caml_advises[Int_val(vadvise)]; 

  errcode = posix_fadvise64(fd, off, len, advise);

  if (errcode != 0)
  {
    unix_error(errcode, "fadvise64", Nothing);
  };

  CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_fadvise(value vfd, value voff, value vlen, value vadvise)
{
  int   errcode = 0;
  int   fd = -1;
  off_t off = 0;
  off_t len = 0;
  int   advise = 0;

  CAMLparam4(vfd, voff, vlen, vadvise);

  fd  = Int_val(vfd);
  off = Long_val(voff);
  len = Long_val(vlen);
  advise = caml_advises[Int_val(vadvise)]; 

  errcode = posix_fadvise(fd, off, len, advise);

  if (errcode != 0)
  {
    unix_error(errcode, "fadvise", Nothing);
  };

  CAMLreturn(Val_unit);
}

#endif

