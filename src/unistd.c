#define EXTUNIX_WANT_TTYNAME
#define EXTUNIX_WANT_CTERMID
#define EXTUNIX_WANT_PGID
#define EXTUNIX_WANT_SETREUID
#define EXTUNIX_WANT_SETRESUID
#define EXTUNIX_WANT_FCNTL
#define EXTUNIX_WANT_TCPGRP
#define EXTUNIX_WANT_PREAD
#define EXTUNIX_WANT_PWRITE
#define EXTUNIX_WANT_READ
#define EXTUNIX_WANT_WRITE
#define EXTUNIX_WANT_GETTID
#define EXTUNIX_WANT_CHROOT
#include "config.h"

#if defined(EXTUNIX_HAVE_TTYNAME)

/*  Copyright © 2010 Stéphane Glondu <steph@glondu.net>                   */

CAMLprim value caml_extunix_ttyname(value v_fd)
{
  CAMLparam1(v_fd);
  char *r = ttyname(Int_val(v_fd));
  if (r) {
    CAMLreturn(caml_copy_string(r));
  } else {
    caml_uerror("ttyname", Nothing);
  }
}

#endif

#if defined(EXTUNIX_HAVE_CTERMID)

CAMLprim value caml_extunix_ctermid(value v_unit)
{
  char buf[L_ctermid + 1];
  UNUSED(v_unit);
  return caml_copy_string(ctermid(buf));
}

#endif

#if defined(EXTUNIX_HAVE_GETTID)

CAMLprim value caml_extunix_gettid(value v_unit)
{
  UNUSED(v_unit);
#if defined(_WIN32)
  DWORD tid = 0;
  tid = GetCurrentThreadId();
#elif defined(EXTUNIX_USE_THREADID)
  uint64_t tid = 0;
  pthread_threadid_np(NULL, &tid);
#elif defined(EXTUNIX_USE_THREAD_SELFID)
  pid_t tid = 0;
  tid = syscall(SYS_thread_selfid);
#else
  pid_t tid = 0;
  tid = syscall(SYS_gettid);
#endif
  return Val_int((int)tid); /* XXX truncating to int */
}

#endif

#if defined(EXTUNIX_HAVE_PGID)

