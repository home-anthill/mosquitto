.DEFAULT_GOAL := build

lint:
	# use staticcheck, because golint has been deprecated
	staticcheck ./...
.PHONY:lint

vet:
	go vet ./...
	shadow ./...
.PHONY:vet

check:
	# find vulnerabilities
	govulncheck ./...
.PHONY:check

deps:
	go install golang.org/x/tools/go/analysis/passes/shadow/cmd/shadow@latest
	go install honnef.co/go/tools/cmd/staticcheck@latest
	go install golang.org/x/vuln/cmd/govulncheck@latest
	go get -u
	go mod tidy
.PHONY: deps
