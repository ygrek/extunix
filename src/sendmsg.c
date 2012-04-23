#define EXTUNIX_WANT_SENDMSG

#include "config.h"

#if defined(EXTUNIX_HAVE_SENDMSG)

/*  Copyright © 2012 Andre Nathan <andre@digirati.com.br>   */

/*
 * These functions are adapted from Stevens, Fenner and Rudoff, UNIX Network
 * Programming, Volume 1, Third Edition. We use CMSG_LEN instead of CMSG_SPACE
 * for the msg_controllen field of struct msghdr to avoid breaking LP64
 * systems (cf. Postfix source code).
 */

#define Val_none Val_int(0)
#define Some_val(v) Field(v,0)

CAMLprim value caml_extunix_sendmsg(value fd_val, value sendfd_val, value data_val)
{
  CAMLparam3(fd_val, sendfd_val, data_val);
  CAMLlocal1(data);
  size_t datalen;
  struct msghdr msg;
  struct iovec iov[1];
  int fd = Int_val(fd_val);
  ssize_t ret;
  char *buf;

  memset(&msg, 0, sizeof msg);

  if (sendfd_val != Val_none) {
    int sendfd = Int_val(Some_val(sendfd_val));
#if defined(CMSG_SPACE) && !defined(NO_MSGHDR_MSG_CONTROL)
    union {
      struct cmsghdr cmsg; /* for alignment */
      char control[CMSG_SPACE(sizeof sendfd)];
    } control_un;
    struct cmsghdr *cmsgp;

    msg.msg_control = control_un.control;
    msg.msg_controllen = CMSG_LEN(sizeof sendfd);

    cmsgp = CMSG_FIRSTHDR(&msg);
    cmsgp->cmsg_len = CMSG_LEN(sizeof sendfd);
    cmsgp->cmsg_level = SOL_SOCKET;
    cmsgp->cmsg_type = SCM_RIGHTS;
    *(int *)CMSG_DATA(cmsgp) = sendfd;
#else
    msg.msg_accrights = (caddr_t)&sendfd;
    msg.msg_accrightslen = sizeof sendfd;
#endif
  }

  datalen = caml_string_length(data_val);
  buf = malloc(datalen+1);
  memcpy(buf, String_val(data_val), datalen);
  buf[datalen] = '\0';

  iov[0].iov_base = buf;
  iov[0].iov_len = strlen(buf);
  msg.msg_iov = iov;
  msg.msg_iovlen = 1;

  caml_enter_blocking_section();
  ret = sendmsg(fd, &msg, 0);
  caml_leave_blocking_section();

  free(buf);

  if (ret == -1)
    uerror("sendmsg", Nothing);
  CAMLreturn (Val_unit);
}

CAMLprim value caml_extunix_recvmsg(value fd_val)
{
  CAMLparam1(fd_val);
  CAMLlocal2(data, res);
  struct msghdr msg;
  int fd = Int_val(fd_val);
  int recvfd;
  ssize_t len;
  struct iovec iov[1];
  char buf[4096];

#if defined(CMSG_SPACE) && !defined(NO_MSGHDR_MSG_CONTROL)
  union {
    struct cmsghdr cmsg; /* just for alignment */
    char control[CMSG_SPACE(sizeof recvfd)];
  } control_un;
  struct cmsghdr *cmsgp;

  memset(&msg, 0, sizeof msg);
  msg.msg_control = control_un.control;
  msg.msg_controllen = CMSG_LEN(sizeof recvfd);
#else
  msg.msg_accrights = (caddr_t)&recvfd;
  msg.msg_accrightslen = sizeof recvfd;
#endif

  iov[0].iov_base = buf;
  iov[0].iov_len = sizeof buf;
  msg.msg_iov = iov;
  msg.msg_iovlen = 1;

  caml_enter_blocking_section();
  len = recvmsg(fd, &msg, 0);
  caml_leave_blocking_section();

  if (len == -1)
    uerror("recvmsg", Nothing);

  res = caml_alloc(2, 0);

#if defined(CMSG_SPACE) && !defined(NO_MSGHDR_MSG_CONTROL)
  cmsgp = CMSG_FIRSTHDR(&msg);
  if (cmsgp == NULL) {
    Store_field(res, 0, Val_none);
  } else {
    CAMLlocal1(some_fd); 
    if (cmsgp->cmsg_len != CMSG_LEN(sizeof recvfd))
      unix_error(EINVAL, "recvmsg", caml_copy_string("wrong descriptor size"));
    if (cmsgp->cmsg_level != SOL_SOCKET || cmsgp->cmsg_type != SCM_RIGHTS)
      unix_error(EINVAL, "recvmsg", caml_copy_string("invalid protocol"));
    some_fd = caml_alloc(1, 0);
    Store_field(some_fd, 0, Val_int(*(int *)CMSG_DATA(cmsgp)));
    Store_field(res, 0, some_fd);
  }
#else
  if (msg.msg_accrightslen != sizeof recvfd) {
    Store_field(res, 0, Val_none);
  } else {
    CAMLlocal1(some_fd);
    some_fd = caml_alloc(1, 0);
    Store_field(some_fd, 0, Val_int(recvfd));
    Store_field(res, 0, some_fd);
  }
#endif

  buf[len] = '\0';
  Store_field(res, 1, caml_copy_string(buf));

  CAMLreturn (res);
}

#endif /* EXTUNIX_HAVE_SENDMSG */
