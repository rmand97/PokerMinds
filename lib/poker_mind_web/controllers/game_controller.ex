defmodule PokerMindWeb.GameController do
  use PokerMindWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias PokerMind.Engine.Match.Coordinator
  alias PokerMind.Engine.Match.Game
  alias PokerMind.Engine.Match.Supervisor, as: MatchSupervisor
  alias PokerMind.Engine.TableState
  alias PokerMind.Engine.TableState.PlayerState

  alias PokerMindWeb.Schemas.ActionRequest
  alias PokerMindWeb.Schemas.GameResponse
  alias PokerMindWeb.Schemas.SuitesResponse

  operation(:suites,
    summary: "List all match suites",
    responses: [
      ok: {"List of match suites and associated players", "application/json", SuitesResponse}
    ]
  )

  def suites(conn, _params) do
    json(conn, %{data: MatchSupervisor.all_match_suites()})
  end

  operation(:next_games,
    summary: "List upcoming games",
    parameters: [
      player_id: [in: :query, description: "Your ID", type: :string],
      suite_id: [in: :query, description: "Suite ID", type: :string]
    ],
    responses: [
      ok: {"List of games", "application/json", GameResponse}
    ]
  )

  def next_games(conn, %{"player_id" => player_id, "suite_id" => suite_id}) do
    coordinator_id = Coordinator.id(suite_id)

    case Coordinator.next_games(coordinator_id, player_id) do
      {:error, msg} when msg in [:game_not_found, :coordinator_not_found] ->
        error_msg = msg |> to_string() |> String.replace("_", " ")

        conn
        |> put_status(:not_found)
        |> json(%{error: error_msg})

      games ->
        mapped_games = Enum.map(games, fn game -> map_tablestate(game, player_id) end)
        json(conn, %{data: mapped_games})
    end
  end

  def next_games(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "player_id and suite_id are required"})
  end

  operation(:perform_action,
    summary: "Submit a player action",
    request_body: {"Action params", "application/json", ActionRequest},
    responses: [
      ok: {"Updated game state", "application/json", PokerMindWeb.Schemas.Game}
    ]
  )

  def perform_action(conn, %{
        "player_id" => player_id,
        "game_id" => game_id,
        "action" => action
      }) do
    case Game.apply_action(game_id, action, player_id) do
      {:ok, state} ->
        mapped_state = %{state | game: map_tablestate(state.game, player_id)}
        json(conn, %{data: mapped_state})

      {:error, :game_not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Game not found"})

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: to_string(reason)})

      other ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "unexpected response: #{inspect(other)}"})
    end
  end

  def perform_action(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "player_id, game_id and action are required"})
  end

  # TODO: This is a draft
  defp map_playerstate(%PlayerState{} = player, calling_player_id) do
    mapped_player_state = %{
      id: player.id,
      remaining_chips: player.remaining_chips,
      state: player.state,
      has_acted: player.has_acted,
      current_bet: player.current_bet
    }

    if player.id == calling_player_id do
      Map.put(mapped_player_state, :current_hand, player.current_hand)
    else
      mapped_player_state
    end
  end

  defp map_tablestate(%TableState{} = tablestate, player_id) do
    player =
      tablestate.players
      |> Enum.find(fn player -> player.id == player_id end)
      |> map_playerstate(player_id)

    other_players =
      tablestate.players
      |> Enum.filter(fn player -> player.id != player_id end)
      |> Enum.map(fn player -> map_playerstate(player, player_id) end)

    %{
      id: tablestate.id,
      player: player,
      other_players: other_players,
      phase: tablestate.phase,
      pot: tablestate.pot,
      community_cards: tablestate.community_cards,
      current_player_id: tablestate.current_player_id,
      highest_raise: tablestate.highest_raise
    }
  end
end
