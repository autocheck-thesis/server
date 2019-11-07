defmodule Autocheck.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Honeydew.EctoPollQueue
  alias Honeydew.FailureMode.Abandon
  alias Autocheck.Submissions.Job
  alias Autocheck.Coderunner
  alias Autocheck.Assignments.GradePassbackResult
  alias Autocheck.GradePassback

  def start(_type, _args) do
    supervisor_link =
      Supervisor.start_link([AutocheckWeb.Endpoint, Autocheck.Repo],
        strategy: :one_for_one,
        name: Autocheck.Supervisor
      )

    :ok =
      Honeydew.start_queue(:run_jobs,
        queue: {EctoPollQueue, [schema: Job, repo: Autocheck.Repo, poll_interval: 1]},
        failure_mode: Abandon
        # failure_mode: {ExponentialRetry, base: 3, times: 3}
      )

    Honeydew.start_queue(:grade_passback,
      queue:
        {EctoPollQueue, [schema: GradePassbackResult, repo: Autocheck.Repo, poll_interval: 1]},
      failure_mode: Abandon
      # failure_mode: {ExponentialRetry, base: 3, times: 3}
    )

    :ok = Honeydew.start_workers(:run_jobs, Coderunner, num: 2)
    :ok = Honeydew.start_workers(:grade_passback, GradePassback, num: 10)

    supervisor_link
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    AutocheckWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
