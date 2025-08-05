defmodule CollaborativeEditorWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :collaborative_editor

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_collaborative_editor_key",
    signing_salt: "your_signing_salt_here"
  ]

  socket "/socket", CollaborativeEditorWeb.UserSocket,
    websocket: true,
    longpoll: false,
    pubsub_server: CollaborativeEditor.PubSub,
    cors: [
      origin: ["http://localhost:3000", "http://localhost:5173"], # React dev servers
      credentials: true
    ]

  # Serve at "/" the static files from "priv/static" directory.
  # Commented out for API-only mode - React frontend will handle static assets
  # plug Plug.Static,
  #   at: "/",
  #   from: :collaborative_editor,
  #   gzip: false,
  #   only: ~w(assets fonts images favicon.ico robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket,
      pubsub_server: CollaborativeEditor.PubSub
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :collaborative_editor
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug CollaborativeEditorWeb.Router
end
