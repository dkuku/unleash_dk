defmodule Unleash.Variant do
  @moduledoc false
  alias Unleash.Feature
  alias Unleash.Strategy.Utils

  @derive Jason.Encoder
  defstruct name: "",
            weight: 0,
            payload: %{},
            overrides: []

  @type t :: %{enabled: boolean(), name: String.t(), payload: map()}
  @type result :: %{
          required(:enabled) => boolean(),
          required(:name) => String.t(),
          optional(:payload) => map()
        }

  def select_variant(%Feature{variants: variants} = feature, context)
      when is_list(variants) and variants != [] do
    {variant, metadata} =
      case Feature.enabled?(feature, context) do
        {true, _} -> variants(feature, context)
        _ -> {disabled(), %{reason: :feature_disabled}}
      end

    common_metadata = %{
      seed: get_seed(context),
      variants: Enum.map(variants, &{&1.name, &1.weight})
    }

    {variant, Map.merge(metadata, common_metadata)}
  end

  def select_variant(_feature, _context), do: {disabled(), %{reason: :feature_has_no_variants}}

  def from_map(map) when is_map(map) do
    %__MODULE__{
      name: map["name"],
      weight: map["weight"],
      payload: map["payload"],
      overrides: Map.get(map, "overrides", [])
    }
  end

  def to_map(%__MODULE__{name: "disabled" = name}) do
    %{
      enabled: false,
      name: name
    }
  end

  def to_map(%__MODULE__{name: name, payload: payload}, enabled \\ false) do
    %{
      enabled: enabled,
      name: name,
      payload: payload
    }
  end

  defp find_variant(variants, target) do
    Enum.reduce_while(variants, 0, fn v, acc ->
      case acc + v.weight do
        x when x < target -> {:cont, x}
        _ -> {:halt, v}
      end
    end)
  end

  defp find_override(variants, context) do
    variants
    |> Enum.filter(fn v -> check_variant_for_override(v, context) end)
    |> Enum.at(0)
  end

  defp check_variant_for_override(%__MODULE__{overrides: []}, _context), do: false

  defp check_variant_for_override(%__MODULE__{overrides: overrides}, context) do
    Enum.any?(overrides, fn %{"contextName" => name, "values" => values} ->
      Enum.any?(values, fn v -> v === get_in(context, get_context_name(name)) end)
    end)
  end

  defp get_seed(context) do
    with nil <- Map.get(context, :session_id),
         nil <- Map.get(context, :user_id),
         nil <- Map.get(context, :remoteAddress),
         properties when not is_nil(properties) <- Map.get(context, :properties),
         nil <- Map.get(properties, :custom_field) do
      to_string(:rand.uniform(100_000))
    else
      nil -> to_string(:rand.uniform(100_000))
      not_nil_value -> not_nil_value
    end
  end

  defp get_context_name("userId"), do: [:user_id]
  defp get_context_name("sessionId"), do: [:session_id]
  defp get_context_name("remoteAddress"), do: [:remote_address]
  defp get_context_name("customField"), do: [:properties, :custom_field]

  def disabled do
    %{
      enabled: false,
      name: "disabled"
    }
  end

  defp variants(%Feature{variants: variants, name: name}, context)
       when is_list(variants) and variants != [] do
    total_weight =
      for %{weight: weight} <- variants, reduce: 0 do
        acc -> weight + acc
      end

    variants
    |> find_override(context)
    |> case do
      nil ->
        variant =
          find_variant(
            variants,
            Utils.normalize_variant(get_seed(context), name, total_weight)
          )

        {to_map(variant, true), %{reason: :variant_selected}}

      variant ->
        {to_map(variant, true), %{reason: :override_found}}
    end
  end
end
