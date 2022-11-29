## v3.0.2 (2022-11-29)

* Document optional buffer size requirement (#54 @reynir)

## v3.0.1 (2022-09-15)

* Add Mirage_block.pp_info (#51 @reynir)
* Use GitHub actions for testing on windows and macos (retire AppVeyor)
* Remove io-page dependency (#52 @hannesm)

## v3.0.0 (2021-11-18)

* Remove Mirage_block_lwt module (#50 @hannesm)
* Remove dependency of mirage-device (#50 @hannesm)

## v2.0.1 (2019-11-04)

* provide deprecated Mirage_block_lwt for smooth transition (#48 @hannesm)

## v2.0.0 (2019-10-22)

- remove mirage-block-lwt, specialise mirage-block to Lwt.t and Cstruct.t (#46 @hannesm)
- move combinators to mirage-block-combinators (#46 @hannesm)
- raise lower OCaml bound to 4.06.0 (#46 @hannesm)

## v1.2.0 (2019-02-03)
- port to dune from jbuilder (@avsm)
- upgrade opam metadata to 2.0 (@avsm)
- switch to dune-release from topkg (@avsm)
- test OCaml 4.07 as well (@avsm)

## 1.1.0 (2017-05-22)

- `resize` should be able to return `write_error`
- update `appveyor.yml`
- build with `jbuilder`

## 1.0.0 (2016-12-21)

- Import `V1.BLOCK` from `mirage-types` into `Mirage_block.S` (@samoht)
- Import `V1_LWT.BLOCK` from `mirage-types-lwt` into `Mirage_bloc_lwt.S` (@samoht)

### 0.2 (2015-11-09)

- add `Error.string_of_error`
- clarify that `fold_mapped` callbacks use sectors, not bytes
- bugfix `fold_mapped_s`
- `fold_unmapped_s` should not return the empty buffers: lengths are enough

### 0.1 (2015-11-03)

- initial version
