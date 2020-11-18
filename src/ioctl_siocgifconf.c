
#define EXTUNIX_WANT_SIOCGIFCONF
#define EXTUNIX_WANT_INET_NTOA
#define EXTUNIX_WANT_INET_NTOP

#define EXTUNIX_WANT_IFADDRS
#include "config.h"

#if defined(EXTUNIX_HAVE_SIOCGIFCONF)

CAMLprim value caml_extunix_ioctl_siocgifconf(value v_sock)
{
    CAMLparam1(v_sock);
    CAMLlocal3(lst,item,cons);

    struct ifreq ifreqs[32];
    struct ifconf ifconf;
    unsigned int i;

    lst = Val_emptylist;

    memset(&ifconf, 0, sizeof(ifconf));
    ifconf.ifc_req = ifreqs;
    ifconf.ifc_len = sizeof(ifreqs);

    if (0 != ioctl(Int_val(v_sock), SIOCGIFCONF, (char *)&ifconf))
      uerror("ioctl(SIOCGIFCONF)", Nothing);

    for (i = 0; i < ifconf.ifc_len/sizeof(struct ifreq); ++i)
    {
      cons = caml_alloc(2, 0);
      item = caml_alloc(2, 0);
      Store_field(item, 0, caml_copy_string(ifreqs[i].ifr_name));
      Store_field(item, 1, caml_copy_string(inet_ntoa(((struct sockaddr_in *)&ifreqs[i].ifr_addr)->sin_addr)));
      Store_field(cons, 0, item); /* head */
      Store_field(cons, 1, lst);  /* tail */
      lst = cons;
    }

    CAMLreturn(lst);
}

#endif

#if defined(EXTUNIX_HAVE_IFADDRS)

CAMLprim value caml_extunix_getifaddrs(value v)
{
    CAMLparam1(v);
    CAMLlocal3(lst,item,cons);

    struct ifaddrs *ifaddrs = NULL;
    struct ifaddrs *iter = NULL;
    char addr_str[INET6_ADDRSTRLEN];

    lst = Val_emptylist;

    if (0 != getifaddrs(&ifaddrs))
    {
      if (ifaddrs) freeifaddrs(ifaddrs);
      uerror("getifaddrs", Nothing);
    }

    iter = ifaddrs; /* store head for further free */

    while(iter != NULL)
    {
      if (iter->ifa_addr != NULL)
      {
        const sa_family_t family = iter->ifa_addr->sa_family;
        if (family == AF_INET || family == AF_INET6)
        {
          cons = caml_alloc(2, 0);
          item = caml_alloc(2, 0);
          Store_field(item, 0, caml_copy_string(iter->ifa_name));
          if (family == AF_INET)
          {
            if (NULL == inet_ntop(family, &((struct sockaddr_in *)iter->ifa_addr)->sin_addr, addr_str, INET_ADDRSTRLEN))
              uerror("inet_ntop", Nothing);
          }
          else
          {
            if (NULL == inet_ntop(family, &((struct sockaddr_in6 *)iter->ifa_addr)->sin6_addr, addr_str, INET6_ADDRSTRLEN))
              uerror("inet_ntop", Nothing);
          }
          Store_field(item, 1, caml_copy_string(addr_str));
          Store_field(cons, 0, item); /* head */
          Store_field(cons, 1, lst);  /* tail */
          lst = cons;
        }
      }
      iter = iter->ifa_next;
    }

    freeifaddrs(ifaddrs);
    CAMLreturn(lst);
}

#endif
