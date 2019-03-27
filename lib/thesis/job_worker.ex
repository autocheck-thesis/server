defmodule Thesis.JobWorker do
  require Logger
  import Thesis.Helpers

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

  defp receive_loop(job) do
    receive do
      reply ->
        Thesis.JobWorker.QueueBroadcaster.notify(:lol, reply)

        # Keep listening for more replies
        with %Docker.AsyncReply{reply: {:chunk, _chunk}} <- reply do
          receive_loop(job)
        end
    end
  end

  def process(docker_conn, %Thesis.Job{} = job) do
    Phoenix.PubSub.broadcast(Thesis.PubSub, job_topic(job), {:reply, "alive"})

    case Docker.Container.create(docker_conn, "test", %{
           Cmd: job.cmd,
           Image: job.image,
           HostConfig: %{AutoRemove: true, Binds: ["#{job.filepath}:/tmp/submission:ro"]}
         }) do
      {:ok, %{"Id" => id}} ->
        Docker.Container.start(docker_conn, id)
        Docker.Container.follow(docker_conn, id)

        receive_loop(job)

      {:error, error} ->
        Phoenix.PubSub.broadcast(Thesis.PubSub, job_topic(job), {:error, error})
    end
  end
end

defmodule Thesis.JobWorker.QueueBroadcaster do
  use GenStage

  def start_link(name) do
    GenStage.start_link(__MODULE__, :ok, name: name)
  end

  def notify(name, event) do
    GenStage.cast(name, {:notify, event})
  end

  def init(:ok) do
    {:producer, {:queue.new(), 0}, dispatcher: GenStage.BroadcastDispatcher}
  end

  def handle_cast({:notify, event}, {queue, pending_demand}) do
    queue = :queue.in(event, queue)
    dispatch_events(queue, pending_demand, [])
  end

  def handle_demand(incoming_demand, {queue, pending_demand}) do
    dispatch_events(queue, incoming_demand + pending_demand, [])
  end

  defp dispatch_events(queue, 0, events) do
    {:noreply, Enum.reverse(events), {queue, 0}}
  end

  defp dispatch_events(queue, demand, events) do
    case :queue.out(queue) do
      {{:value, event}, queue} ->
        dispatch_events(queue, demand - 1, [event | events])

      {:empty, queue} ->
        {:noreply, Enum.reverse(events), {queue, demand}}
    end
  end
end

defmodule Thesis.JobWorker.QueueConsumer do
  use GenStage

  def start_link() do
    GenStage.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    {:consumer, :ok, subscribe_to: [Thesis.JobWorker.QueueBroadcaster]}
  end

  def handle_events(events, _from, state) do
    for event <- events do
      IO.inspect({self(), event})
    end

    {:noreply, [], state}
  end
end
