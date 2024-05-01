defmodule Unleash.Strategy.Constraint do
  @moduledoc """
  Module that is used to verify
  [constraints](https://www.unleash-hosted.com/docs/strategy-constraints/) are
  met.

  These constraints allow for very complex and specifc strategies to be
  enacted by allowing users to specify context values to include or exclude.
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

  defp check(val1, "DATE_AFTER", %{"value" => val2}), do: compare_date(val1, val2, :gt)
  defp check(val1, "DATE_BEFORE", %{"value" => val2}), do: compare_date(val1, val2, :lt)
  defp check(val1, "NUM_EQ", %{"value" => val2}), do: compare_num(val1, val2, :eq)
  defp check(val1, "NUM_GT", %{"value" => val2}), do: compare_num(val1, val2, :gt)
  defp check(val1, "NUM_GTE", %{"value" => val2}), do: compare_num(val1, val2, :gte)
  defp check(val1, "NUM_LT", %{"value" => val2}), do: compare_num(val1, val2, :lt)
  defp check(val1, "NUM_LTE", %{"value" => val2}), do: compare_num(val1, val2, :lte)
  defp check(val1, "SEMVER_EQ", %{"value" => val2}), do: compare_semver(val1, val2, :eq)
  defp check(val1, "SEMVER_GT", %{"value" => val2}), do: compare_semver(val1, val2, :gt)
  defp check(val1, "SEMVER_LT", %{"value" => val2}), do: compare_semver(val1, val2, :lt)
  defp check(val, "IN", %{"values" => values}), do: val in values
  defp check(val, "NOT_IN", %{"values" => values}), do: val not in values
  defp check(val, "STR_CONTAINS", %{"values" => values}), do: Enum.any?(values, &String.contains?(val, &1))
  defp check(val, "STR_ENDS_WITH", %{"values" => values}), do: Enum.any?(values, &String.ends_with?(val, &1))
  defp check(val, "STR_STARTS_WITH", %{"values" => values}), do: Enum.any?(values, &String.starts_with?(val, &1))
  defp check(_val, _, _), do: false

  defp compare_semver(ver1, ver2, equality) do
    with {:ok, v1} <- Version.parse(ver1),
         {:ok, v2} <- Version.parse(ver2) do
      Version.compare(v1, v2) == equality
    else
      _ -> false
    end
  end

  defp compare_num(v1, v2, equality) do
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

  defp compare_date(v1, v2, equality) do
    with {:ok, utc_date1, _offset} <- DateTime.from_iso8601(v1),
         {:ok, utc_date2, _offset} <- DateTime.from_iso8601(v2) do
      DateTime.compare(utc_date1, utc_date2) == equality
    else
      _ -> false
    end
  end

  defp find_value(nil, _name), do: nil

  defp find_value(ctx, name) do
    Map.get(
      ctx,
      String.to_atom(Recase.to_snake(name)),
      find_value(Map.get(ctx, :properties), name)
    )
  end
end
