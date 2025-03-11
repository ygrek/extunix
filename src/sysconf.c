/*
 * Binding to sysconf
 *
 * Copyright 2013
 *
 * License LGPL-2.1 with OCaml linking static exception
 *
 * author: Roman Vorobets
 *
 */

#define EXTUNIX_WANT_SYSCONF
#include "config.h"

#if defined(EXTUNIX_HAVE_SYSCONF)

#ifndef _SC_PHYS_PAGES
#define  _SC_PHYS_PAGES (-1)
#endif

#ifndef _SC_AVPHYS_PAGES
#define _SC_AVPHYS_PAGES (-1)
#endif

#ifndef _SC_NPROCESSORS_CONF
#define _SC_NPROCESSORS_CONF (-1)
#endif

#ifndef _SC_NPROCESSORS_ONLN
#define _SC_NPROCESSORS_ONLN (-1)
#endif

static const int caml_conf_table[] =
  {
    _SC_ARG_MAX,
    _SC_CHILD_MAX,
    _SC_HOST_NAME_MAX,
    _SC_LOGIN_NAME_MAX,
    _SC_CLK_TCK,
    _SC_OPEN_MAX,
    _SC_PAGESIZE,
    _SC_RE_DUP_MAX,
    _SC_STREAM_MAX,
    _SC_SYMLOOP_MAX,
    _SC_TTY_NAME_MAX,
    _SC_TZNAME_MAX,
    _SC_VERSION,
    _SC_LINE_MAX,
    _SC_2_VERSION,
    _SC_PHYS_PAGES,
    _SC_AVPHYS_PAGES,
    _SC_NPROCESSORS_CONF,
    _SC_NPROCESSORS_ONLN
  };

CAMLprim value caml_extunix_sysconf(value name)
{
  CAMLparam1(name);
  long r = -1;
  int sc = caml_conf_table[Int_val(name)];

  if (-1 == sc)
  {
    caml_raise_not_found();
    assert(0);
  }

  r = sysconf(sc);

  if (-1 == r)
  {
    caml_uerror("sysconf", Nothing);
  }

  CAMLreturn(caml_copy_int64(r));
}

#endif
