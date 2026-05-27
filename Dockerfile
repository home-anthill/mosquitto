# syntax=docker/dockerfile:1

# Stage 1: compile the entrypoint binary
FROM golang:1.26.3-alpine AS builder

WORKDIR /build

COPY entrypoint.go .

RUN CGO_ENABLED=0 GOOS=linux go build -o entrypoint entrypoint.go


# Stage 2: hardened image
FROM dhi.io/eclipse-mosquitto:2

COPY --from=builder /build/entrypoint /entrypoint

ENTRYPOINT ["/entrypoint"]