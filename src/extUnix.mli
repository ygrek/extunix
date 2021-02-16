(** ExtUnix *)

module Specific = Specific
(** Only functions available on this platform *)

module All = All
(** All functions,
    those not available on this platform will raise [Not_available]
    with function name as an argument *)

module Config = Config
(** Compile-time configuration information *)
