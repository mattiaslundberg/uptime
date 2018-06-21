defmodule Uptime do
  alias Uptime.{Checkers, Check}

  def add_new_check(url, notify_numbers, expected_code, elks_username, elks_key) do
    check = %Check{
      url: url,
      notify_numbers: notify_numbers,
      expected_code: expected_code,
      elks_username: elks_username,
      elks_key: elks_key
    }

    Checkers.add_check(check)
  end
end
