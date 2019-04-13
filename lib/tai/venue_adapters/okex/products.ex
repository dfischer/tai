defmodule Tai.VenueAdapters.OkEx.Products do
  alias Tai.Utils

  def products(venue_id) do
    with {:ok, instruments} <- ExOkex.Futures.Public.instruments() do
      products = instruments |> Enum.map(&build(&1, venue_id))
      {:ok, products}
    end
  end

  defp build(
         %{
           "instrument_id" => instrument_id,
           "tick_size" => tick_size,
           "trade_increment" => trade_increment
         },
         venue_id
       ) do
    symbol = instrument_id |> String.downcase() |> String.to_atom()
    size_increment = trade_increment |> Utils.Decimal.from()
    price_increment = tick_size |> Utils.Decimal.from()

    %Tai.Venues.Product{
      venue_id: venue_id,
      symbol: symbol,
      venue_symbol: instrument_id,
      status: :trading,
      type: :future,
      price_increment: price_increment,
      size_increment: size_increment,
      min_size: size_increment
    }
  end
end