
#define EXTUNIX_WANT_MOUNT
#include "config.h"

#if defined(EXTUNIX_HAVE_MOUNT)

static int mountflags_table[] = {
  MS_RDONLY, MS_NOSUID, MS_NODEV, MS_NOEXEC, MS_SYNCHRONOUS, MS_REMOUNT,
  MS_MANDLOCK, MS_DIRSYNC, MS_NOATIME, MS_NODIRATIME, MS_BIND, MS_MOVE,
  MS_REC, MS_SILENT, MS_POSIXACL, MS_UNBINDABLE, MS_PRIVATE, MS_SLAVE,
  MS_SHARED, MS_RELATIME, MS_KERNMOUNT, MS_I_VERSION, MS_STRICTATIME,
  MS_NOUSER
};

CAMLprim value caml_extunix_mount(value v_source, value v_target,
                                  value v_fstype, value v_mountflags,
                                  value v_data)
{
  CAMLparam5(v_source, v_target, v_fstype, v_mountflags, v_data);
  int ret;
  char* p_source = strdup(String_val(v_source));
  char* p_target = strdup(String_val(v_target));
  char* p_fstype = strdup(String_val(v_fstype));
  char* p_data   = strdup(String_val(v_data));

  int p_mountflags = caml_convert_flag_list(v_mountflags, mountflags_table);

  caml_enter_blocking_section();
  ret = mount(p_source, p_target, p_fstype, p_mountflags, p_data);
  caml_leave_blocking_section();

  free(p_source);
  free(p_target);
  free(p_fstype);
  free(p_data);

  if (ret != 0) uerror("mount", v_target);
  CAMLreturn(Val_unit);
}

static int umountflags_table[] = {
  MNT_FORCE, MNT_DETACH, MNT_EXPIRE, UMOUNT_NOFOLLOW,
};

CAMLprim value caml_extunix_umount2(value v_target,value v_umountflags)
{
  CAMLparam2(v_target, v_umountflags);
  int ret;
  char* p_target = strdup(String_val(v_target));

  int p_umountflags = caml_convert_flag_list(v_umountflags, umountflags_table);

  caml_enter_blocking_section();
  ret = umount2(p_target, p_umountflags);
  caml_leave_blocking_section();

  free(p_target);

  if (ret != 0) uerror("umount", v_target);
  CAMLreturn(Val_unit);
}


#endif

