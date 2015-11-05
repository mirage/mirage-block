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

 type error = [
   | `Unknown of string
   | `Unimplemented
   | `Is_read_only
   | `Disconnected
 ]

let string_of_error = function
   | `Unknown x -> Printf.sprintf "Unknown %s" x
   | `Unimplemented -> "Operation is not implemented"
   | `Is_read_only -> "Block device is read-only"
   | `Disconnected -> "Block device is disconnected"

exception Error of error

 type 'a result = [
   | `Ok of 'a
   | `Error of error
 ]

 let ok_exn = function
   | `Ok x -> x
   | `Error error -> raise (Error error)

module Monad = Mirage_block_monad
