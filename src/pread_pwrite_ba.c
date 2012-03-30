
#define EXTUNIX_WANT_PREAD
#define EXTUNIX_WANT_PWRITE
#include "config.h"

#if defined(EXTUNIX_HAVE_PREAD)

/*  Copyright © 2012 Goswin von Brederlow <goswin-v-b@web.de>   */

#include <errno.h>
#include <string.h>

CAMLprim value caml_extunixba_pread_common(value v_fd, off_t off, value v_buf, int once) {
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
	    if ((errno == EAGAIN || errno == EWOULDBLOCK) && processed > 0) break;
	    uerror("pread", Nothing);
	}
	processed += ret;
	buf += ret;
	off += ret;
	len -= ret;
	if (once) break;
    }

    CAMLreturn(Val_long(processed));
}

value caml_extunixba_pread(value v_fd, value v_off, value v_buf)
{
    off_t off = Long_val(v_off);
    return caml_extunixba_pread_common(v_fd, off, v_buf, 0);
}

value caml_extunixba_single_pread(value v_fd, value v_off, value v_buf)
{
    off_t off = Long_val(v_off);
    return caml_extunixba_pread_common(v_fd, off, v_buf, 1);
}

value caml_extunixba_pread64(value v_fd, value v_off, value v_buf)
{
    off_t off = Int64_val(v_off);
    return caml_extunixba_pread_common(v_fd, off, v_buf, 0);
}

value caml_extunixba_single_pread64(value v_fd, value v_off, value v_buf)
{
    off_t off = Int64_val(v_off);
    return caml_extunixba_pread_common(v_fd, off, v_buf, 1);
}
#endif

#if defined(EXTUNIX_HAVE_PWRITE)

/*  Copyright © 2012 Goswin von Brederlow <goswin-v-b@web.de>   */

#include <string.h>

CAMLprim value caml_extunixba_pwrite_common(value v_fd, off_t off, value v_buf, int once) {
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
	    if ((errno == EAGAIN || errno == EWOULDBLOCK) && processed > 0) break;
	    uerror("pwrite", Nothing);
	}
	processed += ret;
	buf += ret;
	off += ret;
	len -= ret;
	if (once) break;
    }

    CAMLreturn(Val_long(processed));
}

value caml_extunixba_pwrite(value v_fd, value v_off, value v_buf)
{
    off_t off = Long_val(v_off);
    return caml_extunixba_pwrite_common(v_fd, off, v_buf, 0);
}

value caml_extunixba_single_pwrite(value v_fd, value v_off, value v_buf)
{
    off_t off = Long_val(v_off);
    return caml_extunixba_pwrite_common(v_fd, off, v_buf, 1);
}

value caml_extunixba_pwrite64(value v_fd, value v_off, value v_buf)
{
    off_t off = Int64_val(v_off);
    return caml_extunixba_pwrite_common(v_fd, off, v_buf, 0);
}

value caml_extunixba_single_pwrite64(value v_fd, value v_off, value v_buf)
{
    off_t off = Int64_val(v_off);
    return caml_extunixba_pwrite_common(v_fd, off, v_buf, 1);
}
#endif

