defmodule Tai.TestSupport.Mock do
  @type location :: Tai.Markets.Location.t()
  @type product :: Tai.Venues.Product.t()
  @type fee_info :: Tai.Venues.FeeInfo.t()
  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type account_id :: Tai.Venues.Adapter.account_id()
  @type asset :: Tai.Venues.AssetBalance.asset()

  @spec mock_product(product | map) :: :ok
  def mock_product(%Tai.Venues.Product{} = product) do
    product
    |> Tai.Venues.ProductStore.upsert()
  end

  def mock_product(attrs) when is_map(attrs) do
    Tai.Venues.Product
    |> struct(attrs)
    |> Tai.Venues.ProductStore.upsert()
  end

  @spec mock_fee_info(fee_info | map) :: :ok
  def mock_fee_info(%Tai.Venues.FeeInfo{} = fee_info) do
    fee_info
    |> Tai.Venues.FeeStore.upsert()
  end

  def mock_fee_info(attrs) when is_map(attrs) do
    Tai.Venues.FeeInfo
    |> struct(attrs)
    |> Tai.Venues.FeeStore.upsert()
  end

  @spec mock_asset_balance(
          venue_id,
          account_id,
          asset,
          free :: number | Decimal.t() | String.t(),
          locked :: number | Decimal.t() | String.t()
        ) :: :ok
  def mock_asset_balance(venue_id, account_id, asset, free, locked) do
    %Tai.Venues.AssetBalance{
      venue_id: venue_id,
      account_id: account_id,
      type: "default",
      asset: asset,
      free: free |> Decimal.cast(),
      locked: locked |> Decimal.cast()
    }
    |> Tai.Venues.AssetBalanceStore.upsert()
  end

  @spec push_market_data_snapshot(location :: location, bids :: map, asks :: map) :: no_return
  def push_market_data_snapshot(location, bids, asks) do
    :ok =
      location.venue_id
      |> whereis_stream_connection
      |> send_json_msg(%{
        type: :snapshot,
        symbol: location.product_symbol,
        bids: bids,
        asks: asks
      })
  end

  @spec push_order_update(venue_id, map) :: no_return
  def push_order_update(venue_id, attrs) do
    :ok =
      venue_id
      |> whereis_stream_connection()
      |> send_json_msg(attrs)
  end

  defp whereis_stream_connection(venue_id) do
    venue_id
    |> Tai.VenueAdapters.Mock.Stream.Connection.to_name()
    |> Process.whereis()
  end

  defp send_json_msg(pid, msg) do
    Tai.WebSocket.send_json_msg(pid, msg)
  end
end
