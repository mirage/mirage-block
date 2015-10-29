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

let compare
  (type from) (module From: V1_LWT.BLOCK with type t = from) (from: from)
  (type dest) (module Dest: V1_LWT.BLOCK with type t = dest) (dest: dest) =

  From.get_info from
  >>= fun from_info ->
  Dest.get_info dest
  >>= fun dest_info ->

  let total_size_from = Int64.(mul from_info.From.size_sectors (of_int from_info.From.sector_size)) in
  let total_size_dest = Int64.(mul dest_info.Dest.size_sectors (of_int dest_info.Dest.sector_size)) in
  match compare
    (from_info.From.size_sectors, total_size_from)
    (dest_info.Dest.size_sectors, total_size_dest) with
  | ((-1) | 1) as x -> return (`Ok x)
  | _ ->

    let from_buffer = Io_page.(to_cstruct (get 8)) in
    let dest_buffer = Io_page.(to_cstruct (get 8)) in
    let sectors = Cstruct.len from_buffer / from_info.From.sector_size in

    let rec loop next =
      if next >= from_info.From.size_sectors
      then return (`Ok 0)
      else begin
        let remaining = Int64.sub from_info.From.size_sectors next in
        let this_time = min sectors (Int64.to_int remaining) in
        let from_buf = Cstruct.sub from_buffer 0 (from_info.From.sector_size * this_time) in
        let dest_buf = Cstruct.sub dest_buffer 0 (dest_info.Dest.sector_size * this_time) in
        From.read from next [ from_buf ]
        >>= function
        | `Error e ->
          return (`Error (`Msg (error_to_string e)))
        | `Ok () ->
          Dest.read dest next [ dest_buf ]
          >>= function
          | `Error e ->
            return (`Error (`Msg (error_to_string e)))
          | `Ok () ->
            match Cstruct.compare from_buf dest_buf with
            | 0 ->
              loop Int64.(add next (of_int this_time))
            | x -> return (`Ok x)
      end in
    loop 0L
