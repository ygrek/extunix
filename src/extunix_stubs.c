
#include <caml/memory.h>
#include <caml/fail.h>
#include <caml/unixsupport.h>
#include <caml/signals.h>
#include <caml/alloc.h>
#include <assert.h>

#define HAVE_EVENTFD

#if defined(_MSC_VER)

CAMLprim value caml_extunix_fsync(value v)
{
   CAMLparam1(v);
   HANDLE h = INVALID_HANDLE_VALUE;
   int r = 0;
   if (KIND_HANDLE != Descr_kind_val(v))
     caml_invalid_argument("fsync");
   h = Handle_val(v);
   caml_enter_blocking_section();
   r = FlushFileBuffers(h);
   caml_leave_blocking_section();
   if (0 == r)
     uerror("fsync",Nothing);
   CAMLreturn(Val_unit); 
}

#else

#include <unistd.h>

CAMLprim value caml_extunix_fsync(value v_fd)
{
    CAMLparam1(v_fd);
    int r = 0;
    assert(Is_long(v_fd));
    caml_enter_blocking_section();
    r = fsync(Int_val(v_fd));
    caml_leave_blocking_section();
    if (0 != r)
      uerror("fsync",Nothing);
    CAMLreturn(Val_unit);
}

#endif

#if defined(HAVE_EVENTFD)

#include <sys/eventfd.h>

CAMLprim value caml_extunix_eventfd(value v_init)
{
  CAMLparam1(v_init);
  int fd = eventfd(Int_val(v_init), 0);
  if (-1 == fd) uerror("eventfd",Nothing);
  CAMLreturn(Val_int(fd));
}

CAMLprim value caml_extunix_eventfd_read(value v_fd)
{
  CAMLparam1(v_fd);
  eventfd_t v;
  if (-1 == eventfd_read(Int_val(v_fd), &v)) 
    uerror("eventfd_read",Nothing);
  CAMLreturn(caml_copy_int64(v));
}

CAMLprim value caml_extunix_eventfd_write(value v_fd, value v_val)
{
  CAMLparam2(v_fd, v_val);
  if (-1 == eventfd_write(Int_val(v_fd), Int64_val(v_val))) 
    uerror("eventfd_read",Nothing);
  CAMLreturn(Val_unit);
}

#else

CAMLprim value caml_extunix_eventfd(value v_init)
{
  caml_invalid_argument("eventfd not implemented");
}

CAMLprim value caml_extunix_eventfd_read(value v_fd)
{
  caml_invalid_argument("eventfd_read not implemented");
}

CAMLprim value caml_extunix_eventfd_write(value v_fd, value v_val)
{
  caml_invalid_argument("eventfd_write not implemented");
}

#endif

#if defined(HAVE_ATFILE)

#include <dirent.h>

CAMLprim value caml_extunix_dirfd(value v_dir)
{
  CAMLparam1(v_dir);
  int fd = -1;
  DIR* dir = DIR_Val(v_dir);
  if (dir == (DIR *) NULL) unix_error(EBADF, "dirfd", Nothing);
  fd = dirfd(dir);
  if (fd < 0) uerror("dirfd", Nothing);
  CAMLreturn(Val_int(fd));
}

#else

CAMLprim value caml_extunix_dirfd(value v_dir)
{
  caml_invalid_argument("dirfd not implemented");
}

#endif

#if defined(HAVE_STATVFS)

#include <sys/statvfs.h>

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

#else

CAMLprim value caml_extunix_statvfs(value v_path)
{
  caml_invalid_argument("statvfs not implemented");
}

#endif

