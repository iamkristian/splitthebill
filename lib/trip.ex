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
      %{ expenses: state[:expenses] ++ [expense] , members: state[:members] }
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
end
