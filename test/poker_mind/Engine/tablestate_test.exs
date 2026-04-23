defmodule PokerMind.Engine.TableStateTest do
  use ExUnit.Case, async: true
  alias PokerMind.Engine.TableState

  setup do
    players =
      [
        "stine",
        "rolf",
        "asbjørn",
        "simon"
      ]

    %{state: TableState.init(TableState.new("123"), players)}
  end

  test "init/2 - players and deck are initialized for a new table", %{state: state} do
    # All 4 players are initialized
    assert Enum.count(state.players) == 4

    # The deck is initialized in which each player has been dealt two cards
    assert Enum.count(state.deck) == 52 - 2 * Enum.count(state.players)
  end

  test "deal_cards/1 - each player gets two seprate cards from the deck", %{state: state} do
    # Check that two players have different cards
    [player1, player2 | _rest] = state.players
    assert Enum.sort(player1.current_hand) != Enum.sort(player2.current_hand)

    # Check that dealt cards have been removed from the deck
    dealt_cards = Enum.flat_map(state.players, fn player -> player.current_hand end)

    for card <- dealt_cards do
      assert !Enum.member?(state.deck, card)
    end
  end

  test "set_blinds/1 - more than 2 players, a player is chosen as small blind and another as current player",
       %{
         state: state
       } do
    assert Enum.any?(state.players, fn player -> player.id == state.small_blind_id end)
    assert Enum.any?(state.players, fn player -> player.id == state.current_player_id end)
    assert state.small_blind_id != state.current_player_id
  end

  test "set_blinds/1 - exactly 2 players, a player is chosen as both small blind and current player" do
    players =
      [
        "stine",
        "rolf"
      ]

    state = TableState.init(TableState.new("123"), players)

    assert Enum.any?(state.players, fn player -> player.id == state.small_blind_id end)
    assert Enum.any?(state.players, fn player -> player.id == state.current_player_id end)
    assert state.small_blind_id == state.current_player_id
  end

  test "advance_player/2 - current player becomes next player in the list", %{
    state: state
  } do
    player_idx_0 = Enum.at(state.players, 0)

    new_state =
      state
      |> Map.put(:current_player_id, player_idx_0.id)
      |> TableState.advance_player()

    assert Enum.find_index(new_state.players, fn p -> p.id == new_state.current_player_id end) ==
             1
  end

  test "advance_player/2 - current player becomes first player in the list if the player before was last in the list",
       %{
         state: state
       } do
    player_idx_last = Enum.at(state.players, length(state.players) - 1)

    new_state =
      state
      |> Map.put(:current_player_id, player_idx_last.id)
      |> TableState.advance_player()

    assert Enum.find_index(new_state.players, fn p -> p.id == new_state.current_player_id end) ==
             0
  end

  test "advance_phase/2 - valid transition from pre_flop to flop", %{
    state: state
  } do
    assert %{phase: :flop} = TableState.advance_phase(state, :flop)
  end

  test "advance_phase/2 - invalid transition from pre_flop to river", %{
    state: state
  } do
    assert {:error, new_state} = TableState.advance_phase(state, :river)
    assert new_state == {:invalid_transition, :pre_flop, :river}
  end

  test "complete_current_player_turn/1 - current players `has_acted` is set to `true`", %{
    state: state
  } do
    current_player_id = state.current_player_id
    current_player = Enum.find(state.players, &(&1.id == current_player_id))
    refute current_player.has_acted

    updated_state = TableState.complete_current_player_turn(state)
    current_player_updated = Enum.find(updated_state.players, &(&1.id == current_player_id))
    assert current_player_updated.has_acted
  end

  test "add_to_pot/3 - amount is deducted from remaining_chips and is added to current_bet and pot",
       %{
         state: state
       } do
    player1 = %{TableState.get_player(state, "stine") | remaining_chips: 100, current_bet: 0}
    player2 = %{TableState.get_player(state, "rolf") | remaining_chips: 100, current_bet: 0}

    # update state with new players (with 100 chips and 0 current bet) to test add_to_pot
    state_new_players =
      state
      |> Map.put(:players, [player1, player2 | Enum.drop(state.players, 4)])

    updated_state =
      state_new_players
      # add_to_pot with 20 chips for each player
      |> TableState.add_to_pot(player2.id, 20)
      |> TableState.add_to_pot(player1.id, 20)
      # add_to_pot with for rolf (so 30 more)
      |> TableState.add_to_pot(player2.id, 50)

    updated_player1 = TableState.get_player(updated_state, player1.id)
    updated_player2 = TableState.get_player(updated_state, player2.id)

    # each player starts with 100 chips
    assert updated_player1.remaining_chips == 80
    assert updated_player1.current_bet == 20

    assert updated_player2.remaining_chips == 50
    assert updated_player2.current_bet == 50

    assert updated_state.pot == 70
  end

  test "compare_cards/2 - returns :lt, :gt, or :eq based on card rank" do
    assert TableState.compare_cards(2, 1) == :lt
    assert TableState.compare_cards(1, 2) == :gt
    assert TableState.compare_cards(1, 1) == :eq
  end

  test "compare_hands/3 - hand1 is better than hand2" do
    player1_hand = [%{rank: 4, suit: :clubs}, %{rank: 5, suit: :diamonds}]
    player2_hand = [%{rank: 11, suit: :hearts}, %{rank: 11, suit: :spades}]

    community_cards = [
      %{rank: 3, suit: :clubs},
      %{rank: 6, suit: :clubs},
      %{rank: 7, suit: :diamonds},
      %{rank: 1, suit: :diamonds},
      %{rank: 1, suit: :clubs}
    ]

    assert TableState.compare_hands(player1_hand, player2_hand, community_cards) == :gt
  end

  test "compare_hands/3 - hand1 and hand2 is equally good" do
    player1_hand = [%{rank: 8, suit: :hearts}, %{rank: 9, suit: :hearts}]
    player2_hand = [%{rank: 3, suit: :diamonds}, %{rank: 4, suit: :diamonds}]

    community_cards = [
      %{rank: 2, suit: :clubs},
      %{rank: 10, suit: :clubs},
      %{rank: 11, suit: :clubs},
      %{rank: 12, suit: :clubs},
      %{rank: 13, suit: :clubs}
    ]

    assert TableState.compare_hands(player1_hand, player2_hand, community_cards) == :eq
  end

  test "compare_hands/3 - hand1 is worse than hand2" do
    player1_hand = [%{rank: 11, suit: :hearts}, %{rank: 11, suit: :spades}]
    player2_hand = [%{rank: 4, suit: :clubs}, %{rank: 5, suit: :diamonds}]

    community_cards = [
      %{rank: 3, suit: :clubs},
      %{rank: 6, suit: :clubs},
      %{rank: 7, suit: :diamonds},
      %{rank: 1, suit: :diamonds},
      %{rank: 1, suit: :clubs}
    ]

    assert TableState.compare_hands(player1_hand, player2_hand, community_cards) == :lt
  end

  test "split_pot/2 - one winner, no leftover chips",
       %{
         state: state
       } do
    new_state =
      state
      |> TableState.set_player_value("simon", :remaining_chips, 0)
      |> TableState.set_player_value("asbjørn", :remaining_chips, 0)
      |> TableState.set_player_value("rolf", :remaining_chips, 0)
      |> Map.put(:pot, 100)

    winners = ["simon"]

    final_state = TableState.split_pot(new_state, winners)

    assert final_state.pot == 0
    assert TableState.get_player(final_state, "simon").remaining_chips == 100
    assert TableState.get_player(final_state, "asbjørn").remaining_chips == 0
    assert TableState.get_player(final_state, "rolf").remaining_chips == 0
  end

  test "split_pot/2 - two winners, one leftover chip for the first winning player",
       %{
         state: state
       } do
    new_state =
      state
      |> TableState.set_player_value("simon", :remaining_chips, 0)
      |> TableState.set_player_value("asbjørn", :remaining_chips, 0)
      |> TableState.set_player_value("rolf", :remaining_chips, 0)
      |> Map.put(:pot, 101)

    winners = ["asbjørn", "rolf"]

    final_state = TableState.split_pot(new_state, winners)

    assert final_state.pot == 0
    assert TableState.get_player(final_state, "simon").remaining_chips == 0
    assert TableState.get_player(final_state, "asbjørn").remaining_chips == 51
    assert TableState.get_player(final_state, "rolf").remaining_chips == 50
  end

  test "split_pot/2 - three winners, two leftover chip, one for the first winning player and one for the second winning player",
       %{
         state: state
       } do
    new_state =
      state
      |> TableState.set_player_value("simon", :remaining_chips, 0)
      |> TableState.set_player_value("asbjørn", :remaining_chips, 0)
      |> TableState.set_player_value("rolf", :remaining_chips, 0)
      |> Map.put(:pot, 101)

    winners = ["simon", "asbjørn", "rolf"]

    final_state = TableState.split_pot(new_state, winners)

    assert final_state.pot == 0
    assert TableState.get_player(final_state, "simon").remaining_chips == 34
    assert TableState.get_player(final_state, "asbjørn").remaining_chips == 34
    assert TableState.get_player(final_state, "rolf").remaining_chips == 33
  end

  test "advance_phase/2 - deal community_cards, three for flop, one for turn and one for river",
       %{
         state: state
       } do
    flop_phase = TableState.next_phase(state)
    flop_state = TableState.advance_phase(state, flop_phase)

    turn_phase = TableState.next_phase(flop_state)
    turn_state = TableState.advance_phase(flop_state, turn_phase)

    river_phase = TableState.next_phase(turn_state)
    river_state = TableState.advance_phase(turn_state, river_phase)

    assert length(flop_state.community_cards) == 3
    assert length(turn_state.community_cards) == 4
    assert length(river_state.community_cards) == 5
  end

  test "advance_phase/2 - handle showdown with one active player remaining",
       %{
         state: state
       } do
    players = [
      "stine",
      "rolf",
      "asbjørn",
      "simon"
    ]

    new_state =
      Enum.reduce(players, state, fn name, acc ->
        acc
        |> TableState.set_player_value(name, :state, :inactive_in_hand)
        |> TableState.set_player_value(name, :remaining_chips, 0)
      end)
      |> TableState.set_player_value("stine", :state, :active_in_hand)
      |> Map.put(:pot, 100)

    next_phase = TableState.next_phase(new_state)
    final_state = TableState.advance_phase(new_state, next_phase)

    assert next_phase == :showdown
    assert final_state.pot == 0
    assert final_state.community_cards == []
    assert TableState.get_player(final_state, "rolf").remaining_chips == 0
    assert TableState.get_player(final_state, "stine").remaining_chips == 100
  end

  test "advance_phase/2 - handle showdown with four active players remaining, player 3 and player 4 has equally good hands",
       %{
         state: state
       } do
    # (two pair) A♦ A♣ 7♣ 7♦ 6♣ - worst
    player1_hand = [%{rank: 2, suit: :hearts}, %{rank: 7, suit: :clubs}]

    # (two pair) A♦ A♣ K♥ K♦ 7♦ - better than player 1
    player2_hand = [%{rank: 13, suit: :hearts}, %{rank: 13, suit: :diamonds}]

    # (straight) 7♦ 6♣ 5♥ 4♦ 3♣ - better than player 2
    player3_hand = [%{rank: 4, suit: :diamonds}, %{rank: 5, suit: :hearts}]

    # (straight) 7♦ 6♣ 5♦ 4♣ 3♣ - equal to player 3, but different suits
    player4_hand = [%{rank: 4, suit: :clubs}, %{rank: 5, suit: :diamonds}]

    community_cards = [
      %{rank: 3, suit: :clubs},
      %{rank: 6, suit: :clubs},
      %{rank: 7, suit: :diamonds},
      %{rank: 1, suit: :diamonds},
      %{rank: 1, suit: :clubs}
    ]

    players = [
      {"stine", player1_hand},
      {"rolf", player2_hand},
      {"asbjørn", player3_hand},
      {"simon", player4_hand}
    ]

    new_state =
      Enum.reduce(players, state, fn {name, hand}, acc ->
        acc
        |> TableState.set_player_value(name, :state, :all_in)
        |> TableState.set_player_value(name, :remaining_chips, 0)
        |> TableState.set_player_value(name, :current_hand, hand)
      end)
      |> Map.put(:community_cards, community_cards)
      |> Map.put(:pot, 100)

    next_phase = TableState.next_phase(new_state)
    final_state = TableState.advance_phase(new_state, next_phase)

    assert next_phase == :showdown
    assert final_state.pot == 0
    assert TableState.get_player(final_state, "stine").remaining_chips == 0
    assert TableState.get_player(final_state, "rolf").remaining_chips == 0
    assert TableState.get_player(final_state, "asbjørn").remaining_chips == 50
    assert TableState.get_player(final_state, "simon").remaining_chips == 50
  end

  test "advance_phase/2 - handle finished and starts a new hand with new small blind and reset players and table",
       %{
         state: state
       } do
    players = [
      "stine",
      "rolf",
      "asbjørn",
      "simon"
    ]

    new_state =
      Enum.reduce(players, state, fn name, current_state ->
        current_state
        |> TableState.set_player_value(name, :state, :inactive_in_hand)
        |> TableState.set_player_value(name, :remaining_chips, 50)
      end)
      |> TableState.set_player_value("stine", :state, :active_in_hand)
      |> Map.put(:pot, 150)
      |> TableState.advance_phase(:showdown)

    # Showdown leaves stine with 200 chips and rest with 50

    next_phase = TableState.next_phase(new_state)
    final_state = TableState.advance_phase(new_state, next_phase)

    for {player, updated_player} <- Enum.zip(state.players, final_state.players) do
      # Make sure we compare the same player
      assert player.id == updated_player.id
      # Current hand has been updated for each player
      assert length(player.current_hand) == length(updated_player.current_hand)
      assert player.current_hand != updated_player.current_hand
      # Current_bet, has_acted and state is reset
      assert updated_player.current_bet == 0
      assert updated_player.has_acted == false
      assert updated_player.state == :active_in_hand
    end

    # No winner found yet
    assert final_state.winner == nil
    # New small blind is selected and we start the new hand
    assert state.small_blind_id != final_state.small_blind_id
    assert final_state.phase == :pre_flop
  end

  test "advance_phase/2 - an overall winner has been found for the table",
       %{
         state: state
       } do
    players = [
      "stine",
      "rolf",
      "asbjørn",
      "simon"
    ]

    new_state =
      Enum.reduce(players, state, fn name, current_state ->
        current_state
        |> TableState.set_player_value(name, :state, :out_of_chips)
        |> TableState.set_player_value(name, :remaining_chips, 0)
      end)
      |> TableState.set_player_value("stine", :state, :active_in_hand)
      |> Map.put(:pot, 100)
      |> TableState.advance_phase(:showdown)

    # Showdown leaves stine with 100 chips and rest with 0

    next_phase = TableState.next_phase(new_state)
    final_state = TableState.advance_phase(new_state, next_phase)

    # stine is the winner of the table
    assert final_state.winner == "stine"
    assert final_state.phase == :game_finished
  end
end
