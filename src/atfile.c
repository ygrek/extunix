
#define WANT_ATFILE
#include "config.h"

#if defined(HAVE_ATFILE)

#include <string.h>
#include <errno.h>

/* otherlibs/unix/cst2constr.h */
extern value cst_to_constr(int n, int * tbl, int size, int deflt);

static int file_kind_table[] = {
  S_IFREG, S_IFDIR, S_IFCHR, S_IFBLK, S_IFLNK, S_IFIFO, S_IFSOCK
};

static value stat_aux(/*int use_64,*/ struct stat *buf)
{
  CAMLparam0();
  CAMLlocal5(atime, mtime, ctime, offset, v);

  atime = caml_copy_double((double) buf->st_atime);
  mtime = caml_copy_double((double) buf->st_mtime);
  ctime = caml_copy_double((double) buf->st_ctime);
  offset = /*use_64 ? Val_file_offset(buf->st_size) :*/ Val_int (buf->st_size);
  v = caml_alloc_small(12, 0);
  Field (v, 0) = Val_int (buf->st_dev);
  Field (v, 1) = Val_int (buf->st_ino);
  Field (v, 2) = cst_to_constr(buf->st_mode & S_IFMT, file_kind_table,
                               sizeof(file_kind_table) / sizeof(int), 0);
  Field (v, 3) = Val_int (buf->st_mode & 07777);
  Field (v, 4) = Val_int (buf->st_nlink);
  Field (v, 5) = Val_int (buf->st_uid);
  Field (v, 6) = Val_int (buf->st_gid);
  Field (v, 7) = Val_int (buf->st_rdev);
  Field (v, 8) = offset;
  Field (v, 9) = atime;
  Field (v, 10) = mtime;
  Field (v, 11) = ctime;
  CAMLreturn(v);
}

CAMLprim value caml_extunix_fstatat(value v_dirfd, value v_name)
{
  CAMLparam2(v_dirfd, v_name);
  int ret;
  struct stat buf;
  char* p = caml_stat_alloc(caml_string_length(v_name) + 1);
  strcpy(p, String_val(v_name));
  caml_enter_blocking_section();
  ret = fstatat(Int_val(v_dirfd), p, &buf, 0);
  caml_leave_blocking_section();
  caml_stat_free(p);
  if (ret != 0) uerror("fstatat", Nothing);
  if (buf.st_size > Max_long && (buf.st_mode & S_IFMT) == S_IFREG)
    unix_error(EOVERFLOW, "fstat", Nothing);
  CAMLreturn(stat_aux(/*0,*/ &buf));
}

CAMLprim value caml_extunix_unlinkat(value v_dirfd, value v_name)
{
  CAMLparam2(v_dirfd, v_name);
  char* p = caml_stat_alloc(caml_string_length(v_name) + 1);
  strcpy(p, String_val(v_name));
  caml_enter_blocking_section();
  int ret = unlinkat(Int_val(v_dirfd), p, 0);
  caml_leave_blocking_section();
  caml_stat_free(p);
  if (ret != 0) uerror("unlinkat", Nothing);
  CAMLreturn(Val_unit);
}

/* otherlibs/unix/open.c */
static int open_flag_table[] = {
  O_RDONLY, O_WRONLY, O_RDWR, O_NONBLOCK, O_APPEND, O_CREAT, O_TRUNC, O_EXCL,
  O_NOCTTY, O_DSYNC, O_SYNC, O_RSYNC
};

CAMLprim value caml_extunix_openat(value v_dirfd, value path, value flags, value perm)
{
  CAMLparam4(v_dirfd, path, flags, perm);
  int ret, cv_flags;
  char * p;

  cv_flags = caml_convert_flag_list(flags, open_flag_table);
  p = caml_stat_alloc(caml_string_length(path) + 1);
  strcpy(p, String_val(path));
  /* open on a named FIFO can block (PR#1533) */
  caml_enter_blocking_section();
  ret = openat(Int_val(v_dirfd), p, cv_flags, Int_val(perm));
  caml_leave_blocking_section();
  caml_stat_free(p);
  if (ret == -1) uerror("openat", path);
  CAMLreturn (Val_int(ret));
}

#endif

