defmodule Thesis.JobWorker do
  use Agent
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

    {:ok, conn} = Docker.start_link(docker_server_opts)
    Agent.start_link(fn -> conn end)
  end

  def handle_info(_msg, state) do
    IO.puts("Handle info")
    {:noreply, state}
  end

  defp loop(conn, job, pid) do
    receive do
      %Docker.AsyncReply{reply: {:chunk, [stdout: out]}} ->
        send(pid, {:log, %{job: job, out: out}})
        # Logger.debug("Sending '#{out}' to '#{inspect(pid)}'")
        loop(conn, job, pid)

      %Docker.AsyncReply{reply: :done} ->
        # Logger.debug("Sending done to '#{inspect(pid)}'")
        send(pid, {:done, %{job: job}})
    end
  end

  def process(worker, %Thesis.Job{} = job, pid \\ self()) do
    Agent.cast(
      worker,
      fn conn ->
        case Docker.Container.create(conn, "test", %{
               Cmd: [
                 "bash",
                 "-c",
                 """
                 for i in {1..5}
                 do
                   echo $i
                   sleep 1s
                 done
                 exit 100
                 """
               ],
               Image: "ubuntu",
               HostConfig: %{AutoRemove: true}
             }) do
          {:ok, %{"Id" => id}} ->
            Docker.Container.start(conn, id)
            Docker.Container.follow(conn, id)

            loop(conn, job, pid)

          {:error, error} ->
            send(pid, {:error, error})
        end
      end
    )
  end
end
