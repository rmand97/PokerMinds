defmodule PokerMindWeb.GameController do
  use PokerMindWeb, :controller

  alias PokerMind.Engine.Match.Coordinator
  alias PokerMind.Engine.Match.Game

  def next_games(conn, %{"player_id" => player_id, "suite_id" => suite_id}) do
    # TODO:
    # player_id, what player is asking for data. We need this to filter it properly
    # suite_id, what suite is the player asking for their next games in

    # coordinator_id = Coordinator.id(suite_id)
    # games =
    #   coordinator_id
    #   |> Coordinator.next_games(player_id)
    #   |> filter_state(player_id) # This function is not defined yet

    json(conn, %{data: "games"})
  end

  def next_games(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "player_id and suite_id are required"})
  end

  def perform_action(conn, %{"player_id" => player_id, "game_id" => game_id, "action" => action}) do
    # TODO:
    # Game.apply_action(game_id, action, player_id)
    # give user a response

    json(conn, %{data: "ok"})
  end

  def perform_action(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "player_id, game_id and action are required"})
  end
end
