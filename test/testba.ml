
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

let () =
  let wrap test =
    with_unix_error (fun () -> test (); Gc.compact ())
  in
  let tests = ("tests" >::: [
    "memalign" >:: test_memalign;
  ]) in
  ignore (run_test_tt_main (test_decorate wrap tests))

