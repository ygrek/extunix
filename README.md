ExtUnix OCaml library
=====================

[![Build status](https://github.com/ygrek/extunix/actions/workflows/main.yml/badge.svg)](https://github.com/ygrek/extunix/actions)
[![OCaml-CI Build Status](https://img.shields.io/endpoint?url=https://ocaml.ci.dev/badge/ygrek/extunix/master&logo=ocaml)](https://ocaml.ci.dev/github/ygrek/extunix)

A collection of thin bindings to various low-level system API.

Our motto: "Be to Unix, what extlib is to stdlib"

* Implement thin C bindings that directly map to underlying system API.
* Provide common consistent ocaml interface: naming convention, exceptions.
* Simple to build - no extra dependencies.

Homepage: <https://ygrek.org/p/ocaml-extunix/>

Why?
----

Most of the system API don't deserve fully fledged library.

The ExtUnix project aims to collect these in one place. Read the
"[ExtUnix integration requirements](#extunix-integration-requirements)"
to know what kind of system API we can integrate.

Installation
------------

Dependencies :

* OCaml, Dune, ppxlib for build and installation
* (optional) oUnit2 for tests, odoc for documentation

Build and install:

    make
    make install

Alternatively use the underlying Dune build system directly (plain ocaml,
no sh and make needed):

    dune build @install

Usage example:

    $ ocaml
    # #use "topfind";;
    # #require "extunix";;
    # module U = ExtUnix.Specific;;
    # U.ttyname Unix.stdout;;
    - : string = "/dev/pts/8"

Run unit tests:

    make test

Guidelines
----------

For OCaml programming style, we follow Unix module:

* Values and types should be named by the name of the underlying C function
* Raise `Unix_error` on runtime errors
* Uniformly raise `Not_available` exception for functions not available on the
  current platform
* Be MT friendly by default - i.e. release runtime lock for blocking
  operations, (FIXME) optionally provide ST variants

Portability:

* No shell scripting for build and install (think windows :) )
* Write portable C code (use compiler options to catch compatibility issues),
  NB: msvc doesn't support C99.
* Provide module (`ExtUnix.Specific`) exposing only functions available on the
  platform where library is built - i.e. guaranteed to not throw
  `Not_available` exception (experimental).

Build infrastructure:

* [`discover`][] is used to discover available functions during
  configure step.

* Generated `config.h` describes "features" discovered - it is
  responsible for inclusion of system-specific headers - this ensures
  coherent result at configure and build steps.

* Generated `config.ml` describes the same features for the ocaml
  syntax extension [`ppx_have`][], which preprocesses
  [`src/extUnix.pp.ml`][] and generates two modules: `ExtUnix.All`
  where bindings to missing functions are rewritten to raise exception
  and `ExtUnix.Specific` which drops bindings to missing functions.

[`discover`]: discover/discover.ml
[`ppx_have`]: ppx_have/ppx_have.ml
[`src/extUnix.pp.ml`]: src/extUnix.pp.ml

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

Checklist for adding new bindings
---------------------------------

* Add the C code to [`src`][] (follow the code style of existing bindings)
* Add the required checks to [`discover/discover.ml`][]
* Add the name of the C bindings to [`src/dune`][]
* Add the OCaml code to [`src/extUnix.pp.ml`][] guarded with `HAVE ... END`
* Add some tests to [`test/test.ml`][]
* Add note to [`CHANGES.txt`][]
* Run `make`

[`src`]: src
[`discover/discover.ml`]: discover/discover.ml
[`src/dune`]: src/dune
[`test/test.ml`]: test/test.ml
[`CHANGES.txt`]: CHANGES.txt

Checklist for release
---------------------

* Review `git log` and update [`CHANGES.txt`][]
* Increase VERSION in Makefile
* Commit
* `make release`

Development
-----------

Many people contribute to extunix. Please submit your patches and/or feature requests
to the project bugtracker at <https://github.com/ygrek/extunix/issues>.

The current maintainer is reachable at <mailto:ygrek@autistici.org>.
