defmodule ThesisWeb.LogLiveView do
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
      <h2>Welcome <%= @user_id %></h2>
      <div>Status: <%= @status %></div>
      <h2>Build log:</h2>
      <pre><code><%= for line <- @log_lines do %><span><%= line %></span><%= end %></code></pre>
    """
  end

  def mount(session, socket) do
    if connected?(socket) do
      {:ok, worker} = Thesis.JobWorker.start_link()

      Thesis.JobWorker.process(worker, session[:job])
    end

    {:ok,
     assign(socket,
       log_lines: [],
       status: "Waiting to start",
       user_id: session[:user_id]
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
end
