defmodule CollaborativeEditorWeb.Router do
  use CollaborativeEditorWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {CollaborativeEditorWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # API routes for React frontend
  scope "/api", CollaborativeEditorWeb do
    pipe_through :api

    # Document management endpoints
    get "/documents", DocumentController, :index
    get "/documents/:id", DocumentController, :show
    post "/documents", DocumentController, :create
    put "/documents/:id", DocumentController, :update
    delete "/documents/:id", DocumentController, :delete
  end

  # Fallback route for React app (if serving from same domain)
  # scope "/", CollaborativeEditorWeb do
  #   pipe_through :browser

  #   get "/", PageController, :home
  #   get "/*path", PageController, :home
  # end

  # Other scopes may use custom stacks.
  # scope "/api", CollaborativeEditorWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  # if Application.compile_env(:collaborative_editor, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    # import Phoenix.LiveDashboard.Router

    # scope "/dev" do
    #   pipe_through :browser

    #   live_dashboard "/dashboard", metrics: CollaborativeEditorWeb.Telemetry
    # end
  # end
  
end
