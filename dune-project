(lang dune 3.0)
(name extunix)
(generate_opam_files true)

(package
 (name extunix)
 (depends
  (ocaml (>= 4.06))
  (dune-configurator (and (>= 2.9) :build))
  (ppxlib (and (>= 0.18) :build))
  (ounit2 :with-test)
  base-bytes
  base-bigarray
  base-unix
 )
 (synopsis "Collection of thin bindings to various low-level system API")
 (description
  "\| Motto: "Be to Unix, what extlib is to stdlib"
  "\|
  "\| * Implement thin C bindings that directly map to underlying system API.
  "\| * Provide common consistent ocaml interface: naming convention, exceptions.
  "\| * Simple to build - no extra dependencies.
 )
 (license "LGPL-2.1-only WITH OCaml-LGPL-linking-exception")
 (authors
  "Andre Nathan"
  "Antonin Décimo"
  "Dmitry Grebeniuk"
  "François Bobot"
  "Gerd Stolpmann"
  "Goswin von Brederlow"
  "Joshua Smith"
  "Kaustuv Chaudhuri"
  "Markus W. Weissmann"
  "Mehdi Dogguy"
  "Niki Yoshiuchi"
  "Pierre Chambart"
  "Roman Vorobets"
  "Stéphane Glondu"
  "Sylvain Le Gall"
  "Teague Hansen"
  "ygrek"
  "Zhenya Lykhovyd"
 )
 (maintainers "ygrek@autistici.org" "Antonin Décimo <antonin@tarides.com>")
 (source (github ygrek/extunix))
 (tags ("org:ygrek")))
