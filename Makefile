build:
	dune build @install
clean:
	dune clean
doc:
	dune build @doc
release:
	dune-release tag
	dune-release
test:
	dune runtest
.PHONY: build clean doc release test
