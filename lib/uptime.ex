defmodule Uptime do
  alias Uptime.{Checkers, Check}

  def run(url, notify_number) do
    check = %Check{url: url, notify_number: notify_number}
    Checkers.add_check(check)
  end
end
