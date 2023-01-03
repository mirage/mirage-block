(*
 * Copyright (C) 2015-present David Scott <dave.scott@unikernel.com>
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

type error = [ `Disconnected ]

let pp_error ppf = function
  | `Disconnected -> Fmt.string ppf "Device is disconnected"

type write_error = [ error | `Is_read_only ]

let pp_write_error ppf = function
  | #error as e -> pp_error ppf e
  | `Is_read_only -> Fmt.pf ppf "attempted to write to a read-only disk"

type info = {
  read_write: bool;    (** True if we can write, false if read/only *)
  sector_size: int;    (** Octets per sector *)
  size_sectors: int64; (** Total sectors per device *)
}

let pp_info ppf { read_write; sector_size; size_sectors } =
  Format.fprintf ppf
    "@[<2>{ \
     @[Mirage_block.read_write =@ %B@];@ \
     @[sector_size =@ %d@];@ \
     @[size_sectors =@ %LdL@]@ \
     }@]"
    read_write sector_size size_sectors

module type S = sig
  type nonrec error = private [> error ]
  val pp_error: error Fmt.t
  type nonrec write_error = private [> write_error ]
  val pp_write_error: write_error Fmt.t
  type t
  val disconnect : t -> unit Lwt.t
  val get_info: t -> info Lwt.t
  val read: t -> int64 -> Cstruct.t list -> (unit, error) result Lwt.t
  val write: t -> int64 -> Cstruct.t list ->
    (unit, write_error) result Lwt.t
end

module type READ_ONLY = sig
  type nonrec error = private [> error ]
  val pp_error: error Fmt.t
  type t
  val disconnect : t -> unit Lwt.t
  val get_info : t -> info Lwt.t
  val read : t -> int64 -> Cstruct.t list -> (unit, error) result
end
