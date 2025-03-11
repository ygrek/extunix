#define EXTUNIX_WANT_SOCKOPT
#define EXTUNIX_WANT_TCP_KEEPIDLE
#define EXTUNIX_WANT_TCP_KEEPCNT
#define EXTUNIX_WANT_TCP_KEEPINTVL
#include "config.h"

#if defined(EXTUNIX_HAVE_SOCKOPT)

#ifndef TCP_KEEPCNT
#define TCP_KEEPCNT (-1)
#endif

#ifndef TCP_KEEPIDLE
#if defined(__APPLE__) && defined(TCP_KEEPALIVE)
#define TCP_KEEPIDLE (TCP_KEEPALIVE)
#else
#define TCP_KEEPIDLE (-1)
#endif
#endif

#ifndef TCP_KEEPINTVL
#define TCP_KEEPINTVL (-1)
#endif

#ifndef SO_REUSEPORT
#define SO_REUSEPORT (-1)
#endif

#ifndef SO_ATTACH_BPF
#define SO_ATTACH_BPF (-1)
#endif

#ifndef SO_ATTACH_REUSEPORT_EBPF
#define SO_ATTACH_REUSEPORT_EBPF (-1)
#endif

#ifndef SO_DETACH_FILTER
#define SO_DETACH_FILTER (-1)
#endif

#ifndef SO_DETACH_BPF
#define SO_DETACH_BPF (-1)
#endif

#ifndef SO_LOCK_FILTER
#define SO_LOCK_FILTER (-1)
#endif

struct option {
  int opt;
  int level;
};

static struct option tcp_options[] = {
  { TCP_KEEPCNT, IPPROTO_TCP },
  { TCP_KEEPIDLE, IPPROTO_TCP },
  { TCP_KEEPINTVL, IPPROTO_TCP },
  { SO_REUSEPORT, SOL_SOCKET },
  { SO_ATTACH_BPF, SOL_SOCKET },
  { SO_ATTACH_REUSEPORT_EBPF, SOL_SOCKET },
  { SO_DETACH_FILTER, SOL_SOCKET },
  { SO_DETACH_BPF, SOL_SOCKET },
  { SO_LOCK_FILTER, SOL_SOCKET },
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
#ifdef _WIN32
  SOCKET s = INVALID_SOCKET;
  if (KIND_SOCKET != Descr_kind_val(fd))
    caml_invalid_argument("setsockopt_int");
  s = Socket_val(fd);
#else
  int s = Int_val(fd);
#endif

  if (Int_val(k) < 0 || (unsigned int)Int_val(k) >= sizeof(tcp_options) / sizeof(tcp_options[0]))
  {
    caml_invalid_argument("setsockopt_int");
  }

  if (tcp_options[Int_val(k)].opt == -1)
  {
    caml_raise_not_found();
    assert(0);
  }

  if (0 != setsockopt(s, tcp_options[Int_val(k)].level, tcp_options[Int_val(k)].opt, (void *)&optval, optlen))
  {
#ifdef _WIN32
    if (WSAGetLastError() == WSAENOPROTOOPT) {
#else
    if (errno == ENOPROTOOPT) {
#endif
      caml_raise_not_found();
      assert(0);
    }
    caml_uerror("setsockopt_int", Nothing);
  }

  return Val_unit;
}

CAMLprim value caml_extunix_getsockopt_int(value fd, value k)
{
  int optval;
  socklen_t optlen = sizeof(optval);
#ifdef _WIN32
  SOCKET s = INVALID_SOCKET;
  if (KIND_SOCKET != Descr_kind_val(fd))
    caml_invalid_argument("getsockopt_int");
  s = Socket_val(fd);
#else
  int s = Int_val(fd);
#endif

  if (Int_val(k) < 0 || (unsigned int)Int_val(k) >= sizeof(tcp_options) / sizeof(tcp_options[0]))
  {
    caml_invalid_argument("getsockopt_int");
  }

  if (tcp_options[Int_val(k)].opt == -1)
  {
    caml_raise_not_found();
    assert(0);
  }

  if (0 != getsockopt(s, tcp_options[Int_val(k)].level, tcp_options[Int_val(k)].opt, (void *)&optval, &optlen))
  {
#ifdef _WIN32
    if (WSAGetLastError() == WSAENOPROTOOPT) {
#else
    if (errno == ENOPROTOOPT) {
#endif
      caml_raise_not_found();
      assert(0);
    }
    caml_uerror("getsockopt_int", Nothing);
  }

  return Val_int(optval);
}

#endif
