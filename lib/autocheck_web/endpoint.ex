defmodule AutocheckWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :autocheck

  @session_options [
    store: :cookie,
    key: "_autocheck_key",
    signing_salt: "UG8ofbm6"
  ]

  def init(_key, config) do
    File.mkdir("uploads/")

    {:ok, config}
  end

  socket "/ws/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]]

  # socket "/ws/socket", AutocheckWeb.UserSocket,
  #   websocket: true,
  #   longpoll: false

  # Serve uploads
  plug Plug.Static,
    at: "/uploads",
    from: Path.expand("uploads/"),
    gzip: true

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :autocheck,
    gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, {:multipart, length: 550_000_000}, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options

  plug AutocheckWeb.Router
end
