
#define EXTUNIX_WANT_STATVFS
#include "config.h"

#if defined(EXTUNIX_HAVE_STATVFS)

static int st_flags_table[] = {
  ST_RDONLY, ST_NOSUID, ST_NODEV, ST_NOEXEC, ST_SYNCHRONOUS,
  ST_MANDLOCK, ST_WRITE, ST_APPEND, ST_IMMUTABLE, ST_NOATIME,
  ST_NODIRATIME, ST_RELATIME
};

static const int st_flags_table_size =
  sizeof(st_flags_table) / sizeof(st_flags_table[0]);

static value convert_st_flags(unsigned long int f_flag)
{
  CAMLparam0();
  CAMLlocal2(list, tmp);

  int i;

  list = Val_emptylist;

  for (i = st_flags_table_size - 1; i >= 0; i--)
  {
    if (f_flag & st_flags_table[i])
    {
      tmp = caml_alloc(2, Tag_cons);
      Store_field(tmp,0,Val_int(i));
      Store_field(tmp,1,list);
      list = tmp;
    }
  }
  CAMLreturn(list);
}

static value convert(struct statvfs* s)
{
  CAMLparam0();
  CAMLlocal1(v_s);

  v_s = caml_alloc(11,0);

  Store_field(v_s,0,Val_int(s->f_bsize));
  Store_field(v_s,1,caml_copy_int64(s->f_blocks));
  Store_field(v_s,2,caml_copy_int64(s->f_bfree));
  Store_field(v_s,3,caml_copy_int64(s->f_bavail));
  Store_field(v_s,4,caml_copy_int64(s->f_files));
  Store_field(v_s,5,caml_copy_int64(s->f_ffree));
  Store_field(v_s,6,caml_copy_int64(s->f_favail));
  Store_field(v_s,7,caml_copy_int64(s->f_fsid));
  Store_field(v_s,8,Val_int(s->f_flag));
  Store_field(v_s,9,convert_st_flags(s->f_flag));
  Store_field(v_s,10,Val_int(s->f_namemax));

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

