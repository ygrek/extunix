
/*
 * ftruncate C binding
 *
 * author: Sylvain Le Gall
 *
 */

#include <caml/mlvalues.h>
#include <caml/fail.h>
#include <caml/memory.h>

#ifdef WINDOWS

static void caml_ftruncate_win32_error (void)
{
  win32_maperr(GetLastError());
  uerror("ftruncate", Val_unit);
};

static __int64 caml_ftruncate_win32_lseek (HANDLE hFile, __int64 i64Pos, DWORD dwMoveMethod)
{
  LARGE_INTEGER liRes;

  liRes.QuadPart = i64Pos;
  liRes.LowPart  = SetFilePointer(hFile, liRes.LowPart, &liRes.HighPart, dwMoveMethod);
  if (liRes.LowPart == INVALID_SET_FILE_POINTER && 
      GetLastError() != NO_ERROR)
  {
    caml_ftruncate_win32_error();
  };

  return liRes.QuadPart;
};

static void caml_ftruncate_win32_do (HANDLE hFile, __int64 i64Len)
{
  __int64 i64Cur = 0;

  /* Save actual file offset */
  i64Cur = caml_ftruncate_win32_lseek(hFile, 0, FILE_CURRENT);

  /* Goto expected end */
  caml_ftruncate_win32_lseek(hFile, i64Len, FILE_BEGIN);

  /* Set end */
  if (!SetEndOfFile(hFile))
  {
    caml_ftruncate_win32_error();
  };

  /* Restore file offset */
  caml_ftruncate_win32_lseek(hFile, i64Cur, FILE_BEGIN);
};

CAMLprim value caml_ftruncate_win32 (value vfd, value vlen)
{
  CAMLparam2(vfd, vlen);
  caml_ftruncate_win32_do(Handle_val(vfd), Long_val(vlen));
  CAMLreturn(Val_unit);
}

CAMLprim value caml_ftruncate64_win32 (value vfd, value vlen)
{
  CAMLparam2(vfd, vlen);
  caml_ftruncate_win32_do(Handle_val(vfd), Int64_val(vlen));
  CAMLreturn(Val_unit);
}

#else

CAMLprim value caml_ftruncate_win32 (value vfd, value vlen)
{
  CAMLparam2(vfd, vlen);
  caml_failwith("Not implemented");
  CAMLreturn(Val_unit);
}

CAMLprim value caml_ftruncate64_win32 (value vfd, value vlen)
{
  CAMLparam2(vfd, vlen);
  caml_failwith("Not implemented");
  CAMLreturn(Val_unit);
}

#endif
