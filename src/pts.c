
#define EXTUNIX_WANT_PTS
#include "config.h"

#if defined(EXTUNIX_HAVE_PTS)

CAMLprim value caml_extunix_posix_openpt(value flags)
{
	CAMLparam1(flags);
	int ret, cv_flags;
	cv_flags = extunix_open_flags(flags);
	ret = posix_openpt(cv_flags);
	if(ret == -1)
		uerror("posix_openpt", Nothing);
	CAMLreturn(Val_int(ret));
}

CAMLprim value caml_extunix_grantpt(value fd)
{
	CAMLparam1(fd);
	if(grantpt(Int_val(fd)) == -1)
		uerror("grantpt", Nothing);
	CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_unlockpt(value fd)
{
	CAMLparam1(fd);
	if(unlockpt(Int_val(fd)) == -1)
		uerror("unlockpt", Nothing);
	CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_ptsname(value fd)
{
	CAMLparam1(fd);
	CAMLlocal1(ret);
	char *name = ptsname(Int_val(fd));
	if(name == 0)
		uerror("ptsname", Nothing);
	ret = caml_copy_string(name);
	CAMLreturn(ret);
}


#endif /* HAVE_PTS */
