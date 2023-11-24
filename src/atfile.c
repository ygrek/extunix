
#define EXTUNIX_WANT_ATFILE
#include "config.h"

#if defined(EXTUNIX_HAVE_ATFILE)

/* otherlibs/unix/cst2constr.h */
#if OCAML_VERSION_MAJOR >= 5
# if OCAML_VERSION_MAJOR >= 2
extern value caml_unix_cst_to_constr(int n, const int * tbl, int size, int deflt);
# else
extern value caml_unix_cst_to_constr(int n, int * tbl, int size, int deflt);
# endif
#else
extern value cst_to_constr(int n, int * tbl, int size, int deflt);
#define caml_unix_cst_to_constr cst_to_constr
#endif

static const int file_kind_table[] = {
  S_IFREG, S_IFDIR, S_IFCHR, S_IFBLK, S_IFLNK, S_IFIFO, S_IFSOCK
};

#ifndef AT_EACCESS
#define AT_EACCESS 0
#endif

#ifndef AT_SYMLINK_NOFOLLOW
#define AT_SYMLINK_NOFOLLOW 0
#endif

#ifndef AT_SYMLINK_FOLLOW
#define AT_SYMLINK_FOLLOW 0
#endif

#ifndef AT_NO_AUTOMOUNT
#define AT_NO_AUTOMOUNT 0
#endif

