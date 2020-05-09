build:
	@docker build -t certpub/verifier:dev .

verify:
	@docker run --rm -t \
		certpub/verifier:dev \
		-p 0192:984851006

shell:
	@docker run --rm -it \
		-v $$(pwd):/work \
		-w /work \
		-u $$(id -u) \
		ruby:2.7.1 \
		sh