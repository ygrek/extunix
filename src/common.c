#include "config.h"
#include <fcntl.h>

/* otherlibs/unix/open.c */

#ifndef O_NONBLOCK
#ifndef O_NDELAY
#define O_NDELAY 0
#endif
#define O_NONBLOCK O_NDELAY
#endif
#ifndef O_NOCTTY
#define O_NOCTTY 0
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
#ifndef O_KEEPEXEC
#define O_KEEPEXEC 0
#endif

static const int open_flag_table[] = {
  O_RDONLY, O_WRONLY, O_RDWR, O_NONBLOCK, O_APPEND, O_CREAT, O_TRUNC, O_EXCL,
  O_NOCTTY, O_DSYNC, O_SYNC, O_RSYNC, 0 /* O_SHARE_DELETE */, O_CLOEXEC, O_KEEPEXEC,
};

int extunix_open_flags(value list)
{
  int res;
  int flag;
  res = 0;
  while (list != Val_int(0))
  {
    flag = Int_val(Field(list, 0));
    if (flag >= 0 && (size_t)flag < sizeof(open_flag_table)/sizeof(open_flag_table[0])) /* new flags - ignore */
      res |= open_flag_table[flag];
    list = Field(list, 1);
  }
  return res;
}
