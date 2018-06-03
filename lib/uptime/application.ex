defmodule Uptime.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Uptime.FourSixElksSender, nil},
    ]

    opts = [strategy: :one_for_one, name: Uptime.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
