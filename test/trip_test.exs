defmodule TripTest do
  use ExUnit.Case, async: true
  doctest Trip

  describe "start_link/1" do
    setup [:data]

    test "start link", context do
      {:ok, pid} = start_supervised(Trip)

      Process.exit(pid, :normal)

      assert Trip.members == []
    end

    test "start link with members", context do
      {:ok, pid} = start_supervised({Trip, context[:members]})

      assert Trip.members == ["fred", "joe", "sussie"]
    end
  end

  describe "add_expense/1" do
    setup [:data, :startup]

    test "add_expense - known member", context do
      assert Trip.add_expense(context[:j_exp]) == :ok
    end

    test "add_expense - unknown member", context do
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
      assert Trip.list_expenses == [context[:f_exp]]
    end
  end

  defp data(context) do
    [
      f_exp: %{member: "fred", name: "Paintball", amount: 250 },
      j_exp: %{member: "joe", name: "Hotel", amount: 500 },
      s_exp: %{member: "sussie", name: "Restaurant", amount: 100 },
      members: ["fred", "joe", "sussie"]
    ]
  end

  defp startup(context) do
    {:ok, pid} = start_supervised({Trip, context[:members] })
    :ok
  end

  defp add_expenses(context) do
    context[:f_exp] |> Trip.add_expense
    context[:j_exp] |> Trip.add_expense
    context[:s_exp] |> Trip.add_expense
  end
end
