defmodule CollaborativeEditor.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      CollaborativeEditorWeb.Telemetry,
      # Start the Ecto repository
      CollaborativeEditor.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: CollaborativeEditor.PubSub},
      # Start the Endpoint (http/https)
      CollaborativeEditorWeb.Endpoint,
      # Start a worker by calling: CollaborativeEditor.Worker.start_link(arg)
      # {CollaborativeEditor.Worker, arg}
      # Start Presence for user tracking
      CollaborativeEditor.Presence
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CollaborativeEditor.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CollaborativeEditorWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
