#define EXTUNIX_WANT_ENDIAN
#include "config.h"

#include <stdint.h>
#include <string.h> /* for memcpy */

#if defined(EXTUNIX_HAVE_ENDIAN)

/*  Copyright © 2012 Goswin von Brederlow <goswin-v-b@web.de>   */

#include <endian.h>
#include <arpa/inet.h>

CAMLprim value caml_extunix_htobe16(value v_x) 
{
  CAMLparam1(v_x);
  uint16_t x = Long_val(v_x);
  x = htobe16(x);
  CAMLreturn(Val_long(x));
}

CAMLprim value caml_extunix_htobe16_signed(value v_x) 
{
  CAMLparam1(v_x);
  int16_t x = Long_val(v_x);
  x = htobe16(x);
  CAMLreturn(Val_long(x));
}

CAMLprim value caml_extunix_be16toh(value v_x) 
{
  CAMLparam1(v_x);
  uint16_t x = Long_val(v_x);
  x = be16toh(x);
  CAMLreturn(Val_long(x));
}

CAMLprim value caml_extunix_be16toh_signed(value v_x) 
{
  CAMLparam1(v_x);
  int16_t x = Long_val(v_x);
  x = be16toh(x);
  CAMLreturn(Val_long(x));
}

CAMLprim value caml_extunix_htobe31(value v_x) 
{
  CAMLparam1(v_x);
  uint32_t x = Long_val(v_x);
  x = htobe32(x);
  CAMLreturn(Val_long(x));
}

CAMLprim value caml_extunix_htobe31_signed(value v_x) 
{
  CAMLparam1(v_x);
  int32_t x = Long_val(v_x);
  x = htobe32(x);
  CAMLreturn(Val_long(x));
}

CAMLprim value caml_extunix_be31toh(value v_x) 
{
  CAMLparam1(v_x);
  uint32_t x = Long_val(v_x);
  x = be32toh(x);
  CAMLreturn(Val_long(x));
}

CAMLprim value caml_extunix_be31toh_signed(value v_x) 
{
  CAMLparam1(v_x);
  int32_t x = Long_val(v_x);
  x = be32toh(x);
  CAMLreturn(Val_long(x));
}

CAMLprim value caml_extunix_htobe32(value v_x) 
{
  CAMLparam1(v_x);
  uint32_t x = Int32_val(v_x);
  x = htobe32(x);
  CAMLreturn(caml_copy_int32(x));
}

CAMLprim value caml_extunix_be32toh(value v_x) 
{
  CAMLparam1(v_x);
  uint32_t x = Int32_val(v_x);
  x = be32toh(x);
  CAMLreturn(caml_copy_int32(x));
}

CAMLprim value caml_extunix_htobe64(value v_x) 
{
  CAMLparam1(v_x);
  uint64_t x = Int64_val(v_x);
  x = htobe64(x);
  CAMLreturn(caml_copy_int64(x));
}

CAMLprim value caml_extunix_be64toh(value v_x) 
{
  CAMLparam1(v_x);
  uint64_t x = Int64_val(v_x);
  x = be64toh(x);
  CAMLreturn(caml_copy_int64(x));
}

CAMLprim value caml_extunix_htole16(value v_x) 
{
  CAMLparam1(v_x);
  uint16_t x = Long_val(v_x);
  x = htole16(x);
  CAMLreturn(Val_long(x));
}

CAMLprim value caml_extunix_htole16_signed(value v_x) 
{
  CAMLparam1(v_x);
  int16_t x = Long_val(v_x);
  x = htole16(x);
  CAMLreturn(Val_long(x));
}

CAMLprim value caml_extunix_le16toh(value v_x) 
{
  CAMLparam1(v_x);
  uint16_t x = Long_val(v_x);
  x = le16toh(x);
  CAMLreturn(Val_long(x));
}

CAMLprim value caml_extunix_le16toh_signed(value v_x) 
{
  CAMLparam1(v_x);
  int16_t x = Long_val(v_x);
  x = le16toh(x);
  CAMLreturn(Val_long(x));
}

CAMLprim value caml_extunix_htole31(value v_x) 
{
  CAMLparam1(v_x);
  uint32_t x = Long_val(v_x);
  x = htole32(x);
  CAMLreturn(Val_long(x));
}

