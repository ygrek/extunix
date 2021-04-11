(** ExtUnix *)

module Specific = ExtUnixSpecific
(** Only functions available on this platform *)

module All = ExtUnixAll
(** All functions,
    those not available on this platform will raise [Not_available]
    with function name as an argument *)

module Config = ExtUnixConfig
(** Compile-time configuration information *)
