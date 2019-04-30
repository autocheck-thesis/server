defmodule ThesisWeb.Router do
  use ThesisWeb, :router
  import ThesisWeb.Auth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug Phoenix.LiveView.Flash
  end

  pipeline :json_client do
    plug :accepts, ["json"]
    plug :fetch_session
  end

  pipeline :auth do
    plug :check_auth
  end

  scope "/", ThesisWeb do
    pipe_through :browser

    get "/", IndexController, :index
    get "/index", IndexController, :index
    get "/lti", IndexController, :index
    post "/", IndexController, :launch
    post "/lti", IndexController, :launch
  end

  scope "/", ThesisWeb do
    pipe_through [:browser, :auth]

    # TODO: Grade controller is currently broken
    # get "/grade", GradeController, :grade
    # post "/grade", GradeController, :grade_post

    get "/submission/submit", SubmissionController, :index
    get "/submission/submit/:assignment_id", SubmissionController, :index
    post "/submission/submit/:assignment_id", SubmissionController, :submit
    get "/submission/:id", SubmissionController, :show

    get "/assignment/:assignment_id", AssignmentController, :index
    post "/assignment/:assignment_id", AssignmentController, :submit
  end

  scope "/", ThesisWeb do
    pipe_through [:json_client]
    get "/submission/download/:token_id", SubmissionController, :download
  end
end
