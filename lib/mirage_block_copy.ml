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

module Make_seekable(B: V1_LWT.BLOCK) = struct
  include B

  let seek_mapped t sector = Lwt.return (`Ok sector)
  let seek_unmapped t _ =
    B.get_info t
    >>= fun info ->
    Lwt.return (`Ok info.B.size_sectors)
end

let sparse_copy
  (type from) (module From: Mirage_block_s.SEEKABLE with type t = from) (from: from)
  (type dest) (module Dest: V1_LWT.BLOCK with type t = dest) (dest: dest) =

  From.get_info from
  >>= fun from_info ->
  Dest.get_info dest
  >>= fun dest_info ->

  let total_size_from = Int64.(mul from_info.From.size_sectors (of_int from_info.From.sector_size)) in
  let total_size_dest = Int64.(mul dest_info.Dest.size_sectors (of_int dest_info.Dest.sector_size)) in
  if total_size_from <> total_size_dest
  then return (`Error `Different_sizes)
  else begin

    (* We'll run multiple threads to try to overlap I/O *)
    let next_from_sector = ref 0L in
    let next_dest_sector = ref 0L in
    let failure = ref None in
    let m = Lwt_mutex.create () in

    let record_failure e =
      Lwt_mutex.with_lock m
        (fun () -> match !failure with
          | Some _ -> return ()
          | None -> failure := Some e; return ()) in

    let thread () =
      (* A page-aligned 64KiB buffer *)
      let buffer = Io_page.(to_cstruct (get 8)) in
      let from_sectors = Cstruct.len buffer / from_info.From.sector_size in
      let dest_sectors = Cstruct.len buffer / dest_info.Dest.sector_size in
      let rec loop () =
        (* Grab a region of the disk to copy *)
        Lwt_mutex.with_lock m (fun () ->
          let next_from = !next_from_sector in
          let next_dest = !next_dest_sector in
          next_from_sector := Int64.(add next_from (of_int from_sectors));
          next_dest_sector := Int64.(add next_dest (of_int dest_sectors));
          return (next_from, next_dest)
        ) >>= fun (next_from, next_dest) ->
        if next_from >= from_info.From.size_sectors
        then return ()
        else begin
          (* Copy from [next_from, next_from + from_sectors], ommitting
             unmapped subregions *)
          let rec inner x y =
            if x >= Int64.(add next_from (of_int from_sectors)) || x >= from_info.From.size_sectors
            then loop ()
            else begin
              From.seek_mapped from x
              >>= function
              | `Error e ->
                record_failure (error_to_string e)
              | `Ok x' ->
                if x' > x
                then inner x' Int64.(add y (sub x' x))
                else begin
                  From.seek_unmapped from x
                  >>= function
                  | `Error e ->
                    record_failure (error_to_string e)
                  | `Ok next_unmapped ->
                    (* Copy up to the unmapped block, or the end of our chunk... *)
                    let copy_up_to = min next_unmapped Int64.(add next_from (of_int from_sectors)) in
                    let remaining = Int64.sub copy_up_to x in
                    let this_time = min (Int64.to_int remaining) from_sectors in
                    let buf = Cstruct.sub buffer 0 (from_info.From.sector_size * this_time) in
                    From.read from x [ buf ]
                    >>= function
                    | `Error e ->
                      record_failure (error_to_string e)
                    | `Ok () ->
                      Dest.write dest y [ buf ]
                      >>= function
                      | `Error e ->
                        record_failure (error_to_string e)
                      | `Ok () ->
                        inner Int64.(add x (of_int this_time)) Int64.(add y (of_int this_time))
                  end
            end in
          inner next_from next_dest
        end in
      loop () in
    let threads = List.map thread [ (); (); (); (); (); (); (); () ] in
    Lwt.join threads
    >>= fun () ->
    match !failure with
    | None -> return (`Ok ())
    | Some msg -> return (`Error (`Msg msg))
  end

let copy
  (type from) (module From: V1_LWT.BLOCK with type t = from) (from: from)
  (type dest) (module Dest: V1_LWT.BLOCK with type t = dest) (dest: dest) =
  let module From_seekable = Make_seekable(From) in
  sparse_copy (module From_seekable) from (module Dest) dest
