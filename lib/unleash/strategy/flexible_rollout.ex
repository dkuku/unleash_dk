defmodule Unleash.Strategy.FlexibleRollout do
  @moduledoc """
  Can depend on `:user_id` or `:session_id` in `t:Unleash.context/0`

  Based on the
  [`flexibleRollout`](https://unleash.github.io/docs/activation_strategy#flexiblerollout)
  strategy.
  """

  use Unleash.Strategy, name: "FlexibleRollout"
  alias Unleash.Strategy.Utils

  def enabled?(%{"rollout" => percentage} = params, context) when is_number(percentage) do
    sticky_value =
      params
      |> Map.get("stickiness", "")
      |> stickiness(context)

    group = Map.get(params, "groupId", Map.get(params, :feature_toggle, ""))

    enabled? =
      if sticky_value do
        percentage > 0 and Utils.normalize(sticky_value, group) <= percentage
      else
        false
      end

    {enabled?,
     %{
       group: group,
       percentage: percentage,
       sticky_value: sticky_value,
       stickiness: Map.get(params, "stickiness")
     }}
  end

  def enabled?(%{"rollout" => percentage} = params, context) when is_binary(percentage) do
    enabled?(%{params | "rollout" => Utils.parse_int(percentage)}, context)
  end

  defp stickiness("userId", ctx), do: ctx[:user_id]
  defp stickiness("sessionId", ctx), do: ctx[:session_id]
  defp stickiness("random", _ctx), do: random()
  defp stickiness("customField", ctx), do: get_in(ctx, [:properties, :custom_field])
  defp stickiness("default", ctx), do: Map.get(ctx, :user_id, Map.get(ctx, :session_id, random()))
  defp stickiness("", ctx), do: stickiness("default", ctx)

  defp random,
    do: Integer.to_string(round(:rand.uniform() * 100) + 1)
end
