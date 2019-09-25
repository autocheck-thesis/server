defmodule Autocheck.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Honeydew.EctoPollQueue
  # alias Honeydew.FailureMode.ExponentialRetry
  alias Honeydew.FailureMode.Abandon
  alias Autocheck.Repo
  alias Autocheck.Submissions.Job
  alias Autocheck.Coderunner
  alias Autocheck.Assignments.GradePassbackResult
  alias Autocheck.GradePassback

  def start(_type, _args) do
    # List all child processes to be supervised
    children = Application.get_env(:autocheck, :children)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Autocheck.Supervisor]
    {:ok, supervisor} = Supervisor.start_link(children, opts)

    if Mix.env() != :test do
      :ok =
        Honeydew.start_queue(:run_jobs,
          queue: {EctoPollQueue, [schema: Job, repo: Repo, poll_interval: 1]},
          failure_mode: Abandon
          # failure_mode: {ExponentialRetry, base: 3, times: 3}
        )

      Honeydew.start_queue(:grade_passback,
        queue: {EctoPollQueue, [schema: GradePassbackResult, repo: Repo, poll_interval: 1]},
        failure_mode: Abandon
        # failure_mode: {ExponentialRetry, base: 3, times: 3}
      )

      :ok = Honeydew.start_workers(:run_jobs, Coderunner, num: 2)
      :ok = Honeydew.start_workers(:grade_passback, GradePassback, num: 10)
    end

    {:ok, supervisor}
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    AutocheckWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