CAMLprim value caml_extunix_htole31_signed(value v_x) 
{
  CAMLparam1(v_x);
  int32_t x = Long_val(v_x);
  x = htole32(x);
  CAMLreturn(Val_long(x));
}

CAMLprim value caml_extunix_le31toh(value v_x) 
{
  CAMLparam1(v_x);
  uint32_t x = Long_val(v_x);
  x = le32toh(x);
  CAMLreturn(Val_long(x));
}

CAMLprim value caml_extunix_le31toh_signed(value v_x) 
{
  CAMLparam1(v_x);
  int32_t x = Long_val(v_x);
  x = le32toh(x);
  CAMLreturn(Val_long(x));
}

CAMLprim value caml_extunix_htole32(value v_x) 
{
  CAMLparam1(v_x);
  uint32_t x = Int32_val(v_x);
  x = htole32(x);
  CAMLreturn(caml_copy_int32(x));
}

CAMLprim value caml_extunix_le32toh(value v_x) 
{
  CAMLparam1(v_x);
  uint32_t x = Int32_val(v_x);
  x = le32toh(x);
  CAMLreturn(caml_copy_int32(x));
}

CAMLprim value caml_extunix_htole64(value v_x) 
{
  CAMLparam1(v_x);
  uint64_t x = Int64_val(v_x);
  x = htole64(x);
  CAMLreturn(caml_copy_int64(x));
}

CAMLprim value caml_extunix_le64toh(value v_x) 
{
  CAMLparam1(v_x);
  uint64_t x = Int64_val(v_x);
  x = le64toh(x);
  CAMLreturn(caml_copy_int64(x));
}


/* Get big endian intX_t out of a string */
CAMLprim value caml_extunix_get_bu16(value v_str, value v_off) {
  CAMLparam2(v_str, v_off);
  char *str = String_val(v_str);
  size_t off = Long_val(v_off);
  uint16_t x;
  memcpy(&x, str + off, sizeof(x));
  x = be16toh(x);
  CAMLreturn(Val_long(x));
}

CAMLprim value caml_extunix_get_bs16(value v_str, value v_off) {
  CAMLparam2(v_str, v_off);
  char *str = String_val(v_str);
  size_t off = Long_val(v_off);
  int16_t x;
  memcpy(&x, str + off, sizeof(x));
  x = be16toh(x);
  CAMLreturn(Val_long(x));
}

CAMLprim value caml_extunix_get_bu31(value v_str, value v_off) {
  CAMLparam2(v_str, v_off);
  char *str = String_val(v_str);
  size_t off = Long_val(v_off);
  uint32_t x;
  memcpy(&x, str + off, sizeof(x));
  x = be32toh(x);
  CAMLreturn(Val_long(x));
}

CAMLprim value caml_extunix_get_bs31(value v_str, value v_off) {
  CAMLparam2(v_str, v_off);
  char *str = String_val(v_str);
  size_t off = Long_val(v_off);
  int32_t x;
  memcpy(&x, str + off, sizeof(x));
  x = be32toh(x);
  CAMLreturn(Val_long(x));
}

CAMLprim value caml_extunix_get_bs32(value v_str, value v_off) {
  CAMLparam2(v_str, v_off);
  char *str = String_val(v_str);
  size_t off = Long_val(v_off);
  int32_t x;
  memcpy(&x, str + off, sizeof(x));
  x = be32toh(x);
  CAMLreturn(caml_copy_int32(x));
}

CAMLprim value caml_extunix_get_bs64(value v_str, value v_off) {
  CAMLparam2(v_str, v_off);
  char *str = String_val(v_str);
  size_t off = Long_val(v_off);
  int64_t x;
  memcpy(&x, str + off, sizeof(x));
  x = be64toh(x);
  CAMLreturn(caml_copy_int64(x));
}

