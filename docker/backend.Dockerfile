# Build stage
FROM hexpm/elixir:1.15.7-erlang-26.1.2-alpine-3.18.4 AS build

# Install build dependencies
RUN apk add --no-cache build-base npm git python3

# Set build ENV
ENV MIX_ENV=prod

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set work dir
WORKDIR /app

# Copy mix files
COPY packages/backend/mix.exs packages/backend/mix.lock ./
RUN mix deps.get --only prod
RUN mkdir config

# Copy compile-time config files before we compile dependencies
COPY packages/backend/config/config.exs packages/backend/config/prod.exs config/

# Compile dependencies
RUN mix deps.compile

# Copy application files
COPY packages/backend/priv priv
COPY packages/backend/lib lib

# Compile the release
RUN mix compile

# Copy runtime config
COPY packages/backend/config/runtime.exs config/

# Assemble the release
RUN mix release

# Runtime stage
FROM alpine:3.18

# Install runtime dependencies
RUN apk add --no-cache openssl ncurses-libs

# Set environment
ENV MIX_ENV=prod

# Create app user
RUN addgroup -g 1000 -S phoenix && \
    adduser -S phoenix -u 1000 -G phoenix

# Set work directory
WORKDIR /app

# Set runner ENV
RUN chown phoenix:phoenix /app

# Copy the release
COPY --from=build --chown=phoenix:phoenix /app/_build/prod/rel/collaborative_editor ./

USER phoenix

# Expose port
EXPOSE 4000

# Start the release
CMD ["bin/collaborative_editor", "start"]