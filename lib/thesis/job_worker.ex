defmodule Thesis.JobWorker do
  use Agent
  require Logger

  def start_link() do
    server = %{
      baseUrl: "https://192.168.64.6:2376",
      ssl_options: [
        {:certfile, "/Users/nikteg/.docker/machine/machines/dinghy/cert.pem"},
        {:keyfile, "/Users/nikteg/.docker/machine/machines/dinghy/key.pem"}
      ]
    }

    {:ok, conn} = Docker.start_link(server)
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
        {:ok, %{"Id" => id}} =
          Docker.Container.create(conn, "test", %{
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
          })

        Docker.Container.start(conn, id)
        Docker.Container.follow(conn, id)

        loop(conn, job, pid)
      end
    )
  end
end
