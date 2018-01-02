defmodule Tai.Symbol do
  def downcase(symbol) when is_atom(symbol) do
    symbol
    |> Atom.to_string
    |> String.downcase
  end
  def downcase(symbol) do
    symbol
    |> String.downcase
  end

  def downcase_all(symbols) do
    symbols
    |> Enum.map(&downcase&1)
  end
end
