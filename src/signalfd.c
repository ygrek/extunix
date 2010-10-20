/******************************************************************************/
/* signalfd stubs                                                             */
/*                                                                            */
/* NO COPYRIGHT -- RELEASED INTO THE PUBLIC DOMAIN                            */
/*                                                                            */
/* Author: Kaustuv Chaudhuri <kaustuv.chaudhuri@inria.fr>                     */
/******************************************************************************/

#define WANT_SIGNALFD
#include "config.h"

#define Some_val(v) Field(v,0)
#define Val_none Val_int(0)

#if defined(HAVE_SIGNALFD)

extern int caml_convert_signal_number(int signo);
extern int caml_rev_convert_signal_number(int signo);

CAMLprim
value caml_extunix_signalfd(value vfd, value vsigs, value vflags, value v_unit)
{
  CAMLparam4(vfd, vsigs, vflags, v_unit);
  int fd = ((Val_none == vfd) ? -1 : Int_val(Some_val(vfd)));
  sigset_t ss;
  sigemptyset (&ss);
  while (!Is_long (vsigs)) {
    int sig = caml_convert_signal_number (Int_val (Field (vsigs, 0)));
    if (sigaddset (&ss, sig) < 0) uerror ("sigaddset", Nothing);
    vsigs = Field (vsigs, 1);
  }
  int flags = 0;
  while (!Is_long (vflags)) {
    int f = Int_val (Field (vflags, 0));
    if (SFD_NONBLOCK == f) flags |= SFD_NONBLOCK;
    if (SFD_CLOEXEC == f)  flags |= SFD_CLOEXEC;
    vflags = Field (vflags, 1);
  }
  int ret = signalfd (fd, &ss, flags);
  if (ret < 0) uerror ("signalfd", Nothing);
  CAMLreturn (Val_int (ret));
}

/* [HACK] improve these -- bytestream representation is OK */
static struct custom_operations ssi_ops = {
  "signalfd.signalfd_siginfo",
  custom_finalize_default,
  custom_compare_default, custom_hash_default,
  custom_serialize_default, custom_deserialize_default
};

#define SSI_SIZE sizeof(struct signalfd_siginfo)

CAMLprim
value caml_extunix_signalfd_read(value vfd)
{
  CAMLparam1(vfd);
  CAMLlocal1(vret);
  vret = caml_alloc_custom(&ssi_ops, SSI_SIZE, 0, 1);
  ssize_t nread = read(Int_val(vfd), Data_custom_val(vret), SSI_SIZE);
  if (nread < SSI_SIZE)
    caml_failwith("signalfd: read(2) failed on a signalfd");
  CAMLreturn(vret);
}

CAMLprim
value caml_extunix_ssi_signo_sys(value vssi)
{
  CAMLparam1(vssi);
  struct signalfd_siginfo *ssi = (void *)(Data_custom_val(vssi));
  CAMLreturn(Val_int(caml_rev_convert_signal_number(ssi->ssi_signo)));
}

#define SSI_GET_FIELD(field,coerce)                                     \
  CAMLprim                                                              \
  value caml_extunix_ssi_##field(value vssi)                            \
  {                                                                     \
    CAMLparam1(vssi);                                                   \
    struct signalfd_siginfo *ssi = (void *)Data_custom_val(vssi);       \
    CAMLreturn(coerce(ssi->ssi_##field));                               \
  }                                                                     \

SSI_GET_FIELD( signo   , caml_copy_int32 )
SSI_GET_FIELD( errno   , caml_copy_int32 )
SSI_GET_FIELD( code    , caml_copy_int32 )
SSI_GET_FIELD( pid     , caml_copy_int32 )
SSI_GET_FIELD( uid     , caml_copy_int32 )
SSI_GET_FIELD( fd      , Val_int         )
SSI_GET_FIELD( tid     , caml_copy_int32 )
SSI_GET_FIELD( band    , caml_copy_int32 )
SSI_GET_FIELD( overrun , caml_copy_int32 )
SSI_GET_FIELD( trapno  , caml_copy_int32 )
SSI_GET_FIELD( status  , caml_copy_int32 )
SSI_GET_FIELD( int     , caml_copy_int32 )
SSI_GET_FIELD( ptr     , caml_copy_int64 )
SSI_GET_FIELD( utime   , caml_copy_int64 )
SSI_GET_FIELD( stime   , caml_copy_int64 )
SSI_GET_FIELD( addr    , caml_copy_int64 )

#endif /* HAVE_SIGNALFD */

