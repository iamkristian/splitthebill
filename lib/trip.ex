defmodule Trip do
  use GenServer

  @moduledoc """
  Documentation for the GenServer `Trip`.
  """

  defstruct members: [], expenses: []

  @doc """
  GenServer.init/1 callback
  """
  def init(state), do: { :ok, state }

  @doc """
  GenServer.handle_call/3 callback
  """
  def handle_call(:members, _from, state ), do: {:reply, state[:members], state}
  def handle_call(:list_expenses, _from, state ), do: {:reply, state[:expenses], state}


  @doc """
  GenServer.handle_cast/2 callback
  """
  def handle_cast({:add_expense, expense}, state) do
    newst = updateExpenses(expense, state)
    {:noreply, newst}
  end

  defp updateExpenses(expense, state) do
    if Enum.member?(state[:members], expense[:member]) do
      %{ expenses: state[:expenses] ++ [expense] , members: state[:members] }
    else
      state
    end
  end

  ### Client API

  @doc """
  Start out the trip and link it with members.

  Example:
  Trip.start_link(["Joe", "Fred", "Sussie"])
  """
  def start_link(members \\ []) do
    GenServer.start_link(__MODULE__, %{members: members, expenses: []}, name: __MODULE__)
  end

  defp validate_members(members \\ []) do
    [head | tail] = members
    validate_member(head, tail)
  end

  defp validate_member(head, tail) do
    [h | t] = tail
    String.valid? head
    validate_member(h, t)
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
end
