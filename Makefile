all:
	ocaml pkg/pkg.ml build -n mirage-block -q
	ocaml pkg/pkg.ml build -n mirage-block-lwt -q

clean:
	ocaml pkg/pkg.ml clean -n mirage-block
	ocaml pkg/pkg.ml clean -n mirage-block-lwt
