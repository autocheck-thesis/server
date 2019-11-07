use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :autocheck, AutocheckWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# config :eventstore, EventStore.Storage,
#   serializer: EventStore.TermSerializer,
#   username: "postgres",
#   password: "postgres",
#   database: "autocheck_test_events",
#   hostname: "server_db_1.docker",
#   pool_size: 1,
#   pool_overflow: 0

# config :autocheck, Autocheck.Repo,
#   database: "autocheck_test",
#   username: "postgres",
#   password: "postgres",
#   hostname: "server_db_1.docker"

# config :autocheck,
#   submission_download_hostname: "http://hostmachine.docker:4000"
