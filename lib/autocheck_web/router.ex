defmodule AutocheckWeb.Router do
  use AutocheckWeb, :router
  import AutocheckWeb.Auth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :fetch_live_flash
    plug :protect_from_forgery
  end

  pipeline :json_client do
    plug :accepts, ["json"]
    plug :fetch_session
  end

  pipeline :auth do
    plug :check_auth
  end

  scope "/", AutocheckWeb do
    pipe_through :browser

    get "/", IndexController, :index
    get "/index", IndexController, :index
    get "/lti", IndexController, :index
    post "/", IndexController, :launch
    post "/lti", IndexController, :launch
  end

  scope "/", AutocheckWeb do
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

    get "/assignment/remove_all_files/:assignment_id",
        AssignmentController,
        :remove_all_files

    get "/assignment/remove_file/:assignment_id/:name",
        AssignmentController,
        :remove_file

    get "/user/:id", UserController, :show
    get "/user/submissions/:id", UserController, :submissions
  end

  scope "/", AutocheckWeb do
    pipe_through [:json_client]
    get "/submission/download/:token", SubmissionController, :download
    post "/submission/download/:token/callback", SubmissionController, :download_callback
  end

  scope "/", AutocheckWeb do
    pipe_through [:json_client, :auth]
    post "/assignment/validate_configuration", AssignmentController, :validate_configuration
  end
end
