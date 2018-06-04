defmodule Uptime.Check do
  defstruct pid: nil,
            url: nil,
            failed_checks: 0,
            notify_number: nil,
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
      sender.send_message(get_message(check))
      %{check | alert_sent: true}
    else
      check
    end
  end

  defp get_message(%__MODULE__{notify_number: to, url: url, failed_checks: fail_no}) do
    %Uptime.Message{
      to: to,
      msg: "Failed #{fail_no} checks for #{url}"
    }
  end
end
