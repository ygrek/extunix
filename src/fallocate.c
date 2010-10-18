/*
 * posix_fallocate binding
 *
 * author: Sylvain Le Gall
 *
 */

#define WANT_FALLOCATE
#include "config.h"

#if defined(WIN32)

static void caml_fallocate_error (void)
{
  win32_maperr(GetLastError());
  uerror("fallocate", Val_unit);
};

static __int64 caml_fallocate_lseek (HANDLE hFile, __int64 i64Pos, DWORD dwMoveMethod)
{
  LARGE_INTEGER liRes;

  liRes.QuadPart = i64Pos;
  liRes.LowPart  = SetFilePointer(hFile, liRes.LowPart, &liRes.HighPart, dwMoveMethod);
  if (liRes.LowPart == INVALID_SET_FILE_POINTER && 
      GetLastError() != NO_ERROR)
  {
    caml_fallocate_error();
  };

  return liRes.QuadPart;
};

static void caml_fallocate_do (HANDLE hFile, __int64 i64Off, __int64 i64Len)
{
  __int64        i64Cur = 0;
  LARGE_INTEGER  liFileSize; 

  /* Check that off + len > file size */
  if (!GetFileSizeEx(hFile, &liFileSize))
  {
    caml_fallocate_error();
  };

  if (i64Off + i64Len <= liFileSize.QuadPart)
  {
    return;
  };

  /* Get the current position in the file */
  i64Cur = caml_fallocate_lseek(hFile, 0, FILE_CURRENT);

  /* Go to the expected end of file */
  caml_fallocate_lseek(hFile, i64Off, FILE_BEGIN);
  caml_fallocate_lseek(hFile, i64Len, FILE_CURRENT);

  /* Extend file */
  if (!SetEndOfFile(hFile))
  {
    caml_fallocate_error();
  };

  /* Restore initial file pointer position */
  caml_fallocate_lseek(hFile, i64Cur, FILE_BEGIN);
};

CAMLprim value caml_extunix_fallocate64(value vfd, value voff, value vlen)
{
  CAMLparam3(vfd, voff, vlen);

  caml_fallocate_do(Handle_val(vfd), Int64_val(voff), Int64_val(vlen));

  CAMLreturn(Val_unit);
};

CAMLprim value caml_extunix_fallocate(value vfd, value voff, value vlen)
{
  CAMLparam3(vfd, voff, vlen);

  caml_fallocate_do(Handle_val(vfd), Long_val(voff), Long_val(vlen));

  CAMLreturn(Val_unit);
};

#else

#if defined(HAVE_FALLOCATE)

static void caml_fallocate_error (int errcode)
{
  if (errcode != 0)
  {
    unix_error(errcode, "fallocate", Nothing);
  };
};

CAMLprim value caml_extunix_fallocate64(value vfd, value voff, value vlen)
{
  int   errcode = 0;
  int   fd = -1;
  off64_t off = 0;
  off64_t len = 0;

  CAMLparam3(vfd, voff, vlen);

  fd  = Int_val(vfd);
  off = Int64_val(voff);
  len = Int64_val(vlen);

  errcode = posix_fallocate64(fd, off, len);

  caml_fallocate_error(errcode);

  CAMLreturn(Val_unit);
};

CAMLprim value caml_extunix_fallocate(value vfd, value voff, value vlen)
{
  int   errcode = 0;
  int   fd = -1;
  off_t off = 0;
  off_t len = 0;

  CAMLparam3(vfd, voff, vlen);

  fd  = Int_val(vfd);
  off = Long_val(voff);
  len = Long_val(vlen);

  errcode = posix_fallocate(fd, off, len);

  caml_fallocate_error(errcode);

  CAMLreturn(Val_unit);
};

#endif /* HAVE_FALLOCATE */
#endif /* WIN32 */
