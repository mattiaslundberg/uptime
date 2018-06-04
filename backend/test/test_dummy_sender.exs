alias Uptime.Message

defmodule TestDummySender do
  setup do
    DummySender.reset()
  end

  test "set and get message" do
    m = %Message{}
    DummySender.send_message(m)
    assert DummySender.get_messages() == [m]
  end

  test "reset to empty state" do
    m = %Message{}
    DummySender.send_message(m)
    DummySender.reset()
    assert DummySender.get_messages() == []
  end
end
