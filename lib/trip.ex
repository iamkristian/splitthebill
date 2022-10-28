defmodule Trip do
  use GenServer

  @moduledoc """
  Documentation for the GenServer `Trip`.
  """

  defstruct members: [], expenses: [], payments: []

  @doc """
  GenServer.init/1 callback
  """
  def init(state), do: { :ok, state }

  @doc """
  GenServer.handle_call/3 callback
  """
  def handle_call(:members, _from, state), do: {:reply, state[:members], state}
  def handle_call(:list_expenses, _from, state), do: {:reply, state[:expenses], state}
  def handle_call({ :balance, member }, _from, state) do
    balance = sum_balance(member, state[:expenses])
    {:reply, balance, state}
  end
  def handle_call(:list_payments_settle_all_debts, _from, state) do
    result = sum_payments_settle_all_debts(state[:members], state[:expenses], state[:payments])
    {:reply, result , state}
  end

  defp sum_payments_settle_all_debts(members, [], []), do: 0
  defp sum_payments_settle_all_debts(members, expenses, payments) do
    balance = members
      |> Enum.map(fn(m)-> %{ member: m, balance: sum_balance(m, expenses) } end)

    sum = Enum.reduce(balance, 0, fn(b, acc) -> b[:balance] + acc end)
    no_members = Enum.count(members)
    trip_cost = sum/no_members

    owing = balance
    |> Enum.map(fn(b)-> Map.put(b, :payments, sum_payments(b[:member], payments)) end)
    |> Enum.map(fn(b)-> Map.put(b, :group_owes, (b[:balance]+(b[:payments][:payed]-b[:payments][:received]))-trip_cost) end)

    settlement = owing
    |> Enum.map(fn(b)-> settle_the_trip(b, members, no_members, owing) end)
    |> Enum.reduce([], fn(l, acc)-> l++acc end)
    |> Enum.uniq

    settlement
  end

  defp settle_the_trip(balance, members, no_members, owing) do
    members
    |> Enum.filter(fn(m)-> m != balance[:member] end)
    |> Enum.map(fn(m)-> settle_balance_for(balance, m, owing, no_members) end)
  end

  defp settle_balance_for(balance, member, owing, no_members) do
    member_balance = hd Enum.filter(owing, fn(o)-> member == o[:member] end)

    settle_balance = (balance[:group_owes]/no_members) - (member_balance[:group_owes]/no_members)

    if settle_balance < 0 do # The member owes the group
      %{ sender: balance[:member], receiver: member, amount: -settle_balance }
    else # The group owes the member
      %{ sender: member, receiver: balance[:member], amount: settle_balance }
    end
  end

  defp sum_payments(member, payments) do
    payments
      |> Enum.filter(fn(p)-> p[:sender] == member || p[:receiver] == member end)
      |> Enum.reduce(%{payed: 0, received: 0}, fn(p, acc)-> assign_payment(member, p, acc) end)
  end

  defp assign_payment(member, payment, acc) do
    if payment[:sender] == member do
      Map.put(acc, :payed, acc[:payed] + payment[:amount])
    else
      Map.put(acc, :received, acc[:received] + payment[:amount])
    end
  end

  defp sum_balance(member, []), do: 0
  defp sum_balance(member, expenses) do
    expenses
    |> Enum.filter(fn(exp) -> exp[:member] == member end)
    |> Enum.reduce(0, fn(e, acc) -> e[:amount] + acc end)
  end

  @doc """
  GenServer.handle_cast/2 callback
  """
  def handle_cast({:add_expense, expense}, state) do
    newst = update_expenses(expense, state)
    {:noreply, newst}
  end

  defp update_expenses(expense, state) do
    if is_member?(expense[:member], state) do
      Map.put(state, :expenses, state[:expenses] ++ [expense])
    else
      state
    end
  end

  def handle_cast({:add_payment, payment}, state) do
    newst = update_payments(payment, state)
    {:noreply, newst}
  end

  defp update_payments(payment, state) do
    if is_member?(payment[:sender], state) && is_member?(payment[:receiver], state) && payment[:sender] != payment[:receiver] do
      Map.put(state, :payments, state[:payments] ++ [payment])
    else
      state
    end
  end

  defp is_member?(member, state) do
    Enum.member?(state[:members], member)
  end

  ### Client API

  @doc """
  Start out the trip and link it with members.

  Example:
  Trip.start_link(["Joe", "Fred", "Sussie"])
  """
  def start_link(members \\ []) do
    GenServer.start_link(__MODULE__, %{members: members, expenses: [], payments: []}, name: __MODULE__)
  end

  @doc """
  add_expense/1
  Adds a trip expense for a member.

  Example:
  iex> Trip.start_link(["Joe", "Fred", "Sussie"])
  iex> Trip.add_expense(%{ member: :joe, name: "Restaurant", amount: 45 })
  """
  def add_expense(expense), do: GenServer.cast(__MODULE__, { :add_expense, expense })

  @doc """
  members
  lists the members of the trip
  Example
  iex> Trip.start_link(["Joe", "Fred", "Sussie"])
  iex> Trip.members
  """
  def members, do: GenServer.call(__MODULE__, :members)

  @doc """
  list_expenses
  lists the expenses of the trip
  Example:
  iex> Trip.start_link(["Joe", "Fred", "Sussie"])
  iex> Trip.list_expenses
  """
  def list_expenses, do: GenServer.call(__MODULE__, :list_expenses)

  @doc """
  balance
  Shows the balance for a named member of the trip
  Example:
  iex> Trip.start_link(["Joe", "Fred", "Sussie"])
  iex> Trip.balance("Joe")
  """
  def balance(member), do: GenServer.call(__MODULE__, { :balance, member })

  @doc """
  add_payment/1
  Adds a payment from a sender to a receiver with a given amount.

  Example:
  iex> Trip.start_link(["Joe", "Fred", "Sussie"])
  iex> Trip.add_payment(%{ sender: "groot", receiver: "joe", amount: 45 })
  """
  def add_payment(payment), do: GenServer.cast(__MODULE__, { :add_payment, payment })

  @doc """
  list_payments_settle_all_debts/0

  Example:
  iex> Trip.start_link(["Joe", "Fred", "Sussie"])
  iex> Trip.list_payments_settle_all_debts
  """
  def list_payments_settle_all_debts, do: GenServer.call(__MODULE__, :list_payments_settle_all_debts)
end
