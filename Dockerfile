FROM --platform=$BUILDPLATFORM quay.io/projectquay/golang:1.27 AS builder

ARG TARGETOS
ARG TARGETARCH
ARG VERSION=dev

WORKDIR /go/src/app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN make build TARGETOS=${TARGETOS} TARGETARCH=${TARGETARCH} VERSION=${VERSION}

#
FROM scratch AS linux
WORKDIR /
COPY --from=builder /go/src/app/kbot .
COPY --from=builder /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem /etc/ssl/certs/ca-certificates.crt
ENTRYPOINT ["./kbot"]


FROM mcr.microsoft.com/windows/nanoserver:ltsc2022 AS windows
WORKDIR C:/app
COPY --from=builder /go/src/app/kbot.exe .
ENTRYPOINT ["C:\\app\\kbot.exe"]


FROM ${TARGETOS}
