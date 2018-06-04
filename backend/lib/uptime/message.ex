defmodule Uptime.Message do
  defstruct [:to, :msg]
  @from "Uptime"

  def post_data(%__MODULE__{to: to, msg: msg}) do
    %{
      "to" => to,
      "from" => @from,
      "message" => msg
    }
    |> URI.encode_query()
  end
end
