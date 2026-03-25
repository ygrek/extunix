#define EXTUNIX_WANT_NO_NEW_PRIVS
#include "config.h"

#if defined(EXTUNIX_HAVE_NO_NEW_PRIVS)

CAMLprim value caml_extunix_set_no_new_privs(value v_unit)
{
    UNUSED(v_unit);
    if (prctl(PR_SET_NO_NEW_PRIVS, 1, 0, 0, 0) != 0)
        caml_uerror("prctl(PR_SET_NO_NEW_PRIVS)", Nothing);
    return Val_unit;
}

#endif
