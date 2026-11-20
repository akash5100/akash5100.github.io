FROM hugomods/hugo:debian-dart-sass-go

RUN apt-get update && \
    apt-get install -y --no-install-recommends git ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /src
EXPOSE 1313

ENTRYPOINT ["hugo"]
CMD ["server", "--bind", "0.0.0.0", "--buildDrafts", "--poll", "700ms", "--navigateToChanged"]
