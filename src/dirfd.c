
#define WANT_DIRFD
#include "config.h"

#include <errno.h>

#if defined(HAVE_DIRFD)

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

#endif

