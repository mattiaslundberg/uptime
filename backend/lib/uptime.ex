defmodule Uptime do
  alias Uptime.{Checkers, Check}

  def add_new_check(url, notify_number, expected_code) do
    check = %Check{
      url: url,
      notify_number: notify_number,
      expected_code: expected_code
    }

    Checkers.add_check(check)
  end
end
