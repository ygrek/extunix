
open OUnit
open ExtUnix.All

let test_eventfd () =
  let e = eventfd 2 in
  assert_equal 2L (eventfd_read e);
  eventfd_write e 3L;
  assert_equal 3L (eventfd_read e)

let () =
  let _ = run_test_tt ("tests" >::: [
    "eventfd" >:: test_eventfd
  ]) in
  ()

