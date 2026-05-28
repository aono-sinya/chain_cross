FROM ruby:4.0.5-trixie

ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_BIN=/usr/local/bundle/bin \
    PATH=/usr/local/bundle/bin:$PATH

RUN apt-get update -qq && apt-get install -y --no-install-recommends \
      build-essential libffi-dev libyaml-dev libssl-dev \
      curl git tzdata \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY Gemfile Gemfile.lock* ./
RUN gem install bundler -v 4.0.12 && bundle install

COPY . .

EXPOSE 3000
CMD ["bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]

