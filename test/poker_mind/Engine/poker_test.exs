defmodule PokerMind.Engine.PokerTest do
  use ExUnit.Case, async: true
  alias PokerMind.Engine.Poker

  describe "hand_compare/2 — kicker and same-category edge cases" do
    test "trip aces beat trip kings" do
      assert Poker.hand_compare("Ah As Ac 2h 3h", "Kh Ks Kc Ah Qh") == :gt
    end

    test "aces-up beats kings-up" do
      assert Poker.hand_compare("Ah As 2c 2d 3h", "Kh Ks Qc Qd Ah") == :gt
    end

    test "same two-pair, better kicker wins" do
      assert Poker.hand_compare("Ah As Kh Ks Qh", "Ah As Kh Ks Jh") == :gt
    end

    test "higher low-pair wins when high pair is the same" do
      assert Poker.hand_compare("Ah As Kh Kd 2c", "Ah As Qh Qd Kc") == :gt
    end

    test "pair of threes with low kickers beats pair of twos with AKQ kickers" do
      assert Poker.hand_compare("3h 3s 6c 5d 4h", "2h 2s Ac Kd Qh") == :gt
    end

    test "same pair, better kicker wins" do
      assert Poker.hand_compare("Ah As Kh Qd Jc", "Ah As Kh Qd Tc") == :gt
    end

    test "ace-high flush beats king-high flush" do
      assert Poker.hand_compare("Ah 5h 4h 3h 2h", "Kh Qh Jh Th 8h") == :gt
    end

    test "ace-high beats king-high" do
      assert Poker.hand_compare("Ah 5c 4d 3h 2s", "Kh Qc Jd Th 8s") == :gt
    end
  end

  describe "hand_compare/2 — straight edge cases" do
    test "Broadway beats the wheel" do
      assert Poker.hand_compare("Ah Kh Qh Jh Th", "Ah 2c 3d 4h 5s") == :gt
    end

    test "wheel still beats any non-straight made of worse cards" do
      assert Poker.hand_compare("Ah 2c 3d 4h 5s", "Ah Kh Qh Jh 9s") == :gt
    end

    test "king-high straight beats queen-high straight" do
      assert Poker.hand_compare("Kh Qc Jd Th 9s", "Qh Jc Td 9h 8s") == :gt
    end
  end

  describe "hand_compare/2 — category boundaries" do
    test "straight flush > quads" do
      assert Poker.hand_compare("Ah Kh Qh Jh Th", "Ah As Ac Ad Kh") == :gt
    end

    test "quads > full house" do
      assert Poker.hand_compare("2h 2s 2c 2d 3h", "Ah As Ac Kh Ks") == :gt
    end

    test "full house > flush" do
      assert Poker.hand_compare("2h 2s 2c 3h 3s", "Ah Kh Qh Jh 9h") == :gt
    end

    test "flush > straight" do
      assert Poker.hand_compare("2h 5h 7h 9h Jh", "Ah Kc Qd Jh Ts") == :gt
    end

    test "straight > trips" do
      assert Poker.hand_compare("2h 3c 4d 5h 6s", "Ah As Ac Kh Qs") == :gt
    end

    test "trips > two pair" do
      assert Poker.hand_compare("2h 2s 2c 3h 4s", "Ah As Kh Ks Qc") == :gt
    end

    test "two pair > pair" do
      assert Poker.hand_compare("2h 2s 3c 3d 4h", "Ah As Kc Qd Jh") == :gt
    end

    test "pair > high card" do
      assert Poker.hand_compare("2h 2s 3c 4d 5h", "Ah Kc Qd Jh 9s") == :gt
    end
  end

  describe "hand_compare/2 — equality" do
    test "identical ranks across different suits tie" do
      assert Poker.hand_compare("Ah Kh Qh Jh 9h", "Ac Kc Qc Jc 9c") == :eq
    end
  end

  describe "hand_rank/1" do
    test "straight flush (ace-high)" do
      assert Poker.hand_rank("Ac Kc Qc Jc Tc") == {:straight_flush, :A}
    end

    test "straight flush (king-high)" do
      assert Poker.hand_rank("Kc Qc Jc Tc 9c") == {:straight_flush, :K}
    end

    test "straight flush (wheel)" do
      assert Poker.hand_rank("5c 4c 3c 2c Ac") == {:straight_flush, 5}
    end

    test "four of a kind" do
      assert Poker.hand_rank("Ac Ad Ah As Kd") == {:four_of_a_kind, :A, :K}
    end

    test "full house aces over kings" do
      assert Poker.hand_rank("Ac Ad Ah Kc Kd") == {:full_house, :A, :K}
    end

    test "full house kings over aces" do
      assert Poker.hand_rank("Kc Kd Kh Ac Ad") == {:full_house, :K, :A}
    end

    test "flush" do
      assert Poker.hand_rank("Ac Qc Jc Tc 9c") == {:flush, :c, :A, :Q, :J, :T, 9}
    end

    test "straight (ace-high)" do
      assert Poker.hand_rank("Ac Kc Qc Jc Td") == {:straight, :A}
    end

    test "straight (king-high)" do
      assert Poker.hand_rank("Kc Qc Jc Tc 9d") == {:straight, :K}
    end

    test "straight (wheel)" do
      assert Poker.hand_rank("5c 4c 3c 2c Ad") == {:straight, 5}
    end

    test "three of a kind" do
      assert Poker.hand_rank("Ac Ad Ah Kc Qc") == {:three_of_a_kind, :A, :K, :Q}
    end

    test "two pair" do
      assert Poker.hand_rank("Ac Ad Kc Kd Qc") == {:two_pair, :A, :K, :Q}
    end

    test "one pair" do
      assert Poker.hand_rank("Ac Ad Kc Qc Jd") == {:one_pair, :A, :K, :Q, :J}
    end

    test "high card" do
      assert Poker.hand_rank("Ac Qc Jd Td 9c") == {:high_card, :A, :Q, :J, :T, 9}
    end
  end

  describe "best_hand/2" do
    test "picks the best five out of seven cards" do
      assert Poker.best_hand("4c 5d", "3c 6c 7d Ad Ac") ==
               {{:straight, 7}, {{7, :d}, {6, :c}, {5, :d}, {4, :c}, {3, :c}}}
    end
  end
end
