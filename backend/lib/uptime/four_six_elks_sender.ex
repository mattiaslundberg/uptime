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
    |> parse_response(msg)
    |> send_reply()
  end

  defp send_reply(true) do
    Logger.info("Successfully sent message")

    {:noreply, {}}
  end

  defp send_reply(_) do
    Logger.error("Failed to send message")
    {:noreply, {}}
  end

  defp parse_response(%HTTPotion.Response{status_code: 200, body: body}, _msg) do
    case Poison.decode(body) do
      {:ok, parser} ->
        parser["status"] == "created"

      _ ->
        false
    end
  end

  defp parse_response(_response, _msg), do: false

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
