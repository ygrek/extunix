
open OUnit
open ExtUnixBA.All

let with_unix_error f () =
  try f ()
  with Unix.Unix_error(e,f,a) -> assert_failure (Printf.sprintf "Unix_error : %s(%s) : %s" f a (Unix.error_message e))

let require feature =
  match have feature with
  | None -> assert false
  | Some present -> skip_if (not present) (Printf.sprintf "%S is not available" feature)

let printer x = x

let test_memalign () =
  require "memalign";
  ignore (memalign 512 512);
  ignore (memalign 1024 2048);
  ignore (memalign 2048 16384);
  ignore (memalign 4096 65536)

let test_endian_bigarray () =
  require "unsafe_get_int8";
  require "unsafe_get_int16";
  require "unsafe_get_int31";
  require "unsafe_get_int32";
  require "unsafe_get_int64";
  require "unsafe_get_uint8";
  require "unsafe_get_uint16";
  require "unsafe_get_uint31";
  require "unsafe_set_uint8";
  require "unsafe_set_uint16";
  require "unsafe_set_uint31";
  require "unsafe_set_int8";
  require "unsafe_set_int16";
  require "unsafe_set_int31";
  require "unsafe_set_int32";
  require "unsafe_set_int64";
  let module B = EndianBig in
  let module L = EndianLittle in
  let src =
    Bigarray.Array1.create
      Bigarray.int8_unsigned
      Bigarray.c_layout
      18
  in
  ignore (List.fold_left (fun off x -> Bigarray.Array1.set src off x; off + 1)
	    0
	    [0xFF;
	     0xFF;
	     0xFE; 0xDC;
	     0xFE; 0xDC;
	     0xFE; 0xDC; 0xBA; 0x98;
	     0xFE; 0xDC; 0xBA; 0x98; 0x76; 0x54; 0x32; 0x10]);
  assert_equal (B.get_uint8  src  0) 0xFF;
  assert_equal (B.get_int8   src  1) (-0x01);
  assert_equal (B.get_uint16 src  2) 0xFEDC;
  assert_equal (B.get_int16  src  4) (-0x0124);
  assert_equal (B.get_int32  src  6) (0xFEDCBA98l);
  assert_equal (B.get_int64  src 10) (0xFEDCBA9876543210L);
  assert_equal (L.get_uint8  src  0) 0xFF;
  assert_equal (L.get_int8   src  1) (-0x01);
  assert_equal (L.get_uint16 src  2) 0xDCFE;
  assert_equal (L.get_int16  src  4) (-0x2302);
  assert_equal (L.get_int32  src  6) (0x98BADCFEl);
  assert_equal (L.get_int64  src 10) (0x1032547698BADCFEL);
  let b =
    Bigarray.Array1.create
      Bigarray.int8_unsigned
      Bigarray.c_layout
      18
  in
  B.set_uint8  b  0 0xFF;
  B.set_int8   b  1 (-0x01);
  B.set_uint16 b  2 0xFEDC;
  B.set_uint16 b  4 (-0x0124);
  B.set_int32  b  6 (0xFEDCBA98l);
  B.set_int64  b 10 (0xFEDCBA9876543210L);
  assert_equal b src;
  let l =
    Bigarray.Array1.create
      Bigarray.int8_unsigned
      Bigarray.c_layout
      18
  in
  L.set_uint8  l  0 0xFF;
  L.set_int8   l  1 (-0x01);
  L.set_uint16 l  2 0xDCFE;
  L.set_uint16 l  4 (-0x2302);
  L.set_int32  l  6 (0x98BADCFEl);
  L.set_int64  l 10 (0x1032547698BADCFEL);
  assert_equal l src

let () =
  let wrap test =
    with_unix_error (fun () -> test (); Gc.compact ())
  in
  let tests = ("tests" >::: [
    "memalign" >:: test_memalign;
    "endian_bigrray" >:: test_endian_bigarray;
  ]) in
  ignore (run_test_tt_main (test_decorate wrap tests))

