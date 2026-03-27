defmodule PokerMind.EngineTest do
  alias PokerMind.Engine
  use ExUnit.Case, async: true

  test "some_func/1 - returns error" do
    refute Engine.some_func() != :error
    assert Engine.some_func() == :error
  end
end
