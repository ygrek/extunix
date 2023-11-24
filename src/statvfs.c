#define EXTUNIX_WANT_STATVFS
#include "config.h"

#if defined(EXTUNIX_HAVE_STATVFS) || defined(EXTUNIX_HAVE_FSTATVFS)

static const int st_flags_table[] = {
#if defined(_WIN32)
  FILE_READ_ONLY_VOLUME
#else
  ST_RDONLY, ST_NOSUID, ST_NODEV, ST_NOEXEC, ST_SYNCHRONOUS,
  ST_MANDLOCK, ST_WRITE, ST_APPEND, ST_IMMUTABLE, ST_NOATIME,
  ST_NODIRATIME, ST_RELATIME
#endif
};

static value convert_st_flags(unsigned long int f_flag)
{
  CAMLparam0();
  CAMLlocal2(list, tmp);

  unsigned int i;

  list = Val_emptylist;

  for (i = 0; i < sizeof(st_flags_table) / sizeof(st_flags_table[0]); i++)
  {
    if (f_flag & st_flags_table[i])
    {
      tmp = caml_alloc_small(2, Tag_cons);
      Field(tmp, 0) = Val_int(i);
      Field(tmp, 1) = list;
      list = tmp;
    }
  }
  CAMLreturn(list);
}
#endif

#if defined(EXTUNIX_HAVE_STATVFS) && defined(_WIN32)

#include <caml/osdeps.h>

CAMLprim value caml_extunix_statvfs(value v_path)
{
  CAMLparam1(v_path);
  CAMLlocal1(v_s);
  ULONG sectorsPerCluster = 0U, bytesPerSector = 0U, numberOfFreeClusters = 0U,
    totalNumberOfClusters = 0U, bsize = 0U, serialNumber = 0U, fileSystemFlags = 0U;
  ULONGLONG totalNumberOfFreeBytes = 0ULL;
  char_os *path = caml_stat_strdup_to_os(String_val(v_path));
  BOOL rc;

  rc = GetDiskFreeSpace(path, &sectorsPerCluster, &bytesPerSector,
                        &numberOfFreeClusters, &totalNumberOfClusters)
    && GetDiskFreeSpaceEx(path, NULL, NULL,
                          (PULARGE_INTEGER) &totalNumberOfFreeBytes)
    && GetVolumeInformation(path, NULL, 0, &serialNumber, NULL,
                            &fileSystemFlags, NULL, 0);
  caml_stat_free(path);

  if (!rc)
  {
    uerror("statvfs", v_path);
  }

  bsize = bytesPerSector * sectorsPerCluster;

  v_s = caml_alloc(11, 0);
  Store_field(v_s, 0, Val_int(bsize));        /* Filesystem block size */
  /* don't export s->f_frsize */
  Store_field(v_s, 1, caml_copy_int64(totalNumberOfClusters)); /* Size of fs in bsize units */
  Store_field(v_s, 2, caml_copy_int64(totalNumberOfFreeBytes / (ULONGLONG) bsize)); /* Number of free blocks */
  Store_field(v_s, 3, caml_copy_int64(numberOfFreeClusters));  /* Number of free blocks for
                                                                  unprivileged users */
  Store_field(v_s, 4, caml_copy_int64(LLONG_MAX)); /* Number of inodes */
  Store_field(v_s, 5, caml_copy_int64(LLONG_MAX)); /* Number of free inodes */
  Store_field(v_s, 6, caml_copy_int64(LLONG_MAX)); /* Number of free inodes for
                                                      unprivileged users */
  Store_field(v_s, 7, caml_copy_int64((ULONGLONG) serialNumber)); /* Filesystem ID */
  Store_field(v_s, 8, Val_int(fileSystemFlags));          /* Mount flags (raw) */
  Store_field(v_s, 9, convert_st_flags(fileSystemFlags)); /* Mount flags (decoded) */
  Store_field(v_s, 10, Val_int(MAX_PATH));                /* Maximum filename length */
  CAMLreturn(v_s);
}

#elif (defined(EXTUNIX_HAVE_STATVFS) || defined(EXTUNIX_HAVE_FSTATVFS)) && !defined(_WIN32)

static value convert(struct statvfs* s)
{
  CAMLparam0();
  CAMLlocal1(v_s);

  v_s = caml_alloc(11,0);

  Store_field(v_s,0,Val_int(s->f_bsize));
  /* don't export s->f_frsize */
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

#if defined(EXTUNIX_HAVE_STATVFS)

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

#endif
#if defined(EXTUNIX_HAVE_STATVFS)

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
#endif
