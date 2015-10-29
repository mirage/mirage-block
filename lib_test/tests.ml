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
open Lwt
open OUnit

let expect_ok msg = function
  | `Error _ -> failwith msg
  | `Ok x -> x

let expect_ok_msg = function
  | `Error (`Msg m) -> failwith m
  | `Error _ -> failwith "unexpected error"
  | `Ok x -> x

let ramdisk_compare () =
  let t =
    Ramdisk.connect ~name:"from"
    >>= fun x ->
    let from = expect_ok "from" x in
    Ramdisk.connect ~name:"dest"
    >>= fun x ->
    let dest = expect_ok "dest" x in
    Mirage_block.compare (module Ramdisk) from (module Ramdisk) dest
    >>= fun x ->
    let x = expect_ok_msg x in
    assert_equal ~printer:string_of_int 0 x; return () in
  Lwt_main.run t

let different_compare () =
  let t =
    Ramdisk.connect ~name:"from"
    >>= fun x ->
    let from = expect_ok "from" x in
    Mirage_block.random (module Ramdisk) from
    >>= fun x ->
    let () = expect_ok "patterns" x in
    Ramdisk.connect ~name:"dest"
    >>= fun x ->
    let dest = expect_ok "dest" x in
    Mirage_block.compare (module Ramdisk) from (module Ramdisk) dest
    >>= fun x ->
    let x = expect_ok_msg x in
    if x = 0 then failwith "different disks compared the same";
    return () in
  Lwt_main.run t

let basic_copy () =
  let t =
    Ramdisk.connect ~name:"from"
    >>= fun x ->
    let from = expect_ok "from" x in
    Ramdisk.connect ~name:"dest"
    >>= fun x ->
    let dest = expect_ok "dest" x in
    Mirage_block.copy (module Ramdisk) from (module Ramdisk) dest
    >>= fun x ->
    let () = expect_ok_msg x in
    Mirage_block.compare (module Ramdisk) from (module Ramdisk) dest
    >>= fun x ->
    let x = expect_ok_msg x in
    assert_equal ~printer:string_of_int 0 x; return () in
  Lwt_main.run t

let random_copy () =
  let t =
    Ramdisk.connect ~name:"from"
    >>= fun x ->
    let from = expect_ok "from" x in
    Mirage_block.random (module Ramdisk) from
    >>= fun x ->
    let () = expect_ok "patterns" x in
    Ramdisk.connect ~name:"dest"
    >>= fun x ->
    let dest = expect_ok "dest" x in
    Mirage_block.copy (module Ramdisk) from (module Ramdisk) dest
    >>= fun x ->
    let () = expect_ok_msg x in
    Mirage_block.compare (module Ramdisk) from (module Ramdisk) dest
    >>= fun x ->
    let x = expect_ok_msg x in
    assert_equal ~printer:string_of_int 0 x; return () in
  Lwt_main.run t

let tests = [
  "ramdisk compare" >:: ramdisk_compare;
  "different compare" >:: different_compare;
  "copy empty ramdisk" >:: basic_copy;
  "copy a random disk" >:: random_copy;
]

let _ =
  let suite = "main" >::: tests in
  OUnit2.run_test_tt_main (ounit2_of_ounit1 suite)
