
#define EXTUNIX_WANT_SIOCGIFCONF
#define EXTUNIX_WANT_INET_NTOA
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

