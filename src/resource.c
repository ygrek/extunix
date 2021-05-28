/******************************************************************************/
/*  ocaml-posix-resource: POSIX resource operations                           */
/*                                                                            */
/*  Copyright (C) 2009 Sylvain Le Gall <sylvain@le-gall.net>                  */
/*                                                                            */
/*  This library is free software; you can redistribute it and/or modify it   */
/*  under the terms of the GNU Lesser General Public License as published by  */
/*  the Free Software Foundation; either version 2.1 of the License, or (at   */
/*  your option) any later version; with the OCaml static compilation         */
/*  exception.                                                                */
/*                                                                            */
/*  This library is distributed in the hope that it will be useful, but       */
/*  WITHOUT ANY WARRANTY; without even the implied warranty of                */
/*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser  */
/*  General Public License for more details.                                  */
/*                                                                            */
/*  You should have received a copy of the GNU Lesser General Public License  */
/*  along with this library; if not, write to the Free Software Foundation,   */
/*  Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA               */
/******************************************************************************/

/*
 * POSIX resource for OCaml
 *
 * Author: Sylvain Le Gall
 *
 */

#define EXTUNIX_WANT_RESOURCE
#include "config.h"

#if defined(EXTUNIX_HAVE_RESOURCE)

static void decode_which_prio(value vwprio, int *pwhich, id_t *pwho)
{
  CAMLparam1(vwprio);

  assert(Is_block(vwprio) && Wosize_val(vwprio) == 1);

  *pwho=Long_val(Field(vwprio, 0));

  switch(Tag_val(vwprio))
  {
    case 0:
      *pwhich = PRIO_PROCESS;
      break;
    case 1:
      *pwhich = PRIO_PGRP;
      break;
    case 2:
      *pwhich = PRIO_USER;
      break;
    default:
      caml_invalid_argument("decode_which_prio");
  }

  CAMLreturn0;
}

CAMLprim value caml_extunix_getpriority(value vwprio)
{
  CAMLparam1(vwprio);
  int  which;
  id_t who;
  int  res = -1;

  decode_which_prio(vwprio, &which, &who);

  errno = 0;
  res = getpriority(which, who);
  if (res == -1 && errno != 0)
  {
    uerror("getpriority", Nothing);
  }

  CAMLreturn(Val_int(res));
}

CAMLprim value caml_extunix_setpriority(value vwprio, value vprio)
{
  CAMLparam2(vwprio, vprio);
  int  which;
  id_t who;

  decode_which_prio(vwprio, &which, &who);

  if (setpriority(which, who, Int_val(vprio)) != 0)
  {
    uerror("setpriority", Nothing);
  }

  CAMLreturn(Val_unit);
}

#define RESOURCE_LEN 7

static int resource_map[RESOURCE_LEN] =
  {
    RLIMIT_CORE,
    RLIMIT_CPU,
    RLIMIT_DATA,
    RLIMIT_FSIZE,
    RLIMIT_NOFILE,
    RLIMIT_STACK,
    RLIMIT_AS
  };

static int decode_resource(value vrsrc)
{
  CAMLparam1(vrsrc);
  assert(Int_val(vrsrc) < RESOURCE_LEN && Int_val(vrsrc) >= 0);
  CAMLreturnT(int, resource_map[Int_val(vrsrc)]);
}

static value encode_limit(rlim_t v)
{
  CAMLparam0();
  CAMLlocal1(vres);

  if (v == RLIM_INFINITY)
  {
    vres = Val_int(0);
  }
  else
  {
    vres = caml_alloc(1, 0);
    Store_field(vres, 0, caml_copy_int64(v));
  }

  CAMLreturn(vres);
}

static rlim_t decode_limit(value vchglimit)
{
  CAMLparam1(vchglimit);
  rlim_t res = RLIM_INFINITY;

  if (Is_block(vchglimit))
  {
    assert(Tag_val(vchglimit) == 0);
    res = Int64_val(Field(vchglimit, 0));
  }

  CAMLreturnT(rlim_t, res);
}

CAMLprim value caml_extunix_getrlimit(value vrsrc)
{
  CAMLparam1(vrsrc);
  CAMLlocal1(vres);
  struct rlimit rlmt;

  if (getrlimit(decode_resource(vrsrc), &rlmt) != 0)
  {
    uerror("getrlimit", Nothing);
  }

  vres = caml_alloc(2, 0);
  Store_field(vres, 0, encode_limit(rlmt.rlim_cur));
  Store_field(vres, 1, encode_limit(rlmt.rlim_max));

  CAMLreturn(vres);
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wmissing-field-initializers"

CAMLprim value caml_extunix_setrlimit(value vrsrc, value vslimit, value vhlimit)
{
  CAMLparam3(vrsrc, vslimit, vhlimit);
  struct rlimit rlmt = { 0 };

  rlmt.rlim_cur = decode_limit(vslimit);
  rlmt.rlim_max = decode_limit(vhlimit);

  if (setrlimit(decode_resource(vrsrc), &rlmt) != 0)
  {
    uerror("setrlimit", Nothing);
  }

  CAMLreturn(Val_unit);
}

#pragma GCC diagnostic pop

#endif /* EXTUNIX_HAVE_RESOURCE */

