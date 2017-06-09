FROM golang:alpine as build
MAINTAINER matthew@walster.org
LABEL maintainer "matthew@walster.org"
RUN mkdir -p /go/src/ipd
WORKDIR /go/src/ipd

# Get the latest Maxmind database files
# We do this early so that intermediate build caches are not invalidated often
ADD http://geolite.maxmind.com/download/geoip/database/GeoLite2-Country.mmdb.gz /go/src/ipd
ADD http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.mmdb.gz /go/src/ipd
RUN gzip -d GeoLite2-Country.mmdb.gz
RUN gzip -d GeoLite2-City.mmdb.gz

# Fetch dependencies, vet, test, build
RUN apk --no-cache add ca-certificates git
COPY . /go/src/ipd
RUN go get -d -v ./...
RUN go vet ./...
RUN go test ./...
RUN go install -v

# Take the good bits from the build, for a smaller distributable container
FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=build /go/src/ipd/GeoLite2-Country.mmdb /go/src/ipd/GeoLite2-City.mmdb ./
COPY --from=build /go/bin/ipd ./
EXPOSE 8080
CMD ["./ipd","-f=GeoLite2-Country.mmdb","-c=GeoLite2-City.mmdb","-p","-r","-L=debug"]
