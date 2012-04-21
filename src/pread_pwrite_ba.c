
#define EXTUNIX_WANT_PREAD
#define EXTUNIX_WANT_PWRITE
#include "config.h"

enum mode_bits { BIT_ONCE, BIT_NOERROR, BIT_NOINTR };
#define ONCE (1 << BIT_ONCE)
#define NOERROR (1 << BIT_NOERROR)
#define NOINTR (1 << BIT_NOINTR)

#if defined(EXTUNIX_HAVE_PREAD)

/*  Copyright © 2012 Goswin von Brederlow <goswin-v-b@web.de>   */

#include <errno.h>
#include <string.h>

CAMLprim value caml_extunixba_pread_common(value v_fd, off_t off, value v_buf, int mode) {
    CAMLparam2(v_fd, v_buf);
    ssize_t ret;
    size_t fd = Int_val(v_fd);
    size_t len = Caml_ba_array_val(v_buf)->dim[0];
    size_t processed = 0;
    char *buf = (char*)Caml_ba_data_val(v_buf);

    while(len > 0) {
	caml_enter_blocking_section();
	ret = pread(fd, buf, len, off);
	caml_leave_blocking_section();
	if (ret == 0) break;
	if (ret == -1) {
	    if (errno == EINTR && (mode & NOINTR)) continue;
	    if (processed > 0) {
		if (errno == EAGAIN || errno == EWOULDBLOCK) break;
		if (mode & NOERROR) break;
	    }
	    uerror("pread", Nothing);
	}
	processed += ret;
	buf += ret;
	off += ret;
	len -= ret;
	if (mode & ONCE) break;
    }

    CAMLreturn(Val_long(processed));
}

value caml_extunixba_all_pread(value v_fd, value v_off, value v_buf)
{
    off_t off = Long_val(v_off);
    return caml_extunixba_pread_common(v_fd, off, v_buf, NOINTR);
}

value caml_extunixba_single_pread(value v_fd, value v_off, value v_buf)
{
    off_t off = Long_val(v_off);
    return caml_extunixba_pread_common(v_fd, off, v_buf, ONCE);
}

value caml_extunixba_pread(value v_fd, value v_off, value v_buf)
{
    off_t off = Long_val(v_off);
    return caml_extunixba_pread_common(v_fd, off, v_buf, NOINTR | NOERROR);
}

value caml_extunixba_intr_pread(value v_fd, value v_off, value v_buf)
{
    off_t off = Long_val(v_off);
    return caml_extunixba_pread_common(v_fd, off, v_buf, NOERROR);
}

value caml_extunixba_all_pread64(value v_fd, value v_off, value v_buf)
{
    off_t off = Int64_val(v_off);
    return caml_extunixba_pread_common(v_fd, off, v_buf, NOINTR);
}

value caml_extunixba_single_pread64(value v_fd, value v_off, value v_buf)
{
    off_t off = Int64_val(v_off);
    return caml_extunixba_pread_common(v_fd, off, v_buf, ONCE);
}

value caml_extunixba_pread64(value v_fd, value v_off, value v_buf)
{
    off_t off = Int64_val(v_off);
    return caml_extunixba_pread_common(v_fd, off, v_buf, NOINTR | NOERROR);
}

value caml_extunixba_intr_pread64(value v_fd, value v_off, value v_buf)
{
    off_t off = Int64_val(v_off);
    return caml_extunixba_pread_common(v_fd, off, v_buf, NOERROR);
}
#endif

#if defined(EXTUNIX_HAVE_PWRITE)

/*  Copyright © 2012 Goswin von Brederlow <goswin-v-b@web.de>   */

#include <string.h>

CAMLprim value caml_extunixba_pwrite_common(value v_fd, off_t off, value v_buf, int mode) {
    CAMLparam2(v_fd, v_buf);
    ssize_t ret;
    size_t fd = Int_val(v_fd);
    size_t len = Caml_ba_array_val(v_buf)->dim[0];
    size_t processed = 0;
    char *buf = (char*)Caml_ba_data_val(v_buf);

    while(len > 0) {
	caml_enter_blocking_section();
	ret = pwrite(fd, buf, len, off);
	caml_leave_blocking_section();
	if (ret == 0) break;
	if (ret == -1) {
	    if (errno == EINTR && (mode & NOINTR)) continue;
	    if (processed > 0){
		if (errno == EAGAIN || errno == EWOULDBLOCK) break;
		if (mode & NOERROR) break;
	    }
	    uerror("pwrite", Nothing);
	}
	processed += ret;
	buf += ret;
	off += ret;
	len -= ret;
	if (mode & ONCE) break;
    }

    CAMLreturn(Val_long(processed));
}

value caml_extunixba_all_pwrite(value v_fd, value v_off, value v_buf)
{
    off_t off = Long_val(v_off);
    return caml_extunixba_pwrite_common(v_fd, off, v_buf, NOINTR);
}

value caml_extunixba_single_pwrite(value v_fd, value v_off, value v_buf)
{
    off_t off = Long_val(v_off);
    return caml_extunixba_pwrite_common(v_fd, off, v_buf, ONCE);
}

