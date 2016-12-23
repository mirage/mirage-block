#!/usr/bin/env ocaml
#use "topfind"
#require "topkg"
open Topkg

let metas = [
  Pkg.meta_file ~install:false "pkg/META";
  Pkg.meta_file ~install:false "pkg/META.lwt";
]

let opams =
  let opam no_lint name =
    Pkg.opam_file ~lint_deps_excluding:(Some no_lint) ~install:false name
  in
  [
  opam ["lwt"; "mirage-block"; "cstruct"; "io-page"; "logs"] "opam";
  opam ["mirage-device"] "mirage-block-lwt.opam";
  ]

let () =
  Pkg.describe ~metas ~opams "mirage-block" @@ fun c ->
  match Conf.pkg_name c with
  | "mirage-block" ->
    Ok [ Pkg.lib "pkg/META";
         Pkg.mllib "src/mirage-block.mllib" ]
  | "mirage-block-lwt" ->
    Ok [ Pkg.lib "pkg/META.lwt" ~dst:"META";
         Pkg.mllib ~api:["Mirage_block_lwt"] "lwt/mirage-block-lwt.mllib" ]
  | other ->
    R.error_msgf "unknown package name: %s" other
