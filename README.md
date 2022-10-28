# Splitthebill

Handles the problem of a group of friends going on a trip, splitting the
expenses equally.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `splitthebill` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:splitthebill, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/splitthebill>.

## Try it

```
$ iex -S mix

Trip.start_link(["fred", "joe", "sussie", "groot"])

Trip.add_expense(%{member: "fred", name: "Paintball", amount: 250 })
Trip.add_expense(%{member: "joe", name: "Hotel", amount: 500 })
Trip.add_expense(%{member: "sussie", name: "Restaurant", amount: 100 })

Trip.balance("fred")
Trip.balance("groot")

Trip.list_expenses

Trip.add_payment(%{sender: "groot", receiver: "joe", amount: 100 })
Trip.add_payment(%{sender: "fred", receiver: "joe", amount: 150 })
Trip.add_payment(%{sender: "sussie", receiver: "joe", amount: 50 })

Trip.list_payments_settle_all_debts
```

