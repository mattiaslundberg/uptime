alias Uptime.{Check, Message}

defmodule TestDummySender do
  setup do
    DummySender.reset()
  end

  test "set and get message" do
    m = %Message{}
    c = %Check{}
    DummySender.send_message(m, c)
    assert DummySender.get_messages() == [m]
  end

  test "reset to empty state" do
    m = %Message{}
    c = %Check{}
    DummySender.send_message(m, c)
    DummySender.reset()
    assert DummySender.get_messages() == []
  end
end
