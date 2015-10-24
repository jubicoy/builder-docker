SHELL := /bin/bash

all: container

container:
	docker build -t jubicoy/builder .

push:
	docker push jubicoy/builder
