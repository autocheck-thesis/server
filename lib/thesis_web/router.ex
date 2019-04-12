defmodule ThesisWeb.Router do
  use ThesisWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug Phoenix.LiveView.Flash
  end

  scope "/api", ThesisWeb do
    pipe_through :api
  end

  scope "/grade", ThesisWeb do
    get "/", GradeController, :grade
    post "/", GradeController, :grade_post
  end

  scope "/", ThesisWeb do
    pipe_through :browser

    get "/", IndexController, :index
    get "/index", IndexController, :index
    get "/lti", IndexController, :index
    post "/", IndexController, :launch
    post "/lti", IndexController, :launch

    get "/work", IndexController, :work

    get "/submission/submit", SubmissionController, :index
    get "/submission/submit/:assignment_id", SubmissionController, :index
    post "/submission/submit/:assignment_id", SubmissionController, :submit
    get "/submission/download/:token_id", SubmissionController, :download
    get "/submission/:id", SubmissionController, :show

    get "/assignment/:assignment_id", AssignmentController, :index
    post "/assignment/:assignment_id", AssignmentController, :submit
  end
end