CAMLprim value caml_extunix_setpgid(value v_pid, value v_pgid)
{
  CAMLparam2(v_pid, v_pgid);
  if (0 != setpgid(Int_val(v_pid), Int_val(v_pgid)))
    caml_uerror("setpgid",Nothing);
  CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_getpgid(value v_pid)
{
  CAMLparam1(v_pid);
  int pgid = getpgid(Int_val(v_pid));
  if (pgid < 0)
    caml_uerror("getpgid",Nothing);
  CAMLreturn(Val_int(pgid));
}

CAMLprim value caml_extunix_getsid(value v_pid)
{
  CAMLparam1(v_pid);
  int sid = getsid(Int_val(v_pid));
  if (sid < 0)
    caml_uerror("getsid",Nothing);
  CAMLreturn(Val_int(sid));
}

#endif

#if defined(EXTUNIX_HAVE_SETREUID)

CAMLprim value caml_extunix_setreuid(value v_ruid, value v_euid)
{
  CAMLparam2(v_ruid,v_euid);
  int r = setreuid(Int_val(v_ruid), Int_val(v_euid));
  if (r < 0)
    caml_uerror("setreuid", Nothing);
  CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_setregid(value v_rgid, value v_egid)
{
  CAMLparam2(v_rgid,v_egid);
  int r = setregid(Int_val(v_rgid), Int_val(v_egid));
  if (r < 0)
    caml_uerror("setregid", Nothing);
  CAMLreturn(Val_unit);
}

#endif

#if defined(EXTUNIX_HAVE_SETRESUID)

CAMLprim value caml_extunix_setresuid(value r, value e, value s)
{
  CAMLparam3(r, e, s);
  uid_t ruid = Int_val(r);
  uid_t euid = Int_val(e);
  uid_t suid = Int_val(s);

  if (setresuid(ruid, euid, suid) != 0)
    caml_uerror("setresuid", Nothing);
  CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_setresgid(value r, value e, value s)
{
  CAMLparam3(r, e, s);
  gid_t rgid = Int_val(r);
  gid_t egid = Int_val(e);
  gid_t sgid = Int_val(s);

  if (setresgid(rgid, egid, sgid) == -1)
    caml_uerror("setresgid", Nothing);
  CAMLreturn(Val_unit);
}

#endif /* EXTUNIX_HAVE_SETRESUID */

#if defined(EXTUNIX_HAVE_FCNTL)

CAMLprim value caml_extunix_is_open_descr(value v_fd)
{
    int r = fcntl(Int_val(v_fd), F_GETFL);
    if (-1 == r)
    {
        if (EBADF == errno) return Val_false;
        caml_uerror("fcntl", Nothing);
    };
    return Val_true;
}

#endif

#if defined(EXTUNIX_HAVE_TCPGRP)

CAMLprim value caml_extunix_tcgetpgrp(value v_fd)
{
    int pgid = tcgetpgrp(Int_val(v_fd));
    if (-1 == pgid)
      caml_uerror("tcgetpgrp", Nothing);
    return Val_int(pgid);
}

CAMLprim value caml_extunix_tcsetpgrp(value v_fd, value v_pgid)
{
    int r = tcsetpgrp(Int_val(v_fd), Int_val(v_pgid));
    if (-1 == r)
      caml_uerror("tcsetpgrp", Nothing);
    return Val_int(r);
}

#endif

enum mode_bits {
    BIT_ONCE = 1 << 0,
    BIT_NOERROR = 1 << 1,
    BIT_NOINTR = 1 << 2
};

#if defined(EXTUNIX_HAVE_PREAD)

/*  Copyright © 2012 Goswin von Brederlow <goswin-v-b@web.de>   */

CAMLprim value caml_extunix_pread_common(value v_fd, off_t off, value v_buf, value v_ofs, value v_len, int mode) {
    CAMLparam4(v_fd, v_buf, v_ofs, v_len);
    ssize_t ret;
    size_t fd = Int_val(v_fd);
    size_t ofs = Long_val(v_ofs);
    size_t len = Long_val(v_len);
    size_t processed = 0;
    char iobuf[UNIX_BUFFER_SIZE];

    while(len > 0) {
	size_t numbytes = (len > UNIX_BUFFER_SIZE) ? UNIX_BUFFER_SIZE : len;
	caml_enter_blocking_section();
	ret = pread(fd, iobuf, numbytes, off);
	caml_leave_blocking_section();
	if (ret == 0) break;
	if (ret == -1) {
	    if (errno == EINTR && (mode & BIT_NOINTR)) continue;
	    if (processed > 0) {
		if (errno == EAGAIN || errno == EWOULDBLOCK) break;
		if (mode & BIT_NOERROR) break;
	    }
	    caml_uerror("pread", Nothing);
	}
	memcpy(&Byte(v_buf, ofs), iobuf, ret);
	processed += ret;
	off += ret;
	ofs += ret;
	len -= ret;
	if (mode & BIT_ONCE) break;
    }

    CAMLreturn(Val_long(processed));
}

value caml_extunix_all_pread(value v_fd, value v_off, value v_buf, value v_ofs, value v_len)
{
    off_t off = Long_val(v_off);
    return caml_extunix_pread_common(v_fd, off, v_buf, v_ofs, v_len, BIT_NOINTR);
}

value caml_extunix_single_pread(value v_fd, value v_off, value v_buf, value v_ofs, value v_len)
{
    off_t off = Long_val(v_off);
    return caml_extunix_pread_common(v_fd, off, v_buf, v_ofs, v_len, BIT_ONCE);
}

value caml_extunix_pread(value v_fd, value v_off, value v_buf, value v_ofs, value v_len)
{
    off_t off = Long_val(v_off);
    return caml_extunix_pread_common(v_fd, off, v_buf, v_ofs, v_len, BIT_NOINTR | BIT_NOERROR);
}

value caml_extunix_intr_pread(value v_fd, value v_off, value v_buf, value v_ofs, value v_len)
{
    off_t off = Long_val(v_off);
    return caml_extunix_pread_common(v_fd, off, v_buf, v_ofs, v_len, BIT_NOERROR);
}

value caml_extunix_all_pread64(value v_fd, value v_off, value v_buf, value v_ofs, value v_len)
{
    off_t off = Int64_val(v_off);
    return caml_extunix_pread_common(v_fd, off, v_buf, v_ofs, v_len, BIT_NOINTR);
}

value caml_extunix_single_pread64(value v_fd, value v_off, value v_buf, value v_ofs, value v_len)
{
    off_t off = Int64_val(v_off);
    return caml_extunix_pread_common(v_fd, off, v_buf, v_ofs, v_len, BIT_ONCE);
}

value caml_extunix_pread64(value v_fd, value v_off, value v_buf, value v_ofs, value v_len)
{
    off_t off = Int64_val(v_off);
    return caml_extunix_pread_common(v_fd, off, v_buf, v_ofs, v_len, BIT_NOINTR | BIT_NOERROR);
}

value caml_extunix_intr_pread64(value v_fd, value v_off, value v_buf, value v_ofs, value v_len)
{
    off_t off = Int64_val(v_off);
    return caml_extunix_pread_common(v_fd, off, v_buf, v_ofs, v_len, BIT_NOERROR);
}
#endif

#if defined(EXTUNIX_HAVE_PWRITE)

/*  Copyright © 2012 Goswin von Brederlow <goswin-v-b@web.de>   */

CAMLprim value caml_extunix_pwrite_common(value v_fd, off_t off, value v_buf, value v_ofs, value v_len, int mode) {
    CAMLparam4(v_fd, v_buf, v_ofs, v_len);
    ssize_t ret;
    size_t fd = Int_val(v_fd);
    size_t ofs = Long_val(v_ofs);
    size_t len = Long_val(v_len);
    size_t processed = 0;
    char iobuf[UNIX_BUFFER_SIZE];

    while(len > 0) {
	size_t numbytes = (len > UNIX_BUFFER_SIZE) ? UNIX_BUFFER_SIZE : len;
	memcpy(iobuf, &Byte(v_buf, ofs), numbytes);
	caml_enter_blocking_section();
	ret = pwrite(fd, iobuf, numbytes, off);
	caml_leave_blocking_section();
	if (ret == 0) break;
	if (ret == -1) {
	    if (errno == EINTR && (mode & BIT_NOINTR)) continue;
	    if (processed > 0){
		if (errno == EAGAIN || errno == EWOULDBLOCK) break;
		if (mode & BIT_NOERROR) break;
	    }
	    caml_uerror("pwrite", Nothing);
	}
	processed += ret;
	off += ret;
	ofs += ret;
	len -= ret;
	if (mode & BIT_ONCE) break;
    }

    CAMLreturn(Val_long(processed));
}

value caml_extunix_all_pwrite(value v_fd, value v_off, value v_buf, value v_ofs, value v_len)
{
    off_t off = Long_val(v_off);
    return caml_extunix_pwrite_common(v_fd, off, v_buf, v_ofs, v_len, BIT_NOINTR);
}

value caml_extunix_single_pwrite(value v_fd, value v_off, value v_buf, value v_ofs, value v_len)
{
    off_t off = Long_val(v_off);
    return caml_extunix_pwrite_common(v_fd, off, v_buf, v_ofs, v_len, BIT_ONCE);
}

value caml_extunix_pwrite(value v_fd, value v_off, value v_buf, value v_ofs, value v_len)
{
    off_t off = Long_val(v_off);
    return caml_extunix_pwrite_common(v_fd, off, v_buf, v_ofs, v_len, BIT_NOINTR | BIT_NOERROR);
}

value caml_extunix_intr_pwrite(value v_fd, value v_off, value v_buf, value v_ofs, value v_len)
{
    off_t off = Long_val(v_off);
    return caml_extunix_pwrite_common(v_fd, off, v_buf, v_ofs, v_len, BIT_NOERROR);
}

value caml_extunix_all_pwrite64(value v_fd, value v_off, value v_buf, value v_ofs, value v_len)
{
    off_t off = Int64_val(v_off);
    return caml_extunix_pwrite_common(v_fd, off, v_buf, v_ofs, v_len, BIT_NOINTR);
}

value caml_extunix_single_pwrite64(value v_fd, value v_off, value v_buf, value v_ofs, value v_len)
{
    off_t off = Int64_val(v_off);
    return caml_extunix_pwrite_common(v_fd, off, v_buf, v_ofs, v_len, BIT_ONCE);
}

value caml_extunix_pwrite64(value v_fd, value v_off, value v_buf, value v_ofs, value v_len)
{
    off_t off = Int64_val(v_off);
    return caml_extunix_pwrite_common(v_fd, off, v_buf, v_ofs, v_len, BIT_NOINTR | BIT_NOERROR);
}

value caml_extunix_intr_pwrite64(value v_fd, value v_off, value v_buf, value v_ofs, value v_len)
{
    off_t off = Int64_val(v_off);
    return caml_extunix_pwrite_common(v_fd, off, v_buf, v_ofs, v_len, BIT_NOERROR);
}
#endif

#if defined(EXTUNIX_HAVE_READ)

/*  Copyright © 2012 Goswin von Brederlow <goswin-v-b@web.de>   */

CAMLprim value caml_extunix_read_common(value v_fd, value v_buf, value v_ofs, value v_len, int mode) {
    CAMLparam4(v_fd, v_buf, v_ofs, v_len);
    ssize_t ret;
    size_t fd = Int_val(v_fd);
    size_t ofs = Long_val(v_ofs);
    size_t len = Long_val(v_len);
    size_t processed = 0;
    char iobuf[UNIX_BUFFER_SIZE];

    while(len > 0) {
	size_t numbytes = (len > UNIX_BUFFER_SIZE) ? UNIX_BUFFER_SIZE : len;
	caml_enter_blocking_section();
	ret = read(fd, iobuf, numbytes);
	caml_leave_blocking_section();
	if (ret == 0) break;
	if (ret == -1) {
	    if (errno == EINTR && (mode & BIT_NOINTR)) continue;
	    if (processed > 0) {
		if (errno == EAGAIN || errno == EWOULDBLOCK) break;
		if (mode & BIT_NOERROR) break;
	    }
	    caml_uerror("read", Nothing);
	}
	memcpy(&Byte(v_buf, ofs), iobuf, ret);
	processed += ret;
	ofs += ret;
	len -= ret;
	if (mode & BIT_ONCE) break;
    }

    CAMLreturn(Val_long(processed));
}

value caml_extunix_all_read(value v_fd, value v_buf, value v_ofs, value v_len)
{
    return caml_extunix_read_common(v_fd, v_buf, v_ofs, v_len, BIT_NOINTR);
}

value caml_extunix_single_read(value v_fd, value v_buf, value v_ofs, value v_len)
{
    return caml_extunix_read_common(v_fd, v_buf, v_ofs, v_len, BIT_ONCE);
}

value caml_extunix_read(value v_fd, value v_buf, value v_ofs, value v_len)
{
    return caml_extunix_read_common(v_fd, v_buf, v_ofs, v_len, BIT_NOINTR | BIT_NOERROR);
}

value caml_extunix_intr_read(value v_fd, value v_buf, value v_ofs, value v_len)
{
    return caml_extunix_read_common(v_fd, v_buf, v_ofs, v_len, BIT_NOERROR);
}
#endif

#if defined(EXTUNIX_HAVE_WRITE)

/*  Copyright © 2012 Goswin von Brederlow <goswin-v-b@web.de>   */

CAMLprim value caml_extunix_write_common(value v_fd, value v_buf, value v_ofs, value v_len, int mode) {
    CAMLparam4(v_fd, v_buf, v_ofs, v_len);
    ssize_t ret;
    size_t fd = Int_val(v_fd);
    size_t ofs = Long_val(v_ofs);
    size_t len = Long_val(v_len);
    size_t processed = 0;
    char iobuf[UNIX_BUFFER_SIZE];

    while(len > 0) {
	size_t numbytes = (len > UNIX_BUFFER_SIZE) ? UNIX_BUFFER_SIZE : len;
	memcpy(iobuf, &Byte(v_buf, ofs), numbytes);
	caml_enter_blocking_section();
	ret = write(fd, iobuf, numbytes);
	caml_leave_blocking_section();
	if (ret == 0) break;
	if (ret == -1) {
	    if (errno == EINTR && (mode & BIT_NOINTR)) continue;
	    if (processed > 0){
		if (errno == EAGAIN || errno == EWOULDBLOCK) break;
		if (mode & BIT_NOERROR) break;
	    }
	    caml_uerror("write", Nothing);
	}
	processed += ret;
	ofs += ret;
	len -= ret;
	if (mode & BIT_ONCE) break;
    }

    CAMLreturn(Val_long(processed));
}

value caml_extunix_all_write(value v_fd, value v_buf, value v_ofs, value v_len)
{
    return caml_extunix_write_common(v_fd, v_buf, v_ofs, v_len, BIT_NOINTR);
}

value caml_extunix_single_write(value v_fd, value v_buf, value v_ofs, value v_len)
{
    return caml_extunix_write_common(v_fd, v_buf, v_ofs, v_len, BIT_ONCE);
}

value caml_extunix_write(value v_fd, value v_buf, value v_ofs, value v_len)
{
    return caml_extunix_write_common(v_fd, v_buf, v_ofs, v_len, BIT_NOINTR | BIT_NOERROR);
}

value caml_extunix_intr_write(value v_fd, value v_buf, value v_ofs, value v_len)
{
    return caml_extunix_write_common(v_fd, v_buf, v_ofs, v_len, BIT_NOERROR);
}
#endif

#if defined(EXTUNIX_HAVE_CHROOT)

CAMLprim value caml_extunix_chroot(value v_path)
{
  CAMLparam1(v_path);
  int ret;
  char* p_path = caml_stat_strdup(String_val(v_path));

  caml_enter_blocking_section();
  ret = chroot(p_path);
  caml_leave_blocking_section();

  caml_stat_free(p_path);

  if (ret != 0) caml_uerror("chroot", v_path);
  CAMLreturn(Val_unit);
}

#endif
