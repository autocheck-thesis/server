defmodule Thesis.JobWorker do
  defmodule Job do
    @enforce_keys [:id, :image, :cmd, :filename, :filepath, :stream_id]
    defstruct [:id, :image, :cmd, :filename, :filepath, :stream_id]
  end

  defmodule(Output, do: defstruct([:text]))
  defmodule(Done, do: defstruct([]))
  defmodule(Error, do: defstruct([:text]))

  require Logger

  defp construct_https_url(uri = %URI{}) do
    "https://#{uri.host}:#{uri.port}"
  end

  defp default_opts() do
    [
      docker_url:
        case System.get_env("DOCKER_HOST") do
          nil -> Application.get_env(:docker, :url, "https://localhost:2376")
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

  def start_link(opts \\ []) do
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

    Docker.start_link(docker_server_opts)
  end

  defp default_event(job_id), do: %EventStore.EventData{metadata: %{job_id: job_id}}

  defp pull_event(data, job_id),
    do: %EventStore.EventData{
      default_event(job_id)
      | event_type: "Thesis.JobWorker.Pull",
        data: data
    }

  defp follow_event(data, job_id),
    do: %EventStore.EventData{
      default_event(job_id)
      | event_type: "Thesis.JobWorker.Follow",
        data: data
    }

  def process(docker_conn, %Job{} = job) do
    case Docker.Image.pull(docker_conn, job.image) do
      {:ok, _} ->
        pull_loop(job)

      {:error, error} ->
        Logger.error(inspect(error))

        EventStore.append_to_stream(job.stream_id, :any_version, [
          pull_event(%Error{text: inspect(error)}, job.id)
        ])
    end

    case Docker.Container.create(docker_conn, job.id, %{
           Cmd: job.cmd,
           Image: job.image,
           HostConfig: %{AutoRemove: true, Binds: ["#{job.filepath}:/tmp/submission:ro"]}
         }) do
      {:ok, %{"Id" => id}} ->
        Docker.Container.start(docker_conn, id)
        Docker.Container.follow(docker_conn, id)

        follow_loop(job)

      {:error, error} ->
        Logger.error(inspect(error))

        EventStore.append_to_stream(job.stream_id, :any_version, [
          follow_event(%Error{text: inspect(error)}, job.id)
        ])
    end
  end

  defp pull_loop(job) do
    receive do
      %Docker.AsyncReply{reply: {:chunk, chunk}} ->
        text =
          case chunk do
            %{"status" => text} -> text
          end

        EventStore.append_to_stream(job.stream_id, :any_version, [
          pull_event(%Output{text: text}, job.id)
        ])

        pull_loop(job)

      %Docker.AsyncReply{reply: :done} ->
        EventStore.append_to_stream(job.stream_id, :any_version, [
          pull_event(%Done{}, job.id)
        ])
    end
  end

  defp follow_loop(job) do
    receive do
      %Docker.AsyncReply{reply: {:chunk, chunk}} ->
        text =
          case chunk do
            [stdout: text] -> text
            [stderr: text] -> text
          end

        EventStore.append_to_stream(job.stream_id, :any_version, [
          follow_event(%Output{text: text}, job.id)
        ])

        follow_loop(job)

      %Docker.AsyncReply{reply: :done} ->
        EventStore.append_to_stream(job.stream_id, :any_version, [
          follow_event(%Done{}, job.id)
        ])
    end
  end
end
