defmodule Uptime.Check do
  defstruct [:pid, :url]

  def perform_check(check = %__MODULE__{}) do
    # FIXME: Implement
    check
  end

  def maybe_send_notification(check = %__MODULE__{}) do
    # FIXME: Implement
    check
  end
end
