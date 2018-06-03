defmodule Uptime.FourSixElksSender do
  use GenServer

  require Logger

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
    msg
    |> do_post()
    |> handle_response(msg)
  end

  defp handle_response(%HTTPotion.Response{status_code: 200}, _msg) do
    Logger.info("Successfully sent message")
    {:noreply, {}}
  end

  defp handle_response(response, msg) do
    Logger.error("Failed to send message")
    {:noreply, {}}
  end

  defp do_post(msg = %Message{}) do
    HTTPotion.post(
      @endpoint,
      body: Message.post_data(msg),
      ibrowse: get_auth()
    )
  end

  defp get_auth() do
    [
      basic_auth: {
        to_charlist(Application.get_env(:uptime, :elks_username)),
        to_charlist(Application.get_env(:uptime, :elks_key))
      }
    ]
  end
end
