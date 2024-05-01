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

  defp verify(%{"contextName" => name, "operator" => op, "value" => value} = constraints, context) do
    context
    |> preprocess_value(constraints)
    |> find_value(name)
    |> check_single(op, value)
    |> postprocess_value(constraints)
  end

  defp verify(%{"contextName" => name, "operator" => op, "values" => values} = constraints, context) do
    context
    |> find_value(name)
    |> preprocess_value(constraints)
    |> check_multiple(op, values)
    |> postprocess_value(constraints)
  end

  defp verify(%{}, _context), do: false

  defp postprocess_value(val, %{"inverted" => true}), do: not val
  defp postprocess_value(val, _), do: val
  defp preprocess_value(value, %{"caseInsensitive" => true}), do: String.downcase(value)
  defp preprocess_value(value, _), do: value

  defp check_single(ver1, "SEMVER_EQ", ver2), do: compare_semver(ver1, ver2, :eq)
  defp check_single(ver1, "SEMVER_GT", ver2), do: compare_semver(ver1, ver2, :gt)
  defp check_single(ver1, "SEMVER_LT", ver2), do: compare_semver(ver1, ver2, :lt)
  defp check_single(ver1, "NUM_EQ", ver2), do: compare_num(ver1, ver2, :eq)
  defp check_single(ver1, "NUM_GT", ver2), do: compare_num(ver1, ver2, :gt)
  defp check_single(ver1, "NUM_LT", ver2), do: compare_num(ver1, ver2, :lt)
  defp check_single(ver1, "NUM_LTE", ver2), do: compare_num(ver1, ver2, :lte)
  defp check_single(ver1, "NUM_GTE", ver2), do: compare_num(ver1, ver2, :gte)
  defp check_single(ver1, "DATE_AFTER", ver2), do: compare_date(ver1, ver2, :gt)
  defp check_single(ver1, "DATE_BEFORE", ver2), do: compare_date(ver1, ver2, :lt)
  defp check_single(_ver1, "NOT_A_VALID_OPERATOR", _ver2), do: false

  defp compare_semver(ver1, ver2, equality) do
    with {:ok, v1} <- Version.parse(ver1),
         {:ok, v2} <- Version.parse(ver2) do
      Version.compare(v1, v2) == equality
    else
      _ -> false
    end
  end

  defp compare_num(ver1, ver2, equality) do
    with {v1, ""} <- Float.parse(ver1),
         {v2, ""} <- Float.parse(ver2) do
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

  defp compare_date(ver1, ver2, equality) do
    with {:ok, utc_date1, _offset} <- DateTime.from_iso8601(ver1),
         {:ok, utc_date2, _offset} <- DateTime.from_iso8601(ver2) do
      DateTime.compare(utc_date1, utc_date2) == equality
    else
      _ -> false
    end
  end

  defp check_multiple(value, "IN", values), do: value in values
  defp check_multiple(value, "NOT_IN", values), do: value not in values

  defp check_multiple(value, "STR_CONTAINS", values), do: Enum.any?(values, &String.contains?(value, &1))

  defp check_multiple(value, "STR_ENDS_WITH", values), do: Enum.any?(values, &String.ends_with?(value, &1))

  defp check_multiple(value, "STR_STARTS_WITH", values), do: Enum.any?(values, &String.starts_with?(value, &1))

  defp find_value(nil, _name), do: nil

  defp find_value(ctx, name) do
    Map.get(
      ctx,
      String.to_atom(Recase.to_snake(name)),
      find_value(Map.get(ctx, :properties), name)
    )
  end
end
