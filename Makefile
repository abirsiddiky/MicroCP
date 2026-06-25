build:
	go build -ldflags="-s -w" -o microcp ./cmd/microcp

run:
	go run ./cmd/microcp

dev:
	GIN_MODE=debug go run ./cmd/microcp

test:
	go test ./...

clean:
	rm -f microcp

install: build
	sudo cp microcp /opt/microcp/microcp
	sudo systemctl restart microcp
