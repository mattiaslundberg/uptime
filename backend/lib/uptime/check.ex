defmodule Uptime.Check do
  defstruct pid: nil,
            url: nil,
            elks_username: nil,
            elks_key: nil,
            check_interval: 5 * 60 * 1000,
            failed_checks: 0,
            notify_numbers: [],
            alert_sent: false,
            expected_code: 200

  @required_fails 3

  def perform_check(check = %__MODULE__{expected_code: expected_code}) do
    case HTTPotion.get(check.url) do
      %HTTPotion.Response{status_code: ^expected_code} ->
        %{check | alert_sent: false, failed_checks: 0}

      _ ->
        %{check | failed_checks: check.failed_checks + 1}
    end
  end

  def maybe_send_notification(check = %__MODULE__{}, sender \\ Uptime.FourSixElksSender) do
    if check.failed_checks >= @required_fails and not check.alert_sent do
      check
      |> get_messages()
      |> Enum.map(fn msg -> sender.send_message(msg, check) end)

      %{check | alert_sent: true}
    else
      check
    end
  end

  def get_auth(check = %__MODULE__{}) do
    [
      basic_auth: {
        to_charlist(check.elks_username),
        to_charlist(check.elks_key)
      }
    ]
  end

  defp get_messages(%__MODULE__{notify_numbers: numbers, url: url, failed_checks: fail_no}) do
    Enum.map(numbers, fn number ->
      %Uptime.Message{
        to: number,
        msg: "Failed #{fail_no} checks for #{url}"
      }
    end)
  end
end
