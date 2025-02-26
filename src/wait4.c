#define EXTUNIX_WANT_WAIT4
#include "config.h"

#if defined(EXTUNIX_HAVE_WAIT4)

static value alloc_wait4_return(int pid, int status, struct rusage *rusage) {
  CAMLparam0();
  CAMLlocal3(res, st, ru);

  if (pid == 0)
    status = 0;

  if (WIFEXITED(status)) {
    st = caml_alloc_small(1, 0);
    Store_field(st, 0, Val_int(WEXITSTATUS(status)));
  } else if (WIFSTOPPED(status)) {
    st = caml_alloc_small(1, 2);
    Store_field(st, 0,
                Val_int(caml_rev_convert_signal_number(WSTOPSIG(status))));
  } else {
    st = caml_alloc_small(1, 1);
    Store_field(st, 0,
                Val_int(caml_rev_convert_signal_number(WTERMSIG(status))));
  }

  ru = caml_alloc(3, 0);
  Store_field(ru, 0,
              caml_copy_double((double)rusage->ru_utime.tv_sec +
                               (double)rusage->ru_utime.tv_usec / 1e6));
  Store_field(ru, 1,
              caml_copy_double((double)rusage->ru_stime.tv_sec +
                               (double)rusage->ru_stime.tv_usec / 1e6));
  Store_field(ru, 2, caml_copy_int64(rusage->ru_maxrss));

  res = caml_alloc_tuple(3);
  Store_field(res, 0, Val_int(pid));
  Store_field(res, 1, st);
  Store_field(res, 2, ru);

  CAMLreturn(res);
}

static const int wait_flag_table[] = {WNOHANG, WUNTRACED};

CAMLprim value caml_extunix_wait4(value vwait_flags, value vpid_req) {
  CAMLparam2(vwait_flags, vpid_req);
  int pid, wstatus, options;
  struct rusage rusage;
  int pid_req = Int_val(vpid_req);

  options = caml_convert_flag_list(vwait_flags, wait_flag_table);
  caml_enter_blocking_section();
  pid = wait4(pid_req, &wstatus, options, &rusage);
  caml_leave_blocking_section();
  if (pid == -1)
    unix_error(errno, "wait4", Nothing);
  CAMLreturn(alloc_wait4_return(pid, wstatus, &rusage));
}
#endif
