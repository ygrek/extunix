
#define EXTUNIX_WANT_STATVFS
#include "config.h"

#if defined(EXTUNIX_HAVE_STATVFS)

static value convert(struct statvfs* s)
{
  CAMLparam0();
  CAMLlocal1(v_s);

  v_s = caml_alloc(10,0);

  Store_field(v_s,0,Val_int(s->f_bsize));
  Store_field(v_s,1,caml_copy_int64(s->f_blocks));
  Store_field(v_s,2,caml_copy_int64(s->f_bfree));
  Store_field(v_s,3,caml_copy_int64(s->f_bavail));
  Store_field(v_s,4,caml_copy_int64(s->f_files));
  Store_field(v_s,5,caml_copy_int64(s->f_ffree));
  Store_field(v_s,6,caml_copy_int64(s->f_favail));
  Store_field(v_s,7,caml_copy_int64(s->f_fsid));
  Store_field(v_s,8,Val_int(s->f_flag));
  Store_field(v_s,9,Val_int(s->f_namemax));

  CAMLreturn(v_s);
}

CAMLprim value caml_extunix_statvfs(value v_path)
{
  CAMLparam1(v_path);
  struct statvfs s;

  if (0 != statvfs(String_val(v_path), &s))
  {
    uerror("statvfs",v_path);
  }

  CAMLreturn(convert(&s));
}

CAMLprim value caml_extunix_fstatvfs(value v_fd)
{
  CAMLparam1(v_fd);
  struct statvfs s;

  if (0 != fstatvfs(Int_val(v_fd), &s))
  {
    uerror("fstatvfs",Nothing);
  }

  CAMLreturn(convert(&s));
}

#endif

