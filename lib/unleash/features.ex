defmodule Unleash.Features do
  alias Unleash.Feature

  defstruct version: "1", features: []

  def from_map(map) when is_map(map) do
    %__MODULE__{
      version: map["version"],
      features: Enum.map(map["features"], fn f -> Feature.from_map(f) end)
    }
  end

  def from_map(_), do: %__MODULE__{}

  def enabled?(nil, _feature), do: false

  def enabled?(%__MODULE__{features: nil}, _feature), do: false

  def enabled?(%__MODULE__{}, nil), do: false

  def enabled?(%__MODULE__{features: features} = state, feat)
      when is_list(features) and is_atom(feat) do
    enabled?(state, Atom.to_string(feat))
  end

  def enabled?(%__MODULE__{features: features}, feat)
      when is_list(features) and is_binary(feat) do
    features
    |> IO.inspect()
    |> Enum.find(fn feature -> compare(feature.name, feat) end)
    |> Feature.enabled?()
  end

  defp compare(n1, n2), do: String.downcase(n1) == String.downcase(n2)
end
