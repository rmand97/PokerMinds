defmodule PokerMind.Engine.SupervisorTest do
  use ExUnit.Case, async: true

  @genservers [
    PokerMind.Engine.Supervisor,
    PokerMind.Engine.Registry,
    PokerMind.Engine.Match.Supervisor
  ]

  setup_all do
    Application.ensure_all_started(:poker_mind)
    :ok
  end

  describe "PokerMind.Engine.Supervisor" do
    for genserver <- @genservers do
      test "process: #{inspect(genserver)} is started and alive" do
        pid = Process.whereis(unquote(genserver))
        assert is_pid(pid)
        assert Process.alive?(pid)
      end
    end
  end
end
