
ExtUnix
=======

A collection of thin bindings to various low-level system API.

Our devise: "Be to Unix, what extlib is to stdlib"

 * Implement thin C bindings that directly map to underlying system API.
 * Provide common consistent ocaml interface: naming convention, exceptions.
 * Simple to build - no extra dependencies.

Homepage: http://extunix.forge.ocamlcore.org/

Why?
----

Currently, everybody writes his own bindings to fulfil particular needs. Most
of the system API don't deserve fully fledged library.

The ExtUnix project allow to collect them in one place. Read the "ExtUnix
integration requirements" to know what kind of system API we can integrate.

Guidelines
----------

For OCaml programming style, we follow Unix module:
  * Values and types should be named by the name of the underlying C function
  * Raise Unix_error on runtime errors
  * Uniformly raise Not_available exception for functions not available on the
    current platform
  * Be MT friendly by default - i.e. release runtime lock for blocking
    operations, (FIXME) optionally provide ST variants

Portability: 
  * Minimize (eliminate) shell scripting during build (think windows :) )
  * Write portable C code (use compiler options to catch compatibility issues),
    NB: msvc doesn't support C99.
  * Provide module (ExtUnix.Specific) exposing only functions available on the
    platform where library is built - i.e. guaranteed to not throw
    Not_available exception (experimental, separate archive).

Build infrastructure:
  * src/discover.ml is used to discover available functions during configure
    step.
  * Generated config.h describes "features" discovered - it is responsible for
    inclusion of system-specific headers (currently it provides only "AND"
    check, implement "OR" check - say when C header names differ) - this
    ensures coherent result at configure and build steps.
  * Generated config.ml describes the same features for the ocaml syntax
    extension src/pa_have.ml, which preprocesses src/extUnix.mlpp and generates
    two modules : ExtUnixAll where bindings to missing functions are rewritten
    to raise exception and ExtUnixSpecific which drops bindings to missing
    functions.

ExtUnix integration requirements
--------------------------------

We can integrate into ExtUnix:
  * Official POSIX calls not in Unix module.
  * Drafted POSIX calls which are at least present on two systems among:
    Linux, *BSD, MacOS X.
  * System specific calls, as long as they don't need additional library,
    that they are marked as such in the documentation and that we have an
    automatic configure system test for them.

We should avoid system calls that are complex and would deserve a library on
their own. For example, a family of more than 10 functions and datatypes should
deserve its own library. If an external library already exists and works, like
for inotify system call, we also won't consider it for integration.

Regarding Win32 portability:
If there is a sane default to create a portable equivalent of the function on
Windows, we can consider it. And we will mark it as such in the documentation.

