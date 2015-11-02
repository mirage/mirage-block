(*
 * Copyright (C) 2015 David Scott <dave.scott@unikernel.com>
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

let error_to_string = function
  | `Unknown x -> x
  | `Unimplemented -> "Unimplemented"
  | `Is_read_only -> "Is_read_only"
  | `Disconnected -> "Disconnected"

let fold_s ~f init
  (type block) (module Block: V1_LWT.BLOCK with type t = block) (b: block) =
  Block.get_info b
  >>= fun info ->
  let buffer = Io_page.(to_cstruct (get 8)) in
  let sectors = Cstruct.len buffer / info.Block.sector_size in

  let rec loop acc next =
    if next >= info.Block.size_sectors
    then return (`Ok acc)
    else begin
      let remaining = Int64.sub info.Block.size_sectors next in
      let this_time = min sectors (Int64.to_int remaining) in
      let buf = Cstruct.sub buffer 0 (info.Block.sector_size * this_time) in
      Block.read b next [ buf ]
      >>= function
      | `Error e ->
        return (`Error (`Msg (error_to_string e)))
      | `Ok () ->
        f acc Int64.(mul next (of_int info.Block.sector_size)) buf
        >>= fun acc ->
        loop acc Int64.(add next (of_int this_time))
    end in
  loop init 0L

let fold_mapped_s ~f init
  (type seekable) (module Seekable: Mirage_block_s.SEEKABLE with type t = seekable) (s: seekable) =
  failwith "not implemented"

let fold_unmapped_s ~f init
  (type seekable) (module Seekable: Mirage_block_s.SEEKABLE with type t = seekable) (s: seekable) =
  failwith "not implemented"
