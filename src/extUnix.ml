(** ExtUnix *)

(** Only functions available on this platform *)
module Specific = ExtUnixSpecific

(** All functions,
    those not available on this platform will raise [Not_available]
    with function name as an argument *)
module All = ExtUnixAll

(** Compile-time configuration information *)
module Config = ExtUnixConfig
