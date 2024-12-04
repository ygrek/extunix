#define EXTUNIX_WANT_SYSLOG
#include "config.h"

#if defined(EXTUNIX_HAVE_SYSLOG)

static const int mask_table[] = {
  LOG_MASK(LOG_EMERG), LOG_MASK(LOG_ALERT), LOG_MASK(LOG_CRIT),
  LOG_MASK(LOG_ERR), LOG_MASK(LOG_WARNING), LOG_MASK(LOG_NOTICE),
  LOG_MASK(LOG_INFO), LOG_MASK(LOG_DEBUG)
};

CAMLprim value caml_extunix_setlogmask(value v_level)
{
  CAMLparam1(v_level);
  CAMLlocal2(cli, cons);
  int mask, nmask;
  size_t i;

  mask = caml_convert_flag_list(v_level, mask_table);

  caml_enter_blocking_section();
  nmask = setlogmask(mask);
  caml_leave_blocking_section();

  // generate list from mask (invers of "caml_convert_flag_list")
  cli = Val_emptylist;
  for (i = 0; i < (sizeof(mask_table) / sizeof(int)); i++)
  {
    if ((mask_table[i] & nmask) == mask_table[i])
    {
      cons = caml_alloc(2, 0);

      Store_field(cons, 0, Val_int(i));
      Store_field(cons, 1, cli);

      cli = cons;
    }
  }

  CAMLreturn(cli);
}

static const int option_table[] = {
  LOG_PID, LOG_CONS, LOG_NDELAY, LOG_ODELAY, LOG_NOWAIT
};

static const int facility_table[] = {
  LOG_KERN, LOG_USER, LOG_MAIL, LOG_NEWS, LOG_UUCP, LOG_DAEMON, LOG_AUTH,
  LOG_CRON, LOG_LPR, LOG_LOCAL0, LOG_LOCAL1, LOG_LOCAL2, LOG_LOCAL3,
  LOG_LOCAL4, LOG_LOCAL5, LOG_LOCAL6, LOG_LOCAL7
};

CAMLprim value caml_extunix_openlog(value v_ident, value v_option, value v_facility)
{
  CAMLparam3(v_ident, v_option, v_facility);
  int option, facility;
  size_t index_facility;
  static char *ident = NULL; /* openlog does _not_ store ident -- keep a heap copy */

  if (NULL != ident)
  {
    caml_stat_free(ident);
    ident = NULL;
  }

  ident = (Val_none == v_ident) ? NULL : caml_stat_strdup(String_val(Some_val(v_ident)));
  option = caml_convert_flag_list(v_option, option_table);
  index_facility = Int_val(v_facility);
  assert(index_facility < (sizeof(facility_table) / sizeof(int)));
  facility = facility_table[index_facility];

  openlog(ident, option, facility);

  CAMLreturn(Val_unit);
}

CAMLprim value caml_extunix_closelog(void)
{
  CAMLparam0();
  closelog();
  CAMLreturn(Val_unit);
}

static const int level_table[] = {
  LOG_EMERG, LOG_ALERT, LOG_CRIT, LOG_ERR, LOG_WARNING, LOG_NOTICE, LOG_INFO,
  LOG_DEBUG
};

CAMLprim value caml_extunix_syslog(value v_facility, value v_level, value v_string)
{
  CAMLparam3(v_facility, v_level, v_string);
  int facility, level;
  size_t index_level, index_facility;
  char *str;

  facility = 0;
  if (Val_none != v_facility)
  {
    index_facility = Int_val(Some_val(v_facility));
    assert(index_facility < (sizeof(facility_table) / sizeof(int)));
    facility = facility_table[index_facility];
  }

  index_level = Int_val(v_level);
  assert(index_level < (sizeof(level_table) / sizeof(int)));
  level = level_table[index_level];
  str = caml_stat_strdup(String_val(v_string));

  caml_enter_blocking_section();
  syslog(level | facility, "%s", str);
  caml_leave_blocking_section();

  caml_stat_free(str);

  CAMLreturn(Val_unit);
}

#endif
