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
    pipe_through(:browser)

    get("/", PageController, :index)
  end

  scope "/api", UptimeGuiWeb do
    pipe_through(:api)

    post("/login", AuthController, :index)
  end
end
