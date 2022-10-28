defmodule TripTest do
  use ExUnit.Case, async: true
  doctest Trip

  describe "start_link/1" do
    setup [:data]

    test "start link", _context do
      {:ok, pid} = start_supervised(Trip)

      Process.exit(pid, :normal)

      assert Trip.members == []
    end

    test "start link with members", context do
      {:ok, _pid} = start_supervised({Trip, context[:members]})

      assert Trip.members == ["fred", "joe", "sussie", "groot"]
    end
  end

  describe "add_expense/1" do
    setup [:data, :startup]

    test "add_expense - known member", context do
      assert Trip.add_expense(context[:j_exp]) == :ok
    end

    test "add_expense - unknown member", _context do
      assert Trip.add_expense(%{member: :mac, name: "Paintball", amount: 250 }) == :ok
      assert Trip.list_expenses == []
    end
  end

  describe "list_expenses/0" do
    setup [:data, :startup, :add_expenses]

    test "list_expenses", context do
      assert Trip.list_expenses == [context[:f_exp], context[:j_exp], context[:s_exp]]
    end
  end

  describe "balance/1" do
    setup [:data, :startup, :add_expenses]

    test "shows balance for joe", context do
      context[:j2_exp] |> Trip.add_expense
      context[:j3_exp] |> Trip.add_expense
      assert Trip.balance("joe") == 804
    end

    test "shows balance for fred", _context do
      assert Trip.balance("fred") == 250
    end

    test "shows balance for groot - no expenses", _context do
      assert Trip.balance("groot") == 0
    end
  end

  describe "add_payment/1" do
    setup [:data, :startup, :add_expenses]

    test "add payment from groot to joe", context do
      assert Trip.add_payment(context[:gj_pay]) == :ok
    end

    test "add payment from unknown member", _context do
      assert Trip.add_payment(%{sender: "thanos", receiver: "rocket", amount: 200 }) == :ok
    end
  end

  describe "list_payments_settle_all_debts" do
    setup [:data, :startup, :add_expenses, :add_payments]

    test "list the payments need to settle all debts", _context do
      result = [
        %{amount: 75.0, receiver: "fred", sender: "groot"},
        %{amount: 25.0, receiver: "joe", sender: "groot"},
        %{amount: 12.5, receiver: "sussie", sender: "groot"},
        %{amount: 62.5, receiver: "fred", sender: "sussie"},
        %{amount: 12.5, receiver: "joe", sender: "sussie"},
        %{amount: 50.0, receiver: "fred", sender: "joe"}
      ]
      assert Trip.list_payments_settle_all_debts == result
    end
  end

  defp data(_context) do
    [
      f_exp: %{member: "fred", name: "Paintball", amount: 250 },
      j_exp: %{member: "joe", name: "Hotel", amount: 500 },
      j2_exp: %{member: "joe", name: "Casino", amount: 300 },
      j3_exp: %{member: "joe", name: "Subway", amount: 4 },
      gj_pay: %{sender: "groot", receiver: "joe", amount: 100 },
      fj_pay: %{sender: "fred", receiver: "joe", amount: 150 },
      fs_pay: %{sender: "sussie", receiver: "joe", amount: 50 },
      s_exp: %{member: "sussie", name: "Restaurant", amount: 100 },
      members: ["fred", "joe", "sussie", "groot"]
    ]
  end

  defp startup(context) do
    {:ok, _pid} = start_supervised({Trip, context[:members] })
    :ok
  end

  defp add_expenses(context) do
    context[:f_exp] |> Trip.add_expense
    context[:j_exp] |> Trip.add_expense
    context[:s_exp] |> Trip.add_expense
  end

  defp add_payments(context) do
    context[:gj_pay] |> Trip.add_payment
    context[:fj_pay] |> Trip.add_payment
    context[:fs_pay] |> Trip.add_payment
  end
end
