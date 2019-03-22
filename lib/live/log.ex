defmodule ThesisWeb.LogLiveView do
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
      <h2>Welcome <%= @user_id %></h2>
      <form phx-change="change" phx-submit="start"<%= if @status != "Waiting to start" do %> disabled<%= end %>>
        Image:
        <select name="image">
          <%= for image <- @images do %><option<%= if image == @image do %> selected<% end %>><%= image %></option><% end %>
        </select>
        <button>Start</button>
      </form>
      <div>Status: <%= @status %></div>
      <h2>Build log:</h2>
      <pre><code><%= for line <- @log_lines do %><%= line %><%= end %></code></pre>
    """
  end

  def mount(session, socket) do
    IO.inspect(session)

    {:ok,
     assign(socket,
       log_lines: [],
       status: "Waiting to start",
       user_id: session[:user_id],
       images: session[:images],
       image: hd(session[:images])
     )}
  end

  def handle_info({:log, %{out: out}} = _reply, socket) do
    {:noreply, update(socket, :log_lines, &(&1 ++ [out]))}
  end

  def handle_info({:log, %{err: err}} = _reply, socket) do
    {:noreply, update(socket, :log_lines, &(&1 ++ [err]))}
  end

  def handle_info({:done, %{job: _job}} = _reply, socket) do
    {:noreply, assign(socket, status: "Done")}
  end

  def handle_info({:error, %RuntimeError{} = _error} = _reply, socket) do
    {:noreply, assign(socket, status: "Something went wrong")}
  end

  def handle_event("start", _value, socket) do
    if socket.assigns[:image] in socket.assigns[:images] do
      start(socket.assigns[:image])
      {:noreply, assign(socket, status: "Started", log_lines: [])}
    else
      {:noreply, socket}
    end
  end

  def handle_event("change", %{"image" => image} = _value, socket) do
    {:noreply, assign(socket, image: image)}
  end

  defp start(image) do
    {:ok, worker} = Thesis.JobWorker.start_link()

    Thesis.JobWorker.process(worker, %Thesis.Job{
      id: 1,
      image: image,
      cmd: [
        "sh",
        "-c",
        """
        cat /etc/os-release
        """
      ]
    })
  end
end
