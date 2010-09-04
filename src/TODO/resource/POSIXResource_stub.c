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

#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/unixsupport.h>
#include <caml/callback.h>
#include <caml/fail.h>
#include <assert.h>
#include <errno.h>

static void caml_resource_not_implemented (char *what)
{
  caml_raise_with_string(*caml_named_value("POSIXResource.NotImplemented"), what);
};

#ifdef WIN32

CAMLprim value caml_resource_getpriority_stub (value vwprio)
{
  CAMLparam1(vwprio);
  caml_resource_not_implemented("getpriority");
  CAMLreturn(Val_unit);
};

CAMLprim value caml_resource_setpriority_stub (value vwprio, 
                                               value vprio)
{
  CAMLparam2(vwprio, vprio);
  caml_resource_not_implemented("setpriority");
  CAMLreturn(Val_unit);
};

CAMLprim value caml_resource_getrlimit_stub (value vrsrc)
{
  CAMLparam1(vrsrc);
  caml_resource_not_implemented("getrlimit");
  CAMLreturn(Val_unit);
};

CAMLprim value caml_resource_setrlimit_stub (value vrsrc, 
                                             value vslimit, 
                                             value vhlimit)
{
  CAMLparam3(vrsrc, vslimit, vhlimit);
  caml_resource_not_implemented("setrlimit");
  CAMLreturn(Val_unit);
};

#else

#include <sys/resource.h>

static void caml_resource_decode_which_prio (value vwprio, 
                                             int *pwhich, 
                                             id_t *pwho)
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
      caml_invalid_argument("POSIXResource.{get,set}priority");
  };

  CAMLreturn0;
};

CAMLprim value caml_resource_getpriority_stub (value vwprio)
{
  int  which;
  id_t who; 
  int  res = -1;

  CAMLparam1(vwprio);

  caml_resource_decode_which_prio(vwprio, &which, &who);

  errno = 0;
  res = getpriority(which, who);
  if (res == -1 && errno != 0)
  {
    uerror("POSIXResource.getpriority", Nothing);
  };

  CAMLreturn(Val_int(res));
};

CAMLprim value caml_resource_setpriority_stub (value vwprio, 
                                               value vprio)
{
  int  which;
  id_t who; 

  CAMLparam2(vwprio, vprio);

  caml_resource_decode_which_prio(vwprio, &which, &who);

  if (setpriority(which, who, Int_val(vprio)) != 0)
  {
    uerror("POSIXResource.setpriority", Nothing);
  };

  CAMLreturn(Val_unit);
};

#define RESOURCE_LEN 7

int resource_map[RESOURCE_LEN] = 
  {
    RLIMIT_CORE,
    RLIMIT_CPU,
    RLIMIT_DATA,
    RLIMIT_FSIZE,
    RLIMIT_NOFILE,
    RLIMIT_STACK,
    RLIMIT_AS
  };

static int caml_resource_decode_resource (value vrsrc)
{
  CAMLparam1(vrsrc);

  assert(Int_val(vrsrc) < RESOURCE_LEN);

  CAMLreturnT(int, resource_map[Int_val(vrsrc)]);
}

static value caml_resource_encode_limit (rlim_t v)
{
  CAMLparam0();
  CAMLlocal1(vres);

  if (v == RLIM_INFINITY)
  {
    vres = Val_int(0);
  }
  else
  {
    vres = caml_alloc(0, 1);
    Store_field(vres, 0, caml_copy_int64(v));
  };

  CAMLreturn(vres);
};

CAMLprim value caml_resource_getrlimit_stub (value vrsrc)
{
  struct rlimit rlmt;

  CAMLparam1(vrsrc);
  CAMLlocal1(vres);

  if (getrlimit(caml_resource_decode_resource(vrsrc), &rlmt) != 0)
  {
    uerror("POSIXResource.getrlimit", Nothing);
  };

  vres = caml_alloc(2, 0);
  Store_field(vres, 0, caml_resource_encode_limit(rlmt.rlim_cur));
  Store_field(vres, 1, caml_resource_encode_limit(rlmt.rlim_max));

  CAMLreturn(vres);
};

static rlim_t caml_resource_decode_change_limit (value vchglimit, rlim_t no_change)
{
  rlim_t res = no_change;

  CAMLparam1(vchglimit);
  CAMLlocal1(vlimit);

  /* Is block -> Limit lmt */ 
  if (Is_block(vchglimit))
  {
    assert(Tag_val(vchglimit) == 0);
    vlimit = Field(vchglimit, 0);
    if (Is_block(vlimit))
    {
      res = Int64_val(Field(vlimit, 0));
    }
    else
    {
      res = RLIM_INFINITY;
    };
  };
  /* Else -> No_change = default value */

  CAMLreturnT(rlim_t, res);
};

CAMLprim value caml_resource_setrlimit_stub (value vrsrc, 
                                             value vslimit, 
                                             value vhlimit)
{
  struct rlimit rlmt = { 0 };

  CAMLparam3(vrsrc, vslimit, vhlimit);

  rlmt.rlim_cur = caml_resource_decode_change_limit(vslimit, RLIM_SAVED_CUR);
  rlmt.rlim_max = caml_resource_decode_change_limit(vhlimit, RLIM_SAVED_MAX);

  if (setrlimit(caml_resource_decode_resource(vrsrc), &rlmt) != 0)
  {
    uerror("POSIXResource.setrlimit", Nothing);
  };

  CAMLreturn(Val_unit);
};

#endif /* WIN32 */
