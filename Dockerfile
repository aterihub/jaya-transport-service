###################
# BUILD
###################

FROM golang:1.23-alpine AS builder

ENV GOOS=linux
ENV CGO_ENABLED=0

WORKDIR /app

# Manifests first so the module download layer survives source-only changes.
COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN go build -ldflags="-s -w" -o jaya-transport-service

###################
# RUN
###################

FROM alpine:3.20

RUN apk --no-cache add ca-certificates tzdata \
  && adduser -D -H -u 10001 app

WORKDIR /app

COPY --from=builder /app/jaya-transport-service .

USER app

# Purely an MQTT/HTTP client -- it opens no listening socket, so there is
# nothing to EXPOSE and no endpoint to health-check. Liveness is inferred from
# the process staying alive; it log.Fatalf()s on any failed startup dependency.
CMD ["./jaya-transport-service"]
