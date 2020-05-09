build:
	@docker build -t certpub/verifier .

shell:
	@docker run --rm -it \
		-v $$(pwd):/work \
		-w /work \
		-u $$(id -u) \
		ruby:2.7.1 \
		sh