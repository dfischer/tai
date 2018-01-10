defmodule Tai.Markets.OrderBook do
  use GenServer

  def start_link(feed_id: feed_id, symbol: symbol) do
    GenServer.start_link(
      __MODULE__,
      %{bids: %{}, asks: %{}},
      name: to_name(feed_id: feed_id, symbol: symbol)
    )
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call(:quotes, _from, state) do
    {:reply, {:ok, %{bids: state.bids |> ordered_bids, asks: state.asks |> ordered_asks}}, state}
  end

  def handle_call({:replace, bids, asks}, _from, _state) do
    {:reply, :ok, %{bids: bids |> Map.new, asks: asks |> Map.new}}
  end
  def handle_call({:update, changes}, _from, state) do
    {:reply, :ok, state |> update_changes(changes)}
  end

  def quotes(name) do
    GenServer.call(name, :quotes)
  end

  def replace(name, bids: bids, asks: asks) do
    GenServer.call(name, {:replace, bids, asks})
  end

  def update(name, changes) do
    GenServer.call(name, {:update, changes})
  end

  def to_name(feed_id: feed_id, symbol: symbol) do
    :"#{__MODULE__}_#{feed_id}_#{symbol}"
  end

  defp ordered_bids(bids) do
    bids
    |> Map.keys
    |> Enum.sort
    |> Enum.reverse
    |> to_keyword_list(bids)
  end

  defp ordered_asks(asks) do
    asks
    |> Map.keys
    |> Enum.sort
    |> to_keyword_list(asks)
  end

  defp to_keyword_list(keys, side) do
    keys
    |> Enum.map(&([price: &1, size: side[&1]]))
  end

  defp update_changes(state, []), do: state
  defp update_changes(state, [[side: side, price: price, size: size] | remaining_changes]) do
    state
    |> update_change(side |> to_book_side, price, size)
    |> update_changes(remaining_changes)
  end

  defp update_change(state, side, price, size) do
    state
    |> Map.put(side, state[side] |> update_or_delete_price(price, size))
  end

  defp to_book_side(:bid), do: :bids
  defp to_book_side(:ask), do: :asks

  defp update_or_delete_price(side, price, size) do
    case size == 0 do
      true -> Map.delete(side, price)
      false -> Map.put(side, price, size)
    end
  end
end
