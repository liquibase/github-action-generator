SHELL=/bin/bash

PHONY: build docker generate create-list

build:
	go build -o protoc-gen-liquibase

docker:
	docker build -t liquibase-protobuf-generator:$(VERSION) . --build-arg VERSION=$(VERSION)

create-list: docker
	docker run --rm -v $(PWD):/proto liquibase-protobuf-generator:$(VERSION) --output-file=commands.json list-commands

generate: build docker
	docker run --rm -v $(PWD):/proto liquibase-protobuf-generator:$(VERSION) generate-protobuf --target-command="$(COMMAND)" --output-dir /proto
	PATH=$(PWD):$(PATH) ./scripts/create-action.sh "$(COMMAND)" $(VERSION)
	rm global_options.proto