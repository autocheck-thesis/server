defmodule ThesisWeb.Router do
  use ThesisWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", ThesisWeb do
    pipe_through :api
  end

  post "/", ThesisWeb.IndexController, :index
end
