defmodule Thesis.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Honeydew.EctoPollQueue
  alias Honeydew.FailureMode.ExponentialRetry
  alias Thesis.Repo
  alias Thesis.Submissions.Job
  alias Thesis.Submissions.JobWorker

  def start(_type, _args) do
    # List all child processes to be supervised
    children = Application.get_env(:thesis, :children)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Thesis.Supervisor]
    {:ok, supervisor} = Supervisor.start_link(children, opts)

    :ok =
      Honeydew.start_queue(:run_jobs,
        queue: {EctoPollQueue, [schema: Job, repo: Repo, poll_interval: 1]},
        failure_mode: {ExponentialRetry, base: 3, times: 3}
      )

    :ok = Honeydew.start_workers(:run_jobs, JobWorker, num: 1)

    {:ok, supervisor}
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ThesisWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
