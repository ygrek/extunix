
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
  * raise single defined (FIXME) exception for functions not available on the current platform
  * implement winapi variant if it closely matches semantics
  * be MT friendly by default - i.e. release runtime lock for blocking operations, optionally provide ST variants

Minimize (eliminate) shell scripting during build (think windows :) )
Provide module with only functions available on the platform where library is built (experiment, separate archive?).

Build infrastructure:
src/discover.ml is used to discover available functions during build.
Generated config.h describes "features" discovered - it is responsible for inclusion
of system-specific headers (currently it provides only "AND" check, implement "OR" check - 
say when C header names differ) - this ensures coherent result at configure and build steps.
Generated config.ml describes the same features for the ocaml syntax extension src/pa_have.ml, 
which preprocesses src/extUnix.mlpp and generates two modules : ExtUnixAll where bindings to missing
functions are rewritten to raise exception and ExtUnixSpecific which drops such functions

-- 

