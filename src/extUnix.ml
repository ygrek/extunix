(** ExtUnix *)

(** Only functions available on this platform *)
module Specific = ExtUnixSpecific

(** All functions,
  those not available on this platform will raise [Invalid_argument] *)
module All = ExtUnixAll

