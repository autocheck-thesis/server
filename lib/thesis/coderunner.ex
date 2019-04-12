defmodule Thesis.Coderunner do
  use GenServer

  defmodule(Init, do: defstruct([]))
  defmodule(PullOutput, do: defstruct([:text]))
  defmodule(FollowOutput, do: defstruct([:text]))
  defmodule(PullDone, do: defstruct([]))
  defmodule(FollowDone, do: defstruct([:exit_code]))
  defmodule(Error, do: defstruct([:text]))

  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    opts = Keyword.merge(default_opts(), opts)

    Logger.debug("Creating link to docker with #{inspect(opts)}")

    docker_server_opts = %{
      baseUrl: Keyword.get(opts, :docker_url),
      ssl_options: [
        {:certfile, Keyword.get(opts, :docker_certfile)},
        {:keyfile, Keyword.get(opts, :docker_keyfile)},
        {:cacertfile, Keyword.get(opts, :docker_cacertfile)}
      ]
    }

    with {:ok, docker_conn} <- Docker.start_link(docker_server_opts) do
      {:ok, %{docker_conn: docker_conn, job: nil, phase: nil, container_id: nil}}
    else
      err -> err
    end
  end

  def handle_call(
        {:process, job},
        _from,
        %{
          docker_conn: docker_conn,
          job: nil,
          phase: nil,
          container_id: nil
        } = state
      ) do
    Logger.debug("Starting process of job #{job.id}")

    append_to_stream(job, %Init{})

    pull_image(docker_conn, job)
    {:reply, :ok, %{state | docker_conn: docker_conn, job: job, phase: :pulling_image}}
  end

  def handle_call({:process, job}, _from, %{job: job, phase: phase} = state) do
    Logger.debug("Attempt was made to run concurrent jobs.
      Already running job #{job.id} in phase #{phase}")

    {:reply, {:error, "Can't run concurrent jobs"}, state}
  end

  def handle_info({:error, {:servfail, code, message}}, state) do
    Logger.error("Error (#{code}) #{inspect(message)}")

    {:noreply, state}
  end

  def handle_info(
        %Docker.AsyncReply{reply: {:chunk, chunks}},
        %{job: job, phase: phase} = state
      ) do
    case phase do
      :pulling_image ->
        text = collect_pulling_chunks(chunks)

        append_to_stream(job, %PullOutput{text: text})

      :running ->
        text = collect_running_chunks(chunks)

        append_to_stream(job, %FollowOutput{text: text})
    end

    {:noreply, state}
  end

  def handle_info(
        %Docker.AsyncReply{reply: :done},
        %{docker_conn: docker_conn, phase: :pulling_image, job: job} = state
      ) do
    {:ok, container_id} = create_and_follow_container(docker_conn, job)

    append_to_stream(job, %PullDone{})

    {:noreply, %{state | phase: :running, container_id: container_id}}
  end

  def handle_info(
        %Docker.AsyncReply{reply: :done},
        %{
          docker_conn: docker_conn,
          container_id: container_id,
          phase: :running,
          job: job
        } = state
      ) do
    # Awesome, the job execution is done. Now get the status code
    res = Docker.Container.wait(docker_conn, container_id)

    {:ok, %{"StatusCode" => code}} = res

    append_to_stream(job, %FollowDone{exit_code: code})

    {:noreply, state}
  end

  def process(pid, %Thesis.Job{} = job) do
    GenServer.call(pid, {:process, job})
  end

  defp pull_image(docker_conn, job) do
    Logger.debug("Pulling image #{job.image} in job #{job.id}")
    Docker.Image.pull(docker_conn, job.image)
  end

  defp create_and_follow_container(docker_conn, job) do
    Logger.debug("Creating container in job #{job.id}")

    with {:ok, container_id} <- create_container(docker_conn, job),
         :ok <- Docker.Container.start(docker_conn, container_id),
         {:ok, _pid} <- Docker.Container.follow(docker_conn, container_id) do
      {:ok, container_id}
    else
      err ->
        err
    end
  end

  defp create_container(docker_conn, job) do
    case Docker.Container.create(docker_conn, job.id, %{
           Cmd: ["sh", "-c", job.cmd],
           Image: job.image,
           HostConfig: %{AutoRemove: true}
         }) do
      {:ok, %{"Id" => id}} -> {:ok, id}
      err -> err
    end
  end

  defp collect_pulling_chunks(chunks) when is_list(chunks) do
    Enum.into(chunks, [], &collect_pulling_chunks(&1))
  end

  defp collect_pulling_chunks(chunk) do
    case chunk do
      %{"status" => text, "progress" => progress} -> "#{text}: #{progress}"
      %{"status" => text} -> text
    end
  end

  defp collect_running_chunks(chunks) do
    chunks
    |> Enum.into([], fn chunk ->
      text =
        case chunk do
          {:stdout, text} ->
            text

          {:stderr, text} ->
            text
        end

      # TODO: Maybe this is too aggressive
      String.trim_trailing(text)
    end)
    |> Enum.join("\n")
  end

  defp construct_https_url(uri = %URI{}) do
    "https://#{uri.host}:#{uri.port}"
  end

  defp default_opts() do
    [
      docker_url:
        case System.get_env("DOCKER_HOST") do
          nil -> Application.get_env(:docker, :url, "http://localhost:2375")
          url -> url |> URI.parse() |> construct_https_url
        end,
      docker_certfile:
        case System.get_env("DOCKER_CERT_PATH") do
          nil -> Application.get_env(:docker, :certfile, "~/.docker/cert.pem")
          path -> path <> "/cert.pem"
        end,
      docker_cacertfile:
        case System.get_env("DOCKER_CERT_PATH") do
          nil -> Application.get_env(:docker, :cacertfile, "~/.docker/ca.pem")
          path -> path <> "/ca.pem"
        end,
      docker_keyfile:
        case System.get_env("DOCKER_CERT_PATH") do
          nil -> Application.get_env(:docker, :keyfile, "~/.docker/key.pem")
          path -> path <> "/key.pem"
        end
    ]
  end

  defp append_to_stream(job, event) when not is_list(event) do
    append_to_stream(job, [event])
  end

  defp append_to_stream(job, events) do
    events =
      Enum.map(events, fn event ->
        %EventStore.EventData{
          event_type: Atom.to_string(event.__struct__),
          data: event,
          metadata: %{job_id: job.id}
        }
      end)

    EventStore.append_to_stream(job.id, :any_version, events)
  end
end
