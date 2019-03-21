defmodule ThesisWeb.Router do
  use ThesisWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", ThesisWeb do
    pipe_through :api
  end

  scope "/grade", ThesisWeb do
    get "/", GradeController, :grade
    post "/", GradeController, :grade_post
  end

  get "/", ThesisWeb.IndexController, :index
  post "/", ThesisWeb.IndexController, :launch
end
