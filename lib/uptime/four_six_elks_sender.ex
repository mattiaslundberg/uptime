defmodule Uptime.FourSixElksSender do
  use GenServer

  alias Uptime.Message

  @endpoint "https://api.46elks.com/a1/SMS"

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def send_message(msg = %Message{}) do
    GenServer.cast(__MODULE__, msg)
  end

  # Callbacks

  def init(_) do
    {:ok, nil}
  end

  def handle_cast(msg = %Message{}, _) do
    case HTTPotion.post(
           @endpoint,
           body: Message.post_data(msg),
           ibrowse: [
             basic_auth:
               {to_charlist(Application.get_env(:uptime, :elks_username)),
                to_charlist(Application.get_env(:uptime, :elks_key))}
           ]
         ) do
      r = %HTTPotion.Response{status_code: 202} ->
        IO.inspect(r)
        {:noreply, {}}

      error ->
        IO.inspect(error)
        {:noreply, {}}
    end
  end
end
