defmodule UptimeGuiWeb.Router do
  use UptimeGuiWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", UptimeGuiWeb do
    # Use the default browser stack
    pipe_through(:browser)

    get("/", PageController, :index)
    post("/", PageController, :create)

    post("/login", AuthController, :login)
  end

  # Other scopes may use custom stacks.
  # scope "/api", UptimeGuiWeb do
  #   pipe_through :api
  # end
end
