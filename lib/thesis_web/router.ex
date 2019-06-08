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

    get "/submission/submit/:assignment_id", SubmissionController, :index
    post "/submission/submit/:assignment_id", SubmissionController, :submit
    get "/submission/previous/:assignment_id", SubmissionController, :previous
    get "/submission/:id", SubmissionController, :show
    get "/submission/:id/files", SubmissionController, :files

    get "/assignment/configure/:assignment_id", AssignmentController, :show
    post "/assignment/configure/:assignment_id", AssignmentController, :submit

    get "/user/:id", UserController, :show
    get "/user/submissions/:id", UserController, :submissions
  end

  scope "/", ThesisWeb do
    pipe_through [:json_client]
    get "/submission/download/:token", SubmissionController, :download
    post "/submission/download/:token/callback", SubmissionController, :download_callback
  end

  scope "/", ThesisWeb do
    pipe_through [:json_client, :auth]
    post "/assignment/validate_configuration", AssignmentController, :validate_configuration
  end
end
