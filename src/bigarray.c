#include "config.h"

/*  Copyright © 2012 Goswin von Brederlow <goswin-v-b@web.de>   */

CAMLprim value caml_extunixba_get_substr(value v_buf, value v_off, value v_len)
{
    CAMLparam3(v_buf, v_off, v_len);
    CAMLlocal1(v_str);
    char *buf = (char*)Caml_ba_data_val(v_buf);
    size_t off = Long_val(v_off);
    size_t len = Long_val(v_len);
    char *str;
    v_str = caml_alloc_string(len);
    str = String_val(v_str);
    memcpy(str, buf + off, len);
    CAMLreturn(v_str);
}

CAMLprim value caml_extunixba_set_substr(value v_buf, value v_off, value v_str)
{
    CAMLparam3(v_buf, v_off, v_str);
    char *buf = (char*)Caml_ba_data_val(v_buf);
    size_t off = Long_val(v_off);
    size_t len = caml_string_length(v_str);
    char *str = String_val(v_str);
    memcpy(buf + off, str, len);
    CAMLreturn(Val_unit);
}