static const int at_flags_table[] = {
    AT_EACCESS, AT_SYMLINK_NOFOLLOW, AT_REMOVEDIR, AT_SYMLINK_FOLLOW, AT_NO_AUTOMOUNT,
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
  Field (v, 2) =
    caml_unix_cst_to_constr(buf->st_mode & S_IFMT, file_kind_table,
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

CAMLprim value caml_extunix_fstatat(value v_dirfd, value v_name, value v_flags)
{
  CAMLparam3(v_dirfd, v_name, v_flags);
  int ret;
  struct stat buf;
  char* p = strdup(String_val(v_name));
  int flags = caml_convert_flag_list(v_flags, at_flags_table);
  flags &= (AT_SYMLINK_NOFOLLOW | AT_NO_AUTOMOUNT); /* only allowed flags here */

  caml_enter_blocking_section();
  ret = fstatat(Int_val(v_dirfd), p, &buf, flags);
  caml_leave_blocking_section();
  free(p);
  if (ret != 0) uerror("fstatat", v_name);
  if (buf.st_size > Max_long && (buf.st_mode & S_IFMT) == S_IFREG)
    unix_error(EOVERFLOW, "fstatat", v_name);
  CAMLreturn(stat_aux(/*0,*/ &buf));
}

CAMLprim value caml_extunix_unlinkat(value v_dirfd, value v_name, value v_flags)
{
  CAMLparam3(v_dirfd, v_name, v_flags);
  char* p = strdup(String_val(v_name));
  int ret = 0;
  int flags = caml_convert_flag_list(v_flags, at_flags_table);
  flags &= AT_REMOVEDIR;  /* only allowed flag here */

  caml_enter_blocking_section();
  ret = unlinkat(Int_val(v_dirfd), p, flags);
  caml_leave_blocking_section();
  free(p);
  if (ret != 0) uerror("unlinkat", v_name);
  CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_renameat(value v_oldfd, value v_oldname, value v_newfd, value v_newname)
{
  CAMLparam4(v_oldfd, v_oldname, v_newfd, v_newname);
  int ret = renameat(Int_val(v_oldfd), String_val(v_oldname), Int_val(v_newfd), String_val(v_newname));
  if (ret != 0) uerror("renameat", v_oldname);
  CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_mkdirat(value v_dirfd, value v_name, value v_mode)
{
  CAMLparam3(v_dirfd, v_name, v_mode);
  int ret = mkdirat(Int_val(v_dirfd), String_val(v_name), Int_val(v_mode));
  if (ret != 0) uerror("mkdirat", v_name);
  CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_linkat(value v_olddirfd, value v_oldname, value v_newdirfd, value v_newname, value v_flags)
{
  CAMLparam5(v_olddirfd, v_oldname, v_newdirfd, v_newname, v_flags);
  int ret = 0;
  int flags = caml_convert_flag_list(v_flags, at_flags_table);
  flags &= AT_SYMLINK_FOLLOW;  /* only allowed flag here */
  ret = linkat(Int_val(v_olddirfd), String_val(v_oldname), Int_val(v_newdirfd), String_val(v_newname), flags);
  if (ret != 0) uerror("linkat", v_oldname);
  CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_fchownat(value v_dirfd, value v_name, value v_owner, value v_group, value v_flags)
{
  CAMLparam5(v_dirfd, v_name, v_owner, v_group, v_flags);
  int ret = 0;
  int flags = caml_convert_flag_list(v_flags, at_flags_table);
  flags &= (AT_SYMLINK_NOFOLLOW /* | AT_EMPTY_PATH */);  /* only allowed flag here */
  ret = fchownat(Int_val(v_dirfd), String_val(v_name), Int_val(v_owner), Int_val(v_group), flags);
  if (ret != 0) uerror("fchownat", v_name);
  CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_fchmodat(value v_dirfd, value v_name, value v_mode, value v_flags)
{
  CAMLparam4(v_dirfd, v_name, v_mode, v_flags);
  int ret = 0;
  int flags = caml_convert_flag_list(v_flags, at_flags_table);
  flags &= AT_SYMLINK_NOFOLLOW;  /* only allowed flag here */
  ret = fchmodat(Int_val(v_dirfd), String_val(v_name), Int_val(v_mode), flags);
  if (ret != 0) uerror("fchmodat", v_name);
  CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_symlinkat(value v_path, value v_newdirfd, value v_newname)
{
  CAMLparam3(v_path, v_newdirfd, v_newname);
  int ret = symlinkat(String_val(v_path), Int_val(v_newdirfd), String_val(v_newname));
  if (ret != 0) uerror("symlinkat", v_path);
  CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_openat(value v_dirfd, value path, value flags, value perm)
{
  CAMLparam4(v_dirfd, path, flags, perm);
  int ret, cv_flags;
  char * p;

  cv_flags = extunix_open_flags(flags);
  p = strdup(String_val(path));
  /* open on a named FIFO can block (PR#1533) */
  caml_enter_blocking_section();
  ret = openat(Int_val(v_dirfd), p, cv_flags, Int_val(perm));
  caml_leave_blocking_section();
  free(p);
  if (ret == -1) uerror("openat", path);
  CAMLreturn (Val_int(ret));
}

char *readlinkat_malloc (int dirfd, const char *filename)
{
  int size = 100;
  int nchars;
  char *buffer = NULL;
  char *tmp;

  while (1)
    {
      tmp = (char *) realloc (buffer, size);
      if (tmp == NULL)
      {
        free(buffer); /* if failed, dealloc is not performed */
        return NULL;
      }
      buffer = tmp;
      nchars = readlinkat (dirfd, filename, buffer, size);
      if (nchars < 0)
      {
          free (buffer);
          return NULL;
      }
      if (nchars < size)
      {
        buffer[nchars] = '\0';
        return buffer;
      }
      size *= 2;
    }
}

CAMLprim value caml_extunix_readlinkat(value v_dirfd, value v_name)
{
  CAMLparam2(v_dirfd, v_name);
  CAMLlocal1(v_link);
  char* res;
  char* p = strdup(String_val(v_name));

  caml_enter_blocking_section();
  res = readlinkat_malloc(Int_val(v_dirfd), p);
  caml_leave_blocking_section();
  free(p);
  if (res == NULL) uerror("readlinkat", v_name);
  v_link = caml_copy_string(res);
  free(res);
  CAMLreturn(v_link);
}

#endif

