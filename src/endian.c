#define EXTUNIX_WANT_ENDIAN
#include "config.h"

#include <stdint.h>
#include <string.h> /* for memcpy */

/*  Copyright © 2012 Goswin von Brederlow <goswin-v-b@web.de>   */

/* Convert an intX_t from one endianness to another */
#define CONV(name, type, conv, type_val, val_type)	\
CAMLprim value caml_extunix_##name(value v_x)		\ 
{							\
  CAMLparam1(v_x);					\
  type x = type_val(v_x);				\
  x = conv(x);						\
  CAMLreturn(val_type(x));				\
}

/* Get an intX_t out of a string */
#define GET(name, type, conv, Val_type)					\
CAMLprim value caml_extunix_get_##name(value v_str, value v_off) {	\
  CAMLparam2(v_str, v_off);						\
  char *str = String_val(v_str);					\
  size_t off = Long_val(v_off);						\
  type x;								\
  memcpy(&x, str + off, sizeof(x));					\
  x = conv(x);								\
  CAMLreturn(Val_type(x));							\
}

/* Store an intX_t in a string */
#define SET(name, type, conv, Type_val)					\
CAMLprim value caml_extunix_set_##name(value v_str, value v_off, value v_x) { \
  CAMLparam3(v_str, v_off, v_x);					\
  char *str = String_val(v_str);					\
  size_t off = Long_val(v_off);						\
  type x = Type_val(v_x);						\
  x = conv(x);								\
  memcpy(str + off, &x, sizeof(x));					\
  CAMLreturn(Val_unit);							\
}

#if defined(EXTUNIX_HAVE_ENDIAN)

#include <endian.h>
#include <arpa/inet.h>

/* Big endian */
CONV(htobe16,        uint16_t, htobe16, Long_val, Val_long)
CONV(htobe16_signed,  int16_t, htobe16, Long_val, Val_long)
CONV(be16toh,        uint16_t, be16toh, Long_val, Val_long)
CONV(be16toh_signed,  int16_t, be16toh, Long_val, Val_long)
CONV(htobe31,        uint32_t, htobe32, Long_val, Val_long)
CONV(htobe31_signed,  int32_t, htobe32, Long_val, Val_long)
CONV(be31toh,        uint32_t, be32toh, Long_val, Val_long)
CONV(be31toh_signed,  int32_t, be32toh, Long_val, Val_long)
CONV(htobe32,         int32_t, htobe32, Int32_val, caml_copy_int32)
CONV(be32toh,         int32_t, be32toh, Int32_val, caml_copy_int32)
CONV(htobe64,         int64_t, htobe64, Int64_val, caml_copy_int64)
CONV(be64toh,         int64_t, be64toh, Int64_val, caml_copy_int64)

GET(bu16, uint16_t, be16toh, Val_long)
GET(bs16,  int16_t, be16toh, Val_long)
GET(bu31, uint32_t, be32toh, Val_long)
GET(bs31,  int32_t, be32toh, Val_long)
GET(bs32,  int32_t, be32toh, caml_copy_int32)
GET(bs64,  int64_t, be64toh, caml_copy_int64)

SET(b16, uint16_t, htobe16, Long_val)
SET(b31, uint32_t, htobe32, Long_val)
SET(b32, uint32_t, htobe32, Int32_val)
SET(b64, uint64_t, htobe64, Int64_val)

/* Little endian */
CONV(htole16,        uint16_t, htole16, Long_val, Val_long)
CONV(htole16_signed,  int16_t, htole16, Long_val, Val_long)
CONV(le16toh,        uint16_t, le16toh, Long_val, Val_long)
CONV(le16toh_signed,  int16_t, le16toh, Long_val, Val_long)
CONV(htole31,        uint32_t, htole32, Long_val, Val_long)
CONV(htole31_signed,  int32_t, htole32, Long_val, Val_long)
CONV(le31toh,        uint32_t, le32toh, Long_val, Val_long)
CONV(le31toh_signed,  int32_t, le32toh, Long_val, Val_long)
CONV(htole32,         int32_t, htole32, Int32_val, caml_copy_int32)
CONV(le32toh,         int32_t, le32toh, Int32_val, caml_copy_int32)
CONV(htole64,         int64_t, htole64, Int64_val, caml_copy_int64)
CONV(le64toh,         int64_t, le64toh, Int64_val, caml_copy_int64)

GET(lu16, uint16_t, le16toh, Val_long)
GET(ls16,  int16_t, le16toh, Val_long)
GET(lu31, uint32_t, le32toh, Val_long)
GET(ls31,  int32_t, le32toh, Val_long)
GET(ls32,  int32_t, le32toh, caml_copy_int32)
GET(ls64,  int64_t, le64toh, caml_copy_int64)

SET(l16, uint16_t, htole16, Long_val)
SET(l31, uint32_t, htole32, Long_val)
SET(l32, uint32_t, htole32, Int32_val)
SET(l64, uint64_t, htole64, Int64_val)

#endif /* EXTUNIX_HAVE_ENDIAN */

/* Host endian */
#define id(x) x
GET(u8,    uint8_t, id, Val_long)
GET(s8,     int8_t, id, Val_long)
GET(hu16, uint16_t, id, Val_long)
GET(hs16,  int16_t, id, Val_long)
GET(hu31, uint32_t, id, Val_long)
GET(hs31,  int32_t, id, Val_long)
GET(hs32,  int32_t, id, caml_copy_int32)
GET(hs64,  int64_t, id, caml_copy_int64)

SET(8,    uint8_t, id, Long_val)
SET(h16, uint16_t, id, Long_val)
SET(h31, uint32_t, id, Long_val)
SET(h32, uint32_t, id, Int32_val)
SET(h64, uint64_t, id, Int64_val)
