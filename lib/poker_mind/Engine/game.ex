defmodule PokerMind.Engine.Game do
  defstruct [:players, :id]

  def add_player(%__MODULE__{} = gamestate, new_player) do
    current_players = gamestate.players

    updated_players = [new_player | current_players]

    Map.put(gamestate, :players, updated_players)
  end
end