value caml_extunixba_pwrite(value v_fd, value v_off, value v_buf)
{
    off_t off = Long_val(v_off);
    return caml_extunixba_pwrite_common(v_fd, off, v_buf, NOINTR | NOERROR);
}

value caml_extunixba_intr_pwrite(value v_fd, value v_off, value v_buf)
{
    off_t off = Long_val(v_off);
    return caml_extunixba_pwrite_common(v_fd, off, v_buf, NOERROR);
}

value caml_extunixba_all_pwrite64(value v_fd, value v_off, value v_buf)
{
    off_t off = Int64_val(v_off);
    return caml_extunixba_pwrite_common(v_fd, off, v_buf, NOINTR);
}

value caml_extunixba_single_pwrite64(value v_fd, value v_off, value v_buf)
{
    off_t off = Int64_val(v_off);
    return caml_extunixba_pwrite_common(v_fd, off, v_buf, ONCE);
}

value caml_extunixba_pwrite64(value v_fd, value v_off, value v_buf)
{
    off_t off = Int64_val(v_off);
    return caml_extunixba_pwrite_common(v_fd, off, v_buf, NOINTR | NOERROR);
}

value caml_extunixba_intr_pwrite64(value v_fd, value v_off, value v_buf)
{
    off_t off = Int64_val(v_off);
    return caml_extunixba_pwrite_common(v_fd, off, v_buf, NOERROR);
}
#endif

#if defined(EXTUNIX_HAVE_READ)

/*  Copyright © 2012 Goswin von Brederlow <goswin-v-b@web.de>   */

#include <errno.h>
#include <string.h>

CAMLprim value caml_extunixba_read_common(value v_fd, value v_buf, int mode) {
    CAMLparam2(v_fd, v_buf);
    ssize_t ret;
    size_t fd = Int_val(v_fd);
    size_t len = Caml_ba_array_val(v_buf)->dim[0];
    size_t processed = 0;
    char *buf = (char*)Caml_ba_data_val(v_buf);

    while(len > 0) {
	caml_enter_blocking_section();
	ret = read(fd, buf, len);
	caml_leave_blocking_section();
	if (ret == 0) break;
	if (ret == -1) {
	    if (errno == EINTR && (mode & NOINTR)) continue;
	    if (processed > 0) {
		if (errno == EAGAIN || errno == EWOULDBLOCK) break;
		if (mode & NOERROR) break;
	    }
	    uerror("read", Nothing);
	}
	processed += ret;
	buf += ret;
	len -= ret;
	if (mode & ONCE) break;
    }

    CAMLreturn(Val_long(processed));
}

value caml_extunixba_all_read(value v_fd, value v_buf)
{
    return caml_extunixba_read_common(v_fd, v_buf, NOINTR);
}

value caml_extunixba_single_read(value v_fd, value v_buf)
{
    return caml_extunixba_read_common(v_fd, v_buf, ONCE);
}

value caml_extunixba_read(value v_fd, value v_buf)
{
    return caml_extunixba_read_common(v_fd, v_buf, NOINTR | NOERROR);
}

value caml_extunixba_intr_read(value v_fd, value v_buf)
{
    return caml_extunixba_read_common(v_fd, v_buf, NOERROR);
}
#endif

#if defined(EXTUNIX_HAVE_WRITE)

/*  Copyright © 2012 Goswin von Brederlow <goswin-v-b@web.de>   */

#include <string.h>

CAMLprim value caml_extunixba_write_common(value v_fd, value v_buf, int mode) {
    CAMLparam2(v_fd, v_buf);
    ssize_t ret;
    size_t fd = Int_val(v_fd);
    size_t len = Caml_ba_array_val(v_buf)->dim[0];
    size_t processed = 0;
    char *buf = (char*)Caml_ba_data_val(v_buf);

    while(len > 0) {
	caml_enter_blocking_section();
	ret = write(fd, buf, len);
	caml_leave_blocking_section();
	if (ret == 0) break;
	if (ret == -1) {
	    if (errno == EINTR && (mode & NOINTR)) continue;
	    if (processed > 0){
		if (errno == EAGAIN || errno == EWOULDBLOCK) break;
		if (mode & NOERROR) break;
	    }
	    uerror("write", Nothing);
	}
	processed += ret;
	buf += ret;
	len -= ret;
	if (mode & ONCE) break;
    }

    CAMLreturn(Val_long(processed));
}

value caml_extunixba_all_write(value v_fd, value v_buf)
{
    return caml_extunixba_write_common(v_fd, v_buf, NOINTR);
}

value caml_extunixba_single_write(value v_fd, value v_buf)
{
    return caml_extunixba_write_common(v_fd, v_buf, ONCE);
}

value caml_extunixba_write(value v_fd, value v_buf)
{
    return caml_extunixba_write_common(v_fd, v_buf, NOINTR | NOERROR);
}

value caml_extunixba_intr_write(value v_fd, value v_buf)
{
    return caml_extunixba_write_common(v_fd, v_buf, NOERROR);
}
#endif

