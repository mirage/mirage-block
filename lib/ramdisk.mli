(*
 * Copyright (C) 2011-2013 Citrix Systems Inc
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
 *)

include V1_LWT.BLOCK
  with type id = string

val create: name:string -> size_sectors:int64 -> sector_size:int -> unit
(** Create an in-memory block device (a "ramdisk") with a given name,
    total size in sectors and sector size. Two calls to [connect] with the
    same name will return the same block device *)

val destroy: name:string -> unit
(** Destroy removes an in-memory block device. Subsequent calls to
    [connect] will create a fresh empty device. *)

val connect: name:string -> [ `Ok of t | `Error of error ] Lwt.t

val resize : t -> int64 -> [ `Ok of unit | `Error of error ] io
(** [resize t new_size_sectors] attempts to resize the connected device
    to have the given number of sectors. If successful, subsequent calls
    to [get_info] will reflect the new size. *)
