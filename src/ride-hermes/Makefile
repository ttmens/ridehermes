.PHONY: build run test lint clean migrate

APP_NAME = ride-hermes
BUILD_DIR = ./build

build:
	go build -o $(BUILD_DIR)/$(APP_NAME) ./cmd/server

run:
	go run ./cmd/server

test:
	go test ./... -v -cover

lint:
	golangci-lint run ./...

migrate:
	go run ./cmd/server --migrate

clean:
	rm -rf $(BUILD_DIR)

docker-build:
	docker build -t ridehermes/backend:latest .

docker-run:
	docker run -p 8080:8080 --env-file .env ridehermes/backend:latest
