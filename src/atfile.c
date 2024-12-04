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
  int dirfd = Int_val(v_dirfd);
  struct stat buf;
  char* p = caml_stat_strdup(String_val(v_name));
  int flags = caml_convert_flag_list(v_flags, at_flags_table);
  flags &= (AT_SYMLINK_NOFOLLOW | AT_NO_AUTOMOUNT); /* only allowed flags here */

  caml_enter_blocking_section();
  ret = fstatat(dirfd, p, &buf, flags);
  caml_leave_blocking_section();
  caml_stat_free(p);
  if (ret != 0) uerror("fstatat", v_name);
  if (buf.st_size > Max_long && (buf.st_mode & S_IFMT) == S_IFREG)
    unix_error(EOVERFLOW, "fstatat", v_name);
  CAMLreturn(stat_aux(/*0,*/ &buf));
}

CAMLprim value caml_extunix_unlinkat(value v_dirfd, value v_name, value v_flags)
{
  CAMLparam3(v_dirfd, v_name, v_flags);
  int dirfd = Int_val(dirfd);
  char* p = caml_stat_strdup(String_val(v_name));
  int ret = 0;
  int flags = caml_convert_flag_list(v_flags, at_flags_table);
  flags &= AT_REMOVEDIR;  /* only allowed flag here */

  caml_enter_blocking_section();
  ret = unlinkat(dirfd, p, flags);
  caml_leave_blocking_section();
  caml_stat_free(p);
  if (ret != 0) uerror("unlinkat", v_name);
  CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_renameat(value v_oldfd, value v_oldname, value v_newfd, value v_newname)
{
  CAMLparam4(v_oldfd, v_oldname, v_newfd, v_newname);
  int oldfd = Int_val(v_oldfd), newfd = Int_val(newfd);
  char *oldname = caml_stat_strdup(String_val(v_oldname)),
       *newname = caml_stat_strdup(String_val(v_newname));
  caml_enter_blocking_section();
  int ret = renameat(oldfd, oldname, newfd, newname);
  caml_leave_blocking_section();
  caml_stat_free(newname);
  caml_stat_free(oldname);
  if (ret != 0) uerror("renameat", v_oldname);
  CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_mkdirat(value v_dirfd, value v_name, value v_mode)
{
  CAMLparam3(v_dirfd, v_name, v_mode);
  int dirfd = Int_val(v_dirfd), mode = Int_val(v_mode);
  char *name = caml_stat_strdup(String_val(v_name));
  caml_enter_blocking_section();
  int ret = mkdirat(dirfd, name, mode);
  caml_leave_blocking_section();
  caml_stat_free(name);
  if (ret != 0) uerror("mkdirat", v_name);
  CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_linkat(value v_olddirfd, value v_oldname, value v_newdirfd, value v_newname, value v_flags)
{
  CAMLparam5(v_olddirfd, v_oldname, v_newdirfd, v_newname, v_flags);
  int olddirfd = Int_val(v_olddirfd), newdirfd = Int_val(v_newdirfd);
  char *oldname = caml_stat_strdup(String_val(v_oldname)),
       *newname = caml_stat_strdup(String_val(v_newname));
  int ret = 0;
  int flags = caml_convert_flag_list(v_flags, at_flags_table);
  flags &= AT_SYMLINK_FOLLOW;  /* only allowed flag here */
  caml_enter_blocking_section();
  ret = linkat(olddirfd, oldname, newdirfd, newname, flags);
  caml_leave_blocking_section();
  caml_stat_free(newname);
  caml_stat_free(oldname);
  if (ret != 0) uerror("linkat", v_oldname);
  CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_fchownat(value v_dirfd, value v_name, value v_owner, value v_group, value v_flags)
{
  CAMLparam5(v_dirfd, v_name, v_owner, v_group, v_flags);
  int dirfd = Int_val(v_dirfd), owner = Int_val(v_owner), group = Int_val(v_group);
  char *name = caml_stat_strdup(String_val(v_name));
  int ret = 0;
  int flags = caml_convert_flag_list(v_flags, at_flags_table);
  flags &= (AT_SYMLINK_NOFOLLOW /* | AT_EMPTY_PATH */);  /* only allowed flag here */
  caml_enter_blocking_section();
  ret = fchownat(dirfd, name, owner, group, flags);
  caml_leave_blocking_section();
  caml_stat_free(name);
  if (ret != 0) uerror("fchownat", v_name);
  CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_fchmodat(value v_dirfd, value v_name, value v_mode, value v_flags)
{
  CAMLparam4(v_dirfd, v_name, v_mode, v_flags);
  int dirfd = Int_val(v_dirfd), mode = Int_val(v_mode);
  char *name = caml_stat_strdup(String_val(v_name));
  int ret = 0;
  int flags = caml_convert_flag_list(v_flags, at_flags_table);
  flags &= AT_SYMLINK_NOFOLLOW;  /* only allowed flag here */
  caml_enter_blocking_section();
  ret = fchmodat(dirfd, name, mode, flags);
  caml_leave_blocking_section();
  caml_stat_free(name);
  if (ret != 0) uerror("fchmodat", v_name);
  CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_symlinkat(value v_path, value v_newdirfd, value v_newname)
{
  CAMLparam3(v_path, v_newdirfd, v_newname);
  char *path = caml_stat_strdup(String_val(v_path)),
       *newname = caml_stat_strdup(String_val(v_newname));
  int newdirfd = Int_val(v_newdirfd);
  caml_enter_blocking_section();
  int ret = symlinkat(path, newdirfd, newname);
  caml_leave_blocking_section();
  caml_stat_free(newname);
  caml_stat_free(path);
  if (ret != 0) uerror("symlinkat", v_path);
  CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_openat(value v_dirfd, value v_path, value flags, value v_perm)
{
  CAMLparam4(v_dirfd, v_path, flags, v_perm);
  int dirfd = Int_val(v_dirfd), perm = Int_val(v_perm);
  int ret, cv_flags;
  char *path = caml_stat_strdup(String_val(v_path));;

  cv_flags = extunix_open_flags(flags);
  /* open on a named FIFO can block (PR#1533) */
  caml_enter_blocking_section();
  ret = openat(dirfd, path, cv_flags, perm);
  caml_leave_blocking_section();
  caml_stat_free(path);
  if (ret == -1) uerror("openat", v_path);
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
      tmp = caml_stat_resize_noexc (buffer, size);
      if (tmp == NULL)
      {
        caml_stat_free (buffer); /* if failed, dealloc is not performed */
        return NULL;
      }
      buffer = tmp;
      nchars = readlinkat (dirfd, filename, buffer, size);
      if (nchars < 0)
      {
          caml_stat_free (buffer);
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
  int dirfd = Int_val(v_dirfd);
  char* res;
  char* name = caml_stat_strdup(String_val(v_name));

  caml_enter_blocking_section();
  res = readlinkat_malloc(dirfd, name);
  caml_leave_blocking_section();
  caml_stat_free(name);
  if (res == NULL) uerror("readlinkat", v_name);
  v_link = caml_copy_string(res);
  caml_stat_free(res);
  CAMLreturn(v_link);
}

#endif
