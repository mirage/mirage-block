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

(** Utility functions over Mirage [BLOCK] devices *)

module Monad: sig
  val bind: [< `Error of 'a | `Ok of 'b ] Lwt.t -> ('b -> ([> `Error of 'a ] as 'c) Lwt.t) -> 'c Lwt.t

  val return: 'a -> [> `Ok of 'a ] Lwt.t

  module Infix: sig
    val (>>=): [< `Error of 'a | `Ok of 'b ] Lwt.t -> ('b -> ([> `Error of 'a ] as 'c) Lwt.t) -> 'c Lwt.t
  end
end

val compare:
  (module V1_LWT.BLOCK with type t = 'a) -> 'a ->
  (module V1_LWT.BLOCK with type t = 'b) -> 'b ->
  [ `Ok of int | `Error of [> `Msg of string ]] Lwt.t
(** Compare the contents of two block devices. *)

val fold_s:
  f:('a -> int64 -> Cstruct.t -> 'a Lwt.t) -> 'a ->
  (module V1_LWT.BLOCK with type t = 'b) -> 'b ->
  [ `Ok of 'a | `Error of [> `Msg of string ]] Lwt.t
(** Folds [f] across blocks read sequentially from a block device *)

val fold_mapped_s:
  f:('a -> int64 -> Cstruct.t -> 'a Lwt.t) -> 'a ->
  (module Mirage_block_s.SEEKABLE with type t = 'b) -> 'b ->
  [ `Ok of 'a | `Error of [> `Msg of string ]] Lwt.t
(** Folds [f] across data blocks read sequentially from a block device.
    In contrast to [fold_s], [fold_mapped_s] will use knowledge about the
    underlying disk structure and will skip blocks which it knows contain
    only zeroes. Note it may still read blocks containing zeroes. *)

val fold_unmapped_s:
  f:('a -> int64 -> Cstruct.t -> 'a Lwt.t) -> 'a ->
  (module Mirage_block_s.SEEKABLE with type t = 'b) -> 'b ->
  [ `Ok of 'a | `Error of [> `Msg of string ]] Lwt.t
(** Folds [f] across data blocks read sequentially from a block device.
    In contrast to [fold_s], [fold_unmapped_s] will use knowledge about the
    underlying disk structure and will only fold across those blocks which
    are guaranteed to be zero i.e. those which are unmapped somehow. *)

val copy:
  (module V1_LWT.BLOCK with type t = 'a) -> 'a ->
  (module V1_LWT.BLOCK with type t = 'b) -> 'b ->
  [ `Ok of unit | `Error of [> `Msg of string | `Is_read_only | `Different_sizes ]] Lwt.t
(** Copy all data from a source BLOCK device to a destination BLOCK device.

    Fails with `Different_sizes if the source and destination are not exactly
    the same size.

    Fails with `Is_read_only if the destination device is read-only.
*)

val random:
  (module V1_LWT.BLOCK with type t = 'a) -> 'a ->
  [ `Ok of unit | `Error of [> `Msg of string ]] Lwt.t
(** Fill a block device with pseudorandom data *)
