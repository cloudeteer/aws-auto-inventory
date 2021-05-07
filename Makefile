# You can change this tag to suit your needs
TAG=$(shell date +%Y%m%d)
OS=$(shell uname -s | tr A-Z a-z)
ARCH=$(shell uname -m | tr A-Z a-z)

.PHONY: init
init:
	python3 -m venv .venv
	@( \
       . .venv/bin/activate; \
	   pip install --upgrade pip ; \
	   pip install --upgrade pyinstaller ; \
       pip install -r requirements.txt; \
    )

.PHONY: clean
clean:
	@rm -rf build/ dist/ *.spec log/ output/ build.txt __pycache__/ aai/__pycache__/ 

.PHONY: build
build: clean
	@( \
       . .venv/bin/activate; \
	   pyinstaller --name aws-auto-inventory-$(OS)-$(ARCH) --clean --onefile --hidden-import cmath --log-level=DEBUG cli.py 2> build.txt; \
    )

.PHONY: docker/build
docker/build:
	docker build -f Dockerfile -t aws-auto-inventory:$(TAG) .

.PHONY: docker/run
docker/run:
	docker container run -it "aws-auto-inventory:$(TAG)" /bin/bash

# Build the Docker image, create a container, extract the binary and copy it under dist/, stop and delete the container
.PHONY: docker/release
docker/release: docker/build
	@docker create -ti --name aws-auto-inventory aws-auto-inventory:$(TAG) bash \
	&& mkdir -p dist && docker cp aws-auto-inventory:/opt/aws-auto-inventory/dist/aws-auto-inventory-linux-amd64 dist/aws-auto-inventory-linux-amd64 \
	&& docker container stop aws-auto-inventory \
	&& docker container rm aws-auto-inventory ;\
