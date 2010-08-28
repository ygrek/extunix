
#define WANT_STATVFS
#include "config.h"

#if defined(HAVE_STATVFS)

CAMLprim value caml_extunix_statvfs(value v_path)
{
  CAMLparam1(v_path);
  CAMLlocal1(v_s);
	struct statvfs s;

	if (0 != statvfs(String_val(v_path), &s))
	{
    uerror("statvfs",v_path);
	}

  v_s = caml_alloc(5,0);

  Store_field(v_s,0,Val_int(s.f_bsize));
  Store_field(v_s,1,caml_copy_int64(s.f_blocks));
  Store_field(v_s,2,caml_copy_int64(s.f_bavail));
  Store_field(v_s,3,caml_copy_int64(s.f_files));
  Store_field(v_s,4,caml_copy_int64(s.f_favail));

  CAMLreturn(v_s);
}

#endif

