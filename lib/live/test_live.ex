defmodule ThesisWeb.TestLiveView do
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
    <div class="">
      <div>
        <%= @time %>
      </div>
    </div>
    """
  end

  def mount(_session, socket) do
    if connected?(socket), do: Process.send_after(self(), :tick, 1000)
    {:ok, assign(socket, time: 0)}
  end

  def handle_info(:tick, socket) do
    Process.send_after(self(), :tick, 1000)
    {:noreply, update(socket, :time, &(&1 + 1))}
  end
end
