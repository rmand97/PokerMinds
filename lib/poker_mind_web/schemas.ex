defmodule PokerMindWeb.Schemas do
  alias OpenApiSpex.Schema

  defmodule Card do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "Card",
      type: :object,
      properties: %{
        rank: %Schema{type: :integer},
        suit: %Schema{type: :string}
      }
    })
  end

  defmodule Player do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "Player",
      description: "Information about a base player",
      type: :object,
      properties: %{
        id: %Schema{type: :string, description: "Player ID"},
        remaining_chips: %Schema{type: :integer, description: "Remaining Chips"},
        state: %Schema{type: :string, description: "Player State"},
        has_acted: %Schema{
          type: :boolean,
          description: "Whether the player has acted in this betting round"
        },
        current_bet: %Schema{type: :integer, description: "Your current bet"}
      }
    })
  end

  defmodule Game do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "Game",
      description: "A game",
      type: :object,
      properties: %{
        id: %Schema{type: :integer, description: "Game ID"},
        player: %Schema{
          allOf: [
            Player,
            %Schema{
              type: :object,
              properties: %{
                current_hand: %Schema{type: :array, items: Card, description: "Your Hand"}
              }
            }
          ]
        },
        other_players: %Schema{
          type: :array,
          items: Player,
          description: "List of other players in the game"
        },
        phase: %Schema{type: :string, description: "Phase of the current betting round"},
        pot: %Schema{type: :integer, description: "Current size of the pot"},
        community_cards: %Schema{type: :array, items: Card, description: "Cards on the table"},
        current_player_id: %Schema{type: :string, description: "Current player turn"},
        highest_raise: %Schema{type: :integer, description: "Current bet to match"}
      }
    })
  end

  defmodule GameResponse do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "GameResponse",
      description: "A list of upcoming games",
      type: :object,
      properties: %{
        games: %Schema{
          type: :array,
          items: Game
        },
        all_games_finished: %Schema{type: :boolean, description: "All games in suite are finished"}
      }
    })
  end
end
