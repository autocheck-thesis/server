defmodule Thesis.JobWorker do
  use Agent

  def start_link() do
    server = %{
      baseUrl: "https://192.168.64.6:2376",
      ssl_options: [
        {:certfile, "/Users/nikteg/.docker/machine/machines/dinghy/cert.pem"},
        {:keyfile, "/Users/nikteg/.docker/machine/machines/dinghy/key.pem"}
      ]
    }

    {:ok, conn} = Docker.start_link(server)
    Agent.start_link(fn -> conn end, name: __MODULE__)
  end

  def handle_info(_msg, state) do
    IO.puts("Handle info")
    {:noreply, state}
  end

  def process(worker, %Thesis.Job{} = job) do
    Agent.get(
      worker,
      fn conn ->
        {:ok, %{"Id" => id}} =
          Docker.Container.create(conn, "test", %{
            Cmd: ["bash", "-c", "sleep 1; echo hello world; exit 100"],
            Image: "ubuntu",
            HostConfig: %{AutoRemove: true}
          })

        Docker.Container.start(conn, id)
        {:ok, ref} = Docker.Container.follow(conn, id)
        {:ok, %{"StatusCode" => status_code}} = Docker.Container.wait(conn, id, :infinity)
        IO.inspect(status_code)
        job
      end
    )
  end
end
