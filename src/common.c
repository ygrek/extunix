
#include "config.h"
#include <fcntl.h>

/* otherlibs/unix/open.c */

#ifndef O_NONBLOCK
#define O_NONBLOCK O_NDELAY
#endif
#ifndef O_DSYNC
#define O_DSYNC 0
#endif
#ifndef O_SYNC
#define O_SYNC 0
#endif
#ifndef O_RSYNC
#define O_RSYNC 0
#endif
#ifndef O_CLOEXEC
#define O_CLOEXEC 0
#endif

static int open_flag_table[] = {
  O_RDONLY, O_WRONLY, O_RDWR, O_NONBLOCK, O_APPEND, O_CREAT, O_TRUNC, O_EXCL,
  O_NOCTTY, O_DSYNC, O_SYNC, O_RSYNC, 0 /* O_SHARE_DELETE */, O_CLOEXEC,
};

int extunix_open_flags(value v_flags)
{
  return caml_convert_flag_list(v_flags, open_flag_table);
}
