FROM dart:stable

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get
COPY lib/ ./lib/
EXPOSE 8080
CMD ["dart", "run", "lib/server.dart"]
