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

module type SEEKABLE = sig
  include V1_LWT.BLOCK

	val seek_unmapped: t -> int64 -> [ `Ok of int64 | `Error of error ] io
	(** [seek_unmapped t start] returns the sector offset of the next guaranteed
	    zero-filled region (typically guaranteed because it is unmapped) *)

	val seek_mapped: t -> int64 -> [ `Ok of int64 | `Error of error ] io
	(** [seek_mapped t start] returns the sector offset of the next regoin of the
			device which may have data in it (typically this is the next mapped
			region) *)
end

module type RESIZABLE = sig
  include V1_LWT.BLOCK

	val resize : t -> int64 -> [ `Ok of unit | `Error of error ] io
	(** [resize t new_size_sectors] attempts to resize the connected device
	    to have the given number of sectors. If successful, subsequent calls
	    to [get_info] will reflect the new size. *)
end
