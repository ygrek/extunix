
ExtUnix
=======

A collection of thin bindings to various low-level system API (often non-portable).
Homepage: http://extunix.forge.ocamlcore.org/

Why?
----

Currently, everybody writes his own bindings to fulfil particular needs -> collect them in one place

Goals/guidelines
----------------

Implement thin C bindings that directly map to underlying system API.
Provide common consistent ocaml interface (naming convention, exceptions).
Simple to build - no extra dependencies (anyway, this is mainly C code).
Be to Unix, what extlib is to stdlib :)

FIXME define "system API"
Bindings for other APIs (libacl, libattr) - separate modules/archives (but with same infrastructure) ?

Follow Unix modules style: 
  * values and types should be named by the name of the underlying C function
  * raise Unix_error on runtime errors
  * uniformly raise Not_available exception for functions not available on the current platform
  * implement winapi variant if it closely matches semantics
  * be MT friendly by default - i.e. release runtime lock for blocking operations, optionally provide ST variants

Minimize (eliminate) shell scripting during build (think windows :) )
Write portable C code (use compiler options to catch compatibility issues), NB: msvc doesn't support C99.
Provide module (ExtUnix.Specific) exposing only functions available on the platform where library is built - i.e. guaranteed to not throw Not_available exception (experimental, separate archive?).

Build infrastructure:
src/discover.ml is used to discover available functions during configure step.
Generated config.h describes "features" discovered - it is responsible for inclusion
of system-specific headers (currently it provides only "AND" check, implement "OR" check - 
say when C header names differ) - this ensures coherent result at configure and build steps.
Generated config.ml describes the same features for the ocaml syntax extension src/pa_have.ml, 
which preprocesses src/extUnix.mlpp and generates two modules : ExtUnixAll where bindings to missing
functions are rewritten to raise exception and ExtUnixSpecific which drops bindings to missing functions.

-- 

