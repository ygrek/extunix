(** ExtUnixBA *)

(** Only functions available on this platform *)
module Specific = ExtUnixBASpecific

(** All functions,
    those not available on this platform will raise [Not_available] 
    with function name as an argument *)
module All = ExtUnixBAAll

