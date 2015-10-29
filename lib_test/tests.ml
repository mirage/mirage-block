(*
 * Copyright (c) 2015 David Scott <dave@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 *)
open Mirage_block
open Lwt
open OUnit

let basic_copy () =
  let t =
    Ramdisk.connect ~name:"from"
    >>= function
    | `Error _ -> failwith "from"
    | `Ok from ->
      Ramdisk.connect ~name:"dest"
      >>= function
      | `Error _ -> failwith "dest"
      | `Ok dest ->
        Copy.copy (module Ramdisk) from (module Ramdisk) dest
        >>= function
        | `Error (`Msg m) -> failwith m
        | `Ok () -> return () in
  Lwt_main.run t

let tests = [
  "copy empty ramdisk" >:: basic_copy;
]

let _ =
  let suite = "main" >::: tests in
  OUnit2.run_test_tt_main (ounit2_of_ounit1 suite)
