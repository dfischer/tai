defmodule Tai.Advisors.GroupsTest do
  use ExUnit.Case, async: true

  defmodule TestProvider do
    @btc_usdt struct(Tai.Venues.Product, symbol: :btc_usdt, venue_id: :venue_a)
    @ltc_usdt struct(Tai.Venues.Product, symbol: :ltc_usdt, venue_id: :venue_b)
    @eth_usdt struct(Tai.Venues.Product, symbol: :eth_usdt, venue_id: :venue_c)

    def products, do: [@btc_usdt, @ltc_usdt, @eth_usdt]
  end

  defmodule MyConfig do
    defstruct ~w(my_symbol)a
  end

  test "returns a list of parsed advisor groups" do
    groups_config = %{
      group_a: [
        start_on_boot: true,
        restart: :permanent,
        shutdown: 1000,
        advisor: AdvisorA,
        factory: TestFactoryA,
        products: "*",
        config: %{min_profit: 0.1},
        trades: [:a, :b]
      ]
    }

    assert {:ok, [group | _]} = Tai.Advisors.Groups.from_config(groups_config, TestProvider)
    assert %Tai.AdvisorGroup{} = group
    assert group.id == :group_a
    assert group.advisor == AdvisorA
    assert group.factory == TestFactoryA
    assert group.start_on_boot == true
    assert group.restart == :permanent
    assert group.shutdown == 1000
    assert group.products != nil
    assert group.config == %{min_profit: 0.1}
    assert group.trades == [:a, :b]
  end

  test "filters products with a query" do
    groups_config = %{
      group_a: [
        advisor: AdvisorA,
        factory: TestFactoryA,
        products: "venue_a.btc_usdt"
      ]
    }

    assert {:ok, [group | _]} = Tai.Advisors.Groups.from_config(groups_config, TestProvider)
    assert [product | []] = group.products
    assert product.venue_id == :venue_a
    assert product.symbol == :btc_usdt
  end

  test "start_on_boot is false when not present" do
    groups_config = %{
      group_a: [
        advisor: AdvisorA,
        factory: TestFactoryA,
        products: "*"
      ]
    }

    assert {:ok, [group | _]} = Tai.Advisors.Groups.from_config(groups_config, TestProvider)
    assert group.start_on_boot == false
  end

  test "restart is temporary when not present" do
    groups_config = %{
      group_a: [
        advisor: AdvisorA,
        factory: TestFactoryA,
        products: "*"
      ]
    }

    assert {:ok, [group | _]} = Tai.Advisors.Groups.from_config(groups_config, TestProvider)
    assert group.restart == :temporary
  end

  test "shutdown is 5000 when not present" do
    groups_config = %{
      group_a: [
        advisor: AdvisorA,
        factory: TestFactoryA,
        products: "*"
      ]
    }

    assert {:ok, [group | _]} = Tai.Advisors.Groups.from_config(groups_config, TestProvider)
    assert group.shutdown == 5000
  end

  test "config can substitute rich types" do
    groups_config = %{
      group_a: [
        advisor: AdvisorA,
        factory: TestFactoryA,
        products: "*",
        config: %{
          product_a: {{:venue_a, :btc_usdt}, :product}
        }
      ]
    }

    assert {:ok, [group | _]} = Tai.Advisors.Groups.from_config(groups_config, TestProvider)
    assert %Tai.Venues.Product{} = product_a = group.config.product_a
    assert product_a.venue_id == :venue_a
    assert product_a.symbol == :btc_usdt
  end

  test "config can be parsed into a struct" do
    groups_config = %{
      group_a: [
        advisor: AdvisorA,
        factory: TestFactoryA,
        products: "*",
        config: {MyConfig, %{my_symbol: :btc_usd}}
      ]
    }

    assert {:ok, [group | _]} = Tai.Advisors.Groups.from_config(groups_config, TestProvider)
    assert %MyConfig{} = group.config
    assert group.config.my_symbol == :btc_usd
  end

  test "config is an empty map when not present" do
    groups_config = %{
      group_a: [
        advisor: AdvisorA,
        factory: TestFactoryA,
        products: "*"
      ]
    }

    assert {:ok, [group | _]} = Tai.Advisors.Groups.from_config(groups_config, TestProvider)
    assert group.config == %{}
  end

  test "trades is an empty list when not present" do
    groups_config = %{
      group_a: [
        advisor: AdvisorA,
        factory: TestFactoryA,
        products: "*"
      ]
    }

    assert {:ok, [group | _]} = Tai.Advisors.Groups.from_config(groups_config, TestProvider)
    assert group.trades == []
  end

  test "returns an error tuple when advisor is not present" do
    groups_config = %{
      group_a: [
        factory: TestFactoryA,
        products: "*"
      ]
    }

    assert {:error, errors} = Tai.Advisors.Groups.from_config(groups_config, TestProvider)
    assert errors.group_a == [{:advisor, "must be present"}]
  end

  test "returns an error tuple when factory is not present" do
    groups_config = %{
      group_a: [
        advisor: TestAdvisorA,
        products: "*"
      ]
    }

    assert {:error, errors} = Tai.Advisors.Groups.from_config(groups_config, TestProvider)
    assert errors.group_a == [{:factory, "must be present"}]
  end
end
