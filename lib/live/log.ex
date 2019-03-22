defmodule ThesisWeb.LogLiveView do
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
      <h2>Welcome <%= @user_id %></h2>
      <div>Status: <%= @status %></div>
      <button phx-click="start"<%= if @status != "Waiting to start" do %>disabled<% end %>>Start</button>
      <h2>Build log:</h2>
      <pre><code><%= for line <- @log_lines do %><%= line %><% end %></code></pre>
    """
  end

  def mount(session, socket) do
    IO.inspect(session)
    {:ok, assign(socket, log_lines: [], status: "Waiting to start", user_id: session[:user_id])}
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
    {:ok, worker} = Thesis.JobWorker.start_link()
    Thesis.JobWorker.process(worker, %Thesis.Job{id: 1})

    {:noreply, assign(socket, status: "Started")}
  end
end
