defmodule Uptime do
  alias Uptime.{Checkers, Check}

  def add_new_check(url, notify_number, expected_code, elks_username, elks_key) do
    check = %Check{
      url: url,
      notify_number: notify_number,
      expected_code: expected_code,
      elks_username: elks_username,
      elks_key: elks_key
    }

    Checkers.add_check(check)
  end
end
