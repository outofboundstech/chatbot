defmodule ChatBot.RoomChannel do
  use ChatBot.Web, :channel

  alias ChatBot.FSM.QA

  def join("rooms:lobby", payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("ping", "picture", socket) do
    questions = [
      "Thank you for this image. We've forwarded the image to participating newsrooms. Make sure you delete this image from your phone, if possession of it puts you at risk. Did you take this image?",
      "What story does this image tell?",
      "Thanks again. Please delete this chat if the information puts you at risk."
    ]
    {:ok, pid} = QA.start_link(questions)
    {:reply, response} = QA.request(pid, nil)

    socket = assign(socket, :fsm, pid)
    {:reply, {:pong, %{payload: response}}, socket}
  end

  def handle_in("ping", payload, socket=%{assigns: %{fsm: pid}}) when is_pid(pid) do
    case QA.request(pid, {self, payload}) do
      {:reply, response} ->
        {:reply, {:pong, %{payload: response}}, socket}

      :final ->
        # Do some clean-up
        {:reply, {:ok, %{}}, socket}

      _ ->
        # Includes :ok, acknowledge receipt
        {:reply, {:ok, %{}}, socket}
    end
  end

  def handle_in("ping", payload, socket) do
    {:reply, {:pong, %{payload: payload}}, socket}
  end

  def handle_info({:ok, ref}, socket) do
    reply ref, {:ok, %{}}
    {:noreply, socket}
  end

  def handle_info({:reply, ref, payload}, socket) do
    reply ref, {:pong, %{payload: payload}}
    {:noreply, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (chats:lobby).
  # def handle_in("shout", payload, socket) do
  #   broadcast socket, "shout", payload
  #   {:noreply, socket}
  # end

  # This is invoked every time a notification is being broadcast
  # to the client. The default implementation is just to push it
  # downstream but one could filter or change the event.
  def handle_out(event, payload, socket) do
    push socket, event, payload
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
