
#define EXTUNIX_WANT_SYSINFO
#include "config.h"

#if defined(EXTUNIX_HAVE_SYSINFO)

static value convert(struct sysinfo* s)
{
  CAMLparam0();
  CAMLlocal2(v,v_loads);

  v_loads = caml_alloc_tuple(3);

  Store_field(v_loads, 0, caml_copy_double(s->loads[0] / (float)(1 << SI_LOAD_SHIFT)));
  Store_field(v_loads, 1, caml_copy_double(s->loads[1] / (float)(1 << SI_LOAD_SHIFT)));
  Store_field(v_loads, 2, caml_copy_double(s->loads[2] / (float)(1 << SI_LOAD_SHIFT)));

  v = caml_alloc_tuple(12);

  Store_field(v, 0, Val_long(s->uptime));
  Store_field(v, 1, v_loads);
  Store_field(v, 2, Val_long(s->totalram));
  Store_field(v, 3, Val_long(s->freeram));
  Store_field(v, 4, Val_long(s->sharedram));
  Store_field(v, 5, Val_long(s->bufferram));
  Store_field(v, 6, Val_long(s->totalswap));
  Store_field(v, 7, Val_long(s->freeswap));
  Store_field(v, 8, Val_int(s->procs));
  Store_field(v, 9, Val_long(s->totalhigh));
  Store_field(v, 10, Val_long(s->freehigh));
  Store_field(v, 11, Val_int(s->mem_unit));

  CAMLreturn(v);
}

CAMLprim value caml_extunix_sysinfo(value v_unit)
{
  CAMLparam1(v_unit);
  struct sysinfo s;

  if (0 != sysinfo(&s))
  {
    uerror("sysinfo",Nothing);
  }

  CAMLreturn(convert(&s));
}

CAMLprim value caml_extunix_uptime(value v_unit)
{
  struct sysinfo s;
  UNUSED(v_unit);

  if (0 != sysinfo(&s))
  {
    uerror("sysinfo",Nothing);
  }

  return Val_int(s.uptime);
}

#endif
