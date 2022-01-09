############################
# STEP 1 build executable binary
############################
# FROM golang:alpine AS builder
FROM public.ecr.aws/bitnami/golang:latest as builder
RUN update-ca-certificates
# RUN apk update && apk add --no-cache git
# Create appuser.
ENV USER=appuser
ENV UID=10001 
# See https://stackoverflow.com/a/55757473/12429735RUN 
RUN adduser \    
    --disabled-password \    
    --gecos "" \    
    --home "/nonexistent" \    
    --shell "/sbin/nologin" \    
    --no-create-home \    
    --uid "${UID}" \    
    "${USER}"
WORKDIR $GOPATH/src/github.com/prabhatsharma/go-stars/
COPY . .
# Fetch dependencies.
# Using go get.
RUN go get -d -v

RUN export VERSION=`git describe --tags --always`
RUN export BUILD_DATE=`date -u '+%Y-%m-%d_%I:%M:%S%p-GMT'`
RUN export COMMIT_HASH=`git rev-parse HEAD`

RUN export LDFLAGS="-w -s -X github.com/prabhatsharma/go-stars/pkg/meta/v1.Version=${VERSION} -X github.com/prabhatsharma/go-stars/pkg/meta/v1.BuildDate=${BUILD_DATE} -X github.com/prabhatsharma/go-stars/pkg/meta/v1.CommitHash=${COMMIT_HASH}"

# Using go mod.
# RUN go mod download
# RUN go mod verify
# Build the binary.
# to tackle error standard_init_linux.go:207: exec user process caused "no such file or directory" set CGO_ENABLED=0. 
# CGO_ENABLED=0 builds a statically linked binary.
# docs for -ldflags at https://pkg.go.dev/cmd/link
#       -w : Omit the DWARF symbol table.
#       -s : Omit the symbol table and debug information.
#       Omit the symbol table and debug information will reduce the binary size.
# RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -o go-stars cmd/go-stars/main.go
RUN CGO_ENABLED=0 go build -ldflags="$LDFLAGS" -o go-stars main.go
############################
# STEP 2 build a small image
############################
# FROM public.ecr.aws/lts/ubuntu:latest
FROM scratch
# Import the user and group files from the builder.
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group

# Copy the ssl certificates
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

# Copy our static executable.
COPY --from=builder  /go/src/github.com/prabhatsharma/go-stars/go-stars /go/bin/go-stars

# Use an unprivileged user.
USER appuser:appuser
# Port on which the service will be exposed.
EXPOSE 4080
# Run the go-stars binary.
ENTRYPOINT ["/go/bin/go-stars"]
