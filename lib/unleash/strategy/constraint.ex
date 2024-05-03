defmodule Unleash.Strategy.Constraint do
  @moduledoc """
  Module that is used to verify
  [constraints](https://www.unleash-hosted.com/docs/strategy-constraints/) are
  met.

  These constraints allow for very complex and specifc strategies to be
  enacted by allowing users to specify context values to include or exclude.

  - DATE_AFTER
  - DATE_BEFORE
  - IN
  - NOT_IN
  - NUM_EQ
  - NUM_GT
  - NUM_GTE
  - NUM_LT
  - NUM_LTE
  - SEMVER_EQ
  - SEMVER_GT
  - SEMVER_LT
  - STR_CONTAINS
  - STR_ENDS_WITH
  - STR_STARTS_WITH

  """

  def verify_all(constraints, context) do
    Enum.all?(constraints, &verify(&1, context))
  end

  defp verify(%{"contextName" => name, "operator" => op} = constraints, context) do
    context
    |> find_value(name)
    |> preprocess_value(constraints)
    |> check(op, constraints)
    |> postprocess_value(constraints)
  end

  defp verify(%{}, _context), do: false

  defp postprocess_value(val, %{"inverted" => true}), do: not val
  defp postprocess_value(val, _), do: val
  defp preprocess_value(value, %{"caseInsensitive" => true}), do: String.downcase(value)
  defp preprocess_value(value, _), do: value

  defp check(val, "DATE_AFTER", %{"value" => value}), do: compare_date(val, value, :gt)
  defp check(val, "DATE_BEFORE", %{"value" => value}), do: compare_date(val, value, :lt)
  defp check(val, "IN", %{"values" => values}), do: compare_in(val, values, :in)
  defp check(val, "NOT_IN", %{"values" => values}), do: compare_in(val, values, :not_in)
  defp check(val, "NUM_EQ", %{"value" => value}), do: compare_num(val, value, :eq)
  defp check(val, "NUM_GT", %{"value" => value}), do: compare_num(val, value, :gt)
  defp check(val, "NUM_GTE", %{"value" => value}), do: compare_num(val, value, :gte)
  defp check(val, "NUM_LT", %{"value" => value}), do: compare_num(val, value, :lt)
  defp check(val, "NUM_LTE", %{"value" => value}), do: compare_num(val, value, :lte)
  defp check(val, "SEMVER_EQ", %{"value" => value}), do: compare_semver(val, value, :eq)
  defp check(val, "SEMVER_GT", %{"value" => value}), do: compare_semver(val, value, :gt)
  defp check(val, "SEMVER_LT", %{"value" => value}), do: compare_semver(val, value, :lt)
  defp check(val, "STR_CONTAINS", %{"values" => values}), do: compare_str(val, values, :contains)
  defp check(val, "STR_ENDS_WITH", %{"values" => values}), do: compare_str(val, values, :ends)
  defp check(val, "STR_STARTS_WITH", %{"values" => values}), do: compare_str(val, values, :starts)
  defp check(_val, _, _), do: false

  defp compare_in(val, values, equality) when is_integer(val) do
    compare_in(to_string(val), values, equality)
  end

  defp compare_in(val, values, equality) when is_list(values) do
    case equality do
      :in -> val in values
      :not_in -> val not in values
    end
  end

  defp compare_in(_val, _values, _equality), do: false

  defp compare_str(val, values, equality) when is_binary(val) and is_list(values) do
    Enum.any?(values, fn value ->
      case equality do
        :contains -> String.contains?(val, value)
        :ends -> String.ends_with?(val, value)
        :starts -> String.starts_with?(val, value)
      end
    end)
  end

  defp compare_str(_val, _values, _equality), do: false

  defp compare_semver(v1, v2, equality) when is_binary(v1) and is_binary(v2) do
    with {:ok, v1} <- Version.parse(v1),
         {:ok, v2} <- Version.parse(v2) do
      Version.compare(v1, v2) == equality
    else
      _ -> false
    end
  end

  defp compare_semver(_v1, _v2, _equality), do: false

  defp compare_num(v1, v2, equality) when is_binary(v1) and is_binary(v2) do
    with {v1, ""} <- Float.parse(v1),
         {v2, ""} <- Float.parse(v2) do
      case equality do
        :eq -> v1 == v2
        :lt -> v1 < v2
        :gt -> v1 > v2
        :lte -> v1 <= v2
        :gte -> v1 >= v2
      end
    else
      _ -> false
    end
  end

  defp compare_num(_v1, _v2, _equality), do: false

  defp compare_date(v1, v2, equality) when is_binary(v1) and is_binary(v2) do
    with {:ok, utc_date1, _offset} <- DateTime.from_iso8601(v1),
         {:ok, utc_date2, _offset} <- DateTime.from_iso8601(v2) do
      DateTime.compare(utc_date1, utc_date2) == equality
    else
      _ -> false
    end
  end

  defp compare_date(_v1, _v2, _equality), do: false

  defp find_value(nil, _name), do: nil

  defp find_value(ctx, name) do
    Map.get(
      ctx,
      String.to_atom(Recase.to_snake(name)),
      find_value(Map.get(ctx, :properties), name)
    )
  end
end
