#Go image that has everything i need to compile in my app 
FROM golang:1.25 AS build
WORKDIR /app
# copy go module files into the container
COPY go.mod go.sum ./
# download all the dependencies in go.mod and go.sum
RUN go mod download
# copy the rest of the source ccode into the contianer s app
COPY . .
#build the go project into a binary named server
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o server ./...

# start a new img based on distroless 
FROM gcr.io/distroless/base-debian12
WORKDIR /app
# copy the compiler server binary from the first stage(build) into this new img 
COPY --from=build /app/server /app/server
EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/app/server"]