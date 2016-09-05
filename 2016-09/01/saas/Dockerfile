FROM jimmycuadra/rust:latest
LABEL name="saas"
COPY . /src
WORKDIR /src
RUN cargo build --release 
EXPOSE 80
CMD ["target/release/saas"]
