
#define EXTUNIX_WANT_STRTIME
#define EXTUNIX_WANT_TIMEZONE
#define EXTUNIX_WANT_TIMEGM
#include "config.h"

#if defined(EXTUNIX_HAVE_STRTIME)

/*
 * http://caml.inria.fr/mantis/view.php?id=3851
 * Author: Joshua Smith
 */

/* from otherlibs/unix/gmtime.c */
static value alloc_tm(struct tm *tm)
{
  value res;
  res = caml_alloc_small(9, 0);
  Field(res,0) = Val_int(tm->tm_sec);
  Field(res,1) = Val_int(tm->tm_min);
  Field(res,2) = Val_int(tm->tm_hour);
  Field(res,3) = Val_int(tm->tm_mday);
  Field(res,4) = Val_int(tm->tm_mon);
  Field(res,5) = Val_int(tm->tm_year);
  Field(res,6) = Val_int(tm->tm_wday);
  Field(res,7) = Val_int(tm->tm_yday);
  Field(res,8) = tm->tm_isdst ? Val_true : Val_false;
  return res;
}

static void fill_tm(struct tm* tm, value t)
{
  tm->tm_sec = Int_val(Field(t, 0));
  tm->tm_min = Int_val(Field(t, 1));
  tm->tm_hour = Int_val(Field(t, 2));
  tm->tm_mday = Int_val(Field(t, 3));
  tm->tm_mon = Int_val(Field(t, 4));
  tm->tm_year = Int_val(Field(t, 5));
  tm->tm_wday = Int_val(Field(t, 6));
  tm->tm_yday = Int_val(Field(t, 7));
  tm->tm_isdst = Bool_val(Field(t, 8)); /* -1 */
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wmissing-field-initializers"

CAMLprim value caml_extunix_strptime(value v_fmt, value v_s)
{
  struct tm tm = { 0 };
  if (NULL == strptime(String_val(v_s),String_val(v_fmt),&tm))
    unix_error(EINVAL, "strptime", v_s);
  return alloc_tm(&tm);
}

#pragma GCC diagnostic pop

CAMLprim value caml_extunix_asctime(value v_t)
{
  struct tm tm;
  char buf[32]; /* user-supplied buffer which should have room for at least 26 bytes */
 
  fill_tm(&tm, v_t);
  if (NULL == asctime_r(&tm,buf))
    unix_error(EINVAL, "asctime", Nothing);
  return caml_copy_string(buf);
}

CAMLprim value caml_extunix_strftime(value v_fmt, value v_t)
{
  struct tm tm;
  char buf[256];

  fill_tm(&tm, v_t);
  if (0 == strftime(buf,sizeof(buf),String_val(v_fmt),&tm))
    unix_error(EINVAL, "strftime", v_fmt);

  return caml_copy_string(buf);
}

CAMLprim value caml_extunix_tzname(value v_isdst)
{
  int i = Bool_val(v_isdst) ? 1 : 0;
  tzset();
  return caml_copy_string(tzname[i]);
}

#endif

#if defined(EXTUNIX_WANT_TIMEZONE)

CAMLprim value caml_extunix_timezone(value v_unit)
{
  CAMLparam1(v_unit);
  CAMLlocal1(v);
  tzset();
  v = caml_alloc_tuple(2);
  Store_field(v, 0, Val_int(timezone));
  Store_field(v, 1, Val_bool(daylight != 0));
  CAMLreturn(v);
}

#endif

#if defined(EXTUNIX_HAVE_TIMEGM)

CAMLprim value caml_extunix_timegm(value v_t)
{
  CAMLparam1(v_t);
  struct tm tm;
  time_t t;

  fill_tm(&tm, v_t);
  t = timegm(&tm);

  CAMLreturn(caml_copy_double(t));
}

#endif

