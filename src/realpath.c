/**************************************************************************/
/*                                                                        */
/*                                 OCaml                                  */
/*                                                                        */
/*                         The OCaml programmers                          */
/*                                                                        */
/*   Copyright 2020 Institut National de Recherche en Informatique et     */
/*     en Automatique.                                                    */
/*                                                                        */
/*   All rights reserved.  This file is distributed under the terms of    */
/*   the GNU Lesser General Public License version 2.1, with the          */
/*   special exception on linking described in the file LICENSE.          */
/*                                                                        */
/**************************************************************************/

#define EXTUNIX_WANT_REALPATH
#include "config.h"

#if defined(EXTUNIX_HAVE_REALPATH)

#if !defined(_WIN32)

CAMLprim value caml_extunix_realpath (value p)
{
  CAMLparam1 (p);
  char *r;
  value rp;

  // caml_unix_check_path (p, "realpath");
  r = realpath (String_val (p), NULL);
  if (r == NULL) { caml_uerror ("realpath", p); }
  rp = caml_copy_string (r);
  free (r);
  CAMLreturn (rp);
}

#else

#include <caml/osdeps.h>

CAMLprim value caml_extunix_realpath (value p)
{
  CAMLparam1 (p);
  HANDLE h;
  wchar_t *wp;
  wchar_t *wr;
  DWORD wr_len;
  value rp;

  // caml_unix_check_path (p, "realpath");
  wp = caml_stat_strdup_to_utf16 (String_val (p));
  h = CreateFile (wp, 0,
                  FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, NULL,
                  OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, NULL);
  caml_stat_free (wp);

  if (h == INVALID_HANDLE_VALUE)
  {
    caml_win32_maperr (GetLastError ());
    caml_uerror ("realpath", p);
  }

  wr_len = GetFinalPathNameByHandle (h, NULL, 0, VOLUME_NAME_DOS);
  if (wr_len == 0)
  {
    caml_win32_maperr (GetLastError ());
    CloseHandle (h);
    caml_uerror ("realpath", p);
  }

  wr = caml_stat_alloc ((wr_len + 1) * sizeof (wchar_t));
  wr_len = GetFinalPathNameByHandle (h, wr, wr_len, VOLUME_NAME_DOS);

  if (wr_len == 0)
  {
    caml_win32_maperr (GetLastError ());
    CloseHandle (h);
    caml_stat_free (wr);
    caml_uerror ("realpath", p);
  }

  rp = caml_copy_string_of_utf16 (wr);
  CloseHandle (h);
  caml_stat_free (wr);
  CAMLreturn (rp);
}

#endif
#endif