/* Store intX_t as big endian in a string */
CAMLprim value caml_extunix_set_b16(value v_str, value v_off, value v_x) {
  CAMLparam3(v_str, v_off, v_x);
  char *str = String_val(v_str);
  size_t off = Long_val(v_off);
  uint16_t x = Long_val(v_x);
  x = htobe16(x);
  memcpy(str + off, &x, sizeof(x));
  CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_set_b31(value v_str, value v_off, value v_x) {
  CAMLparam3(v_str, v_off, v_x);
  char *str = String_val(v_str);
  size_t off = Long_val(v_off);
  uint32_t x = Long_val(v_x);
  x = htobe32(x);
  memcpy(str + off, &x, sizeof(x));
  CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_set_b32(value v_str, value v_off, value v_x) {
  CAMLparam3(v_str, v_off, v_x);
  char *str = String_val(v_str);
  size_t off = Long_val(v_off);
  uint32_t x = Int32_val(v_x);
  x = htobe32(x);
  memcpy(str + off, &x, sizeof(x));
  CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_set_b64(value v_str, value v_off, value v_x) {
  CAMLparam3(v_str, v_off, v_x);
  char *str = String_val(v_str);
  size_t off = Long_val(v_off);
  uint64_t x = Int64_val(v_x);
  x = htobe64(x);
  memcpy(str + off, &x, sizeof(x));
  CAMLreturn(Val_unit);
}


/* Get little endian intX_t out of a string */
CAMLprim value caml_extunix_get_lu16(value v_str, value v_off) {
  CAMLparam2(v_str, v_off);
  char *str = String_val(v_str);
  size_t off = Long_val(v_off);
  uint16_t x;
  memcpy(&x, str + off, sizeof(x));
  x = le16toh(x);
  CAMLreturn(Val_long(x));
}

CAMLprim value caml_extunix_get_ls16(value v_str, value v_off) {
  CAMLparam2(v_str, v_off);
  char *str = String_val(v_str);
  size_t off = Long_val(v_off);
  int16_t x;
  memcpy(&x, str + off, sizeof(x));
  x = le16toh(x);
  CAMLreturn(Val_long(x));
}

CAMLprim value caml_extunix_get_lu31(value v_str, value v_off) {
  CAMLparam2(v_str, v_off);
  char *str = String_val(v_str);
  size_t off = Long_val(v_off);
  uint32_t x;
  memcpy(&x, str + off, sizeof(x));
  x = le32toh(x);
  CAMLreturn(Val_long(x));
}

CAMLprim value caml_extunix_get_ls31(value v_str, value v_off) {
  CAMLparam2(v_str, v_off);
  char *str = String_val(v_str);
  size_t off = Long_val(v_off);
  int32_t x;
  memcpy(&x, str + off, sizeof(x));
  x = le32toh(x);
  CAMLreturn(Val_long(x));
}

CAMLprim value caml_extunix_get_ls32(value v_str, value v_off) {
  CAMLparam2(v_str, v_off);
  char *str = String_val(v_str);
  size_t off = Long_val(v_off);
  int32_t x;
  memcpy(&x, str + off, sizeof(x));
  x = le32toh(x);
  CAMLreturn(caml_copy_int32(x));
}

CAMLprim value caml_extunix_get_ls64(value v_str, value v_off) {
  CAMLparam2(v_str, v_off);
  char *str = String_val(v_str);
  size_t off = Long_val(v_off);
  int64_t x;
  memcpy(&x, str + off, sizeof(x));
  x = le64toh(x);
  CAMLreturn(caml_copy_int64(x));
}

/* Store intX_t as big endian in a string */
CAMLprim value caml_extunix_set_l16(value v_str, value v_off, value v_x) {
  CAMLparam3(v_str, v_off, v_x);
  char *str = String_val(v_str);
  size_t off = Long_val(v_off);
  uint16_t x = Long_val(v_x);
  x = htole16(x);
  memcpy(str + off, &x, sizeof(x));
  CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_set_l31(value v_str, value v_off, value v_x) {
  CAMLparam3(v_str, v_off, v_x);
  char *str = String_val(v_str);
  size_t off = Long_val(v_off);
  uint32_t x = Long_val(v_x);
  x = htole32(x);
  memcpy(str + off, &x, sizeof(x));
  CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_set_l32(value v_str, value v_off, value v_x) {
  CAMLparam3(v_str, v_off, v_x);
  char *str = String_val(v_str);
  size_t off = Long_val(v_off);
  uint32_t x = Int32_val(v_x);
  x = htole32(x);
  memcpy(str + off, &x, sizeof(x));
  CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_set_l64(value v_str, value v_off, value v_x) {
  CAMLparam3(v_str, v_off, v_x);
  char *str = String_val(v_str);
  size_t off = Long_val(v_off);
  uint64_t x = Int64_val(v_x);
  x = htole64(x);
  memcpy(str + off, &x, sizeof(x));
  CAMLreturn(Val_unit);
}

#endif /* EXTUNIX_HAVE_ENDIAN */

/* Get intX_t out of a string */
CAMLprim value caml_extunix_get_u8(value v_str, value v_off) {
  CAMLparam2(v_str, v_off);
  uint8_t x = String_val(v_str)[Long_val(v_off)];
  CAMLreturn(Val_long(x));
}

CAMLprim value caml_extunix_get_s8(value v_str, value v_off) {
  CAMLparam2(v_str, v_off);
  int8_t x = String_val(v_str)[Long_val(v_off)];
  CAMLreturn(Val_long(x));
}

CAMLprim value caml_extunix_get_hu16(value v_str, value v_off) {
  CAMLparam2(v_str, v_off);
  char *str = String_val(v_str);
  size_t off = Long_val(v_off);
  uint16_t x;
  memcpy(&x, str + off, sizeof(x));
  CAMLreturn(Val_long(x));
}

CAMLprim value caml_extunix_get_hs16(value v_str, value v_off) {
  CAMLparam2(v_str, v_off);
  char *str = String_val(v_str);
  size_t off = Long_val(v_off);
  int16_t x;
  memcpy(&x, str + off, sizeof(x));
  CAMLreturn(Val_long(x));
}

CAMLprim value caml_extunix_get_hu31(value v_str, value v_off) {
  CAMLparam2(v_str, v_off);
  char *str = String_val(v_str);
  size_t off = Long_val(v_off);
  uint32_t x;
  memcpy(&x, str + off, sizeof(x));
  CAMLreturn(Val_long(x));
}

CAMLprim value caml_extunix_get_hs31(value v_str, value v_off) {
  CAMLparam2(v_str, v_off);
  char *str = String_val(v_str);
  size_t off = Long_val(v_off);
  int32_t x;
  memcpy(&x, str + off, sizeof(x));
  CAMLreturn(Val_long(x));
}

CAMLprim value caml_extunix_get_hs32(value v_str, value v_off) {
  CAMLparam2(v_str, v_off);
  char *str = String_val(v_str);
  size_t off = Long_val(v_off);
  int32_t x;
  memcpy(&x, str + off, sizeof(x));
  CAMLreturn(caml_copy_int32(x));
}

CAMLprim value caml_extunix_get_hs64(value v_str, value v_off) {
  CAMLparam2(v_str, v_off);
  char *str = String_val(v_str);
  size_t off = Long_val(v_off);
  int64_t x;
  memcpy(&x, str + off, sizeof(x));
  CAMLreturn(caml_copy_int64(x));
}

/* Store intX_t in a string */
CAMLprim value caml_extunix_set_8(value v_str, value v_off, value v_x) {
  CAMLparam3(v_str, v_off, v_x);
  String_val(v_str)[Long_val(v_off)] = Long_val(v_x);  
  CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_set_h16(value v_str, value v_off, value v_x) {
  CAMLparam3(v_str, v_off, v_x);
  char *str = String_val(v_str);
  size_t off = Long_val(v_off);
  uint16_t x = Long_val(v_x);
  memcpy(str + off, &x, sizeof(x));
  CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_set_h31(value v_str, value v_off, value v_x) {
  CAMLparam3(v_str, v_off, v_x);
  char *str = String_val(v_str);
  size_t off = Long_val(v_off);
  uint32_t x = Long_val(v_x);
  memcpy(str + off, &x, sizeof(x));
  CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_set_h32(value v_str, value v_off, value v_x) {
  CAMLparam3(v_str, v_off, v_x);
  char *str = String_val(v_str);
  size_t off = Long_val(v_off);
  uint32_t x = Int32_val(v_x);
  memcpy(str + off, &x, sizeof(x));
  CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_set_h64(value v_str, value v_off, value v_x) {
  CAMLparam3(v_str, v_off, v_x);
  char *str = String_val(v_str);
  size_t off = Long_val(v_off);
  uint64_t x = Int64_val(v_x);
  memcpy(str + off, &x, sizeof(x));
  CAMLreturn(Val_unit);
}
