
#define EXTUNIX_WANT_SOCKOPT
#include "config.h"

#if defined(EXTUNIX_HAVE_SOCKOPT)

#include <assert.h>

#ifndef TCP_KEEPCNT
#define TCP_KEEPCNT (-1)
#endif

#ifndef TCP_KEEPIDLE
#define TCP_KEEPIDLE (-1)
#endif

#ifndef TCP_KEEPINTVL
#define TCP_KEEPINTVL (-1)
#endif

#ifndef SO_REUSEPORT
#define SO_REUSEPORT (-1)
#endif

struct option {
  int opt;
  int level;
};

static struct option tcp_options[] = {
  { .opt = TCP_KEEPCNT, .level = IPPROTO_TCP},
  { .opt = TCP_KEEPIDLE, .level = IPPROTO_TCP},
  { .opt = TCP_KEEPINTVL, .level = IPPROTO_TCP},
  { .opt = SO_REUSEPORT, .level = SOL_SOCKET },
};

CAMLprim value caml_extunix_have_sockopt(value k)
{
  if (Int_val(k) < 0 || (unsigned int)Int_val(k) >= sizeof(tcp_options) / sizeof(tcp_options[0]))
  {
    caml_invalid_argument("have_sockopt");
  }

  return Val_bool(tcp_options[Int_val(k)].opt != -1);
}

CAMLprim value caml_extunix_setsockopt_int(value fd, value k, value v)
{
  int optval = Int_val(v);
  socklen_t optlen = sizeof(optval);

  if (Int_val(k) < 0 || (unsigned int)Int_val(k) >= sizeof(tcp_options) / sizeof(tcp_options[0]))
  {
    caml_invalid_argument("setsockopt_int");
  }

  if (tcp_options[Int_val(k)].opt == -1)
  {
    caml_raise_not_found();
    assert(0);
  }

  if (0 != setsockopt(Int_val(fd), tcp_options[Int_val(k)].level, tcp_options[Int_val(k)].opt, &optval, optlen))
  {
    uerror("setsockopt_int", Nothing);
  }

  return Val_unit;
}

CAMLprim value caml_extunix_getsockopt_int(value fd, value k)
{
  int optval;
  socklen_t optlen = sizeof(optval);

  if (Int_val(k) < 0 || (unsigned int)Int_val(k) >= sizeof(tcp_options) / sizeof(tcp_options[0]))
  {
    caml_invalid_argument("getsockopt_int");
  }

  if (tcp_options[Int_val(k)].opt == -1)
  {
    caml_raise_not_found();
    assert(0);
  }

  if (0 != getsockopt(Int_val(fd), tcp_options[Int_val(k)].level, tcp_options[Int_val(k)].opt, &optval, &optlen))
  {
    uerror("getsockopt_int", Nothing);
  }

  return Val_int(optval);
}

#endif
