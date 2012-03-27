#define EXTUNIX_WANT_ENDIAN
#include "config.h"

#include <stdint.h>

#if defined(EXTUNIX_HAVE_ENDIAN)
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

#endif /* EXTUNIX_HAVE_ENDIAN */
