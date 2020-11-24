FROM golang:1.15.5-alpine3.12 as build

ENV GOOS=linux
ENV GO111MODULE=on

WORKDIR /src

COPY . .
RUN env CGO_ENABLED=0 go build -o /bin/app

FROM gcr.io/distroless/static as run
COPY --from=build /bin/app /app
CMD ["/app"]