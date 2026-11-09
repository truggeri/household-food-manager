FROM ruby:3.3.9-slim-bookworm

ENV BUNDLE_WITHOUT="development:test" \
    RAILS_ENV=production

WORKDIR /rails

RUN apt-get update -qq \
    && apt-get install --no-install-recommends -y build-essential libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

RUN SECRET_KEY_BASE_DUMMY=1 bin/rails assets:precompile

EXPOSE 3000

CMD ["sh", "-c", "bin/rails db:prepare && exec bin/rails server -b 0.0.0.0"]
