(lang dune 2.8)
(use_standard_c_and_cxx_flags true)
(name extunix)
(generate_opam_files true)

(package
 (name extunix)
 (depends
  (dune-configurator :build)
  (ocaml-migrate-parsetree (and :build (< 2.0.0)))
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
 (license "LGPL-2.1-only with OCaml-LGPL-linking-exception")
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
  "ygrek"
  "Zhenya Lykhovyd"
 )
 (maintainers "ygrek@autistici.org")
 (source (github ygrek/extunix))
 (bug_reports "https://github.com/ygrek/extunix/issues")
 (homepage "https://ygrek.org.ua/p/ocaml-extunix")
 (documentation "https://ygrek.org.ua/p/ocaml-extunix")
 (tags ("org:ygrek")))
