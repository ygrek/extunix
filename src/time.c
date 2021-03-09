#define EXTUNIX_WANT_STRPTIME
#define EXTUNIX_WANT_STRTIME
#define EXTUNIX_WANT_TIMEZONE
#define EXTUNIX_WANT_TIMEGM
#include "config.h"


#if defined(EXTUNIX_HAVE_STRPTIME)

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
#endif

#if defined(EXTUNIX_HAVE_STRTIME) || defined(EXTUNIX_HAVE_TIMEGM)

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

#endif

#if defined(EXTUNIX_HAVE_STRTIME)

CAMLprim value caml_extunix_asctime(value v_t)
{
  CAMLparam1(v_t);
  struct tm tm;
  char_os buf[32]; /* user-supplied buffer which should have room for
                      at least 26 bytes */
#if defined(_WIN32)
  errno_t err;
#endif

  fill_tm(&tm, v_t);
#if defined(_WIN32)
  if ((0 != (err = _wasctime_s(buf, sizeof(buf)/sizeof(buf[0]), &tm)))) {
    win32_maperr(err);
#else
  if (NULL == asctime_r(&tm, buf)) {
#endif
    uerror("asctime", Nothing);
  }
  CAMLreturn(caml_copy_string_of_os(buf));
}

CAMLprim value caml_extunix_strftime(value v_fmt, value v_t)
{
  CAMLparam2(v_fmt, v_t);
  struct tm tm;
  char_os buf[256];
#if defined(_WIN32)
  char_os *fmt;
  size_t rc;
#endif

  fill_tm(&tm, v_t);
#if defined(_WIN32)
  fmt = caml_stat_strdup_to_os(String_val(v_fmt));
  rc = wcsftime(buf,sizeof(buf)/sizeof(buf[0]),fmt,&tm);
  caml_stat_free(fmt);
  if (0 == rc)
#else
  if (0 == strftime(buf,sizeof(buf),String_val(v_fmt),&tm))
#endif
    unix_error(EINVAL, "strftime", v_fmt);

  CAMLreturn(caml_copy_string_of_os(buf));
}

CAMLprim value caml_extunix_tzname(value v_isdst)
{
  CAMLparam1(v_isdst);
  int i = Bool_val(v_isdst) ? 1 : 0;
#if defined(_WIN32)
  CAMLlocal1(tzname);
  size_t tznameSize;
  _tzset();
  if (0 != _get_tzname(&tznameSize, NULL, 0, i))
    unix_error(EINVAL, "tzname", Nothing);
  tzname = caml_alloc_string(tznameSize);
  if (0 != _get_tzname(&tznameSize, (char *)String_val(tzname),
                       tznameSize, i))
    unix_error(EINVAL, "tzname", Nothing);
  CAMLreturn(tzname);
#else
  tzset();
  CAMLreturn(caml_copy_string(tzname[i]));
#endif
}

#endif

#if defined(EXTUNIX_HAVE_TIMEZONE)

CAMLprim value caml_extunix_timezone(value v_unit)
{
  CAMLparam1(v_unit);
  CAMLlocal1(v);

#if defined(_WIN32)
  long timezone;
  int daylight;
  _tzset();
  if (0 != _get_timezone(&timezone))
    unix_error(EINVAL, "timezone", Nothing);
  if (0 != _get_daylight(&daylight))
    unix_error(EINVAL, "daylight", Nothing);
#else
  tzset();
#endif

  v = caml_alloc_tuple(2);
  Store_field(v, 0, Val_long(timezone));
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
#if defined(_WIN32)
  t = _mkgmtime(&tm);
#else
  t = timegm(&tm);
#endif

  CAMLreturn(caml_copy_double(t));
}

#endif
