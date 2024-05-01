defmodule Unleash.ClientSpecificationTest do
  @moduledoc false
  use ExUnit.Case

  @specification_path "priv/client-specification/specifications"

  @specs "#{@specification_path}/index.json"
         |> File.read!()
         |> Jason.decode!()
  @specs
  |> List.wrap()
  |> Enum.reject(fn path -> path =~ "15" end)
  |> Enum.reject(fn path -> path =~ "16" end)
  |> Enum.reject(fn path -> path =~ "17" end)
  |> Enum.each(fn spec ->
    test_spec =
      "#{@specification_path}/#{spec}"
      |> File.read!()
      |> Jason.decode!()

    %{"name" => name, "state" => state} = test_spec

    tests = Map.get(test_spec, "tests", [])

    variant_tests = Map.get(test_spec, "variantTests", [])

    @state state

    describe name do
      setup do
        stop_supervised(Unleash.Repo)
        state = Unleash.Features.from_map!(@state)
        {:ok, _pid} = start_supervised({Unleash.Repo, state})

        :ok
      end

      Enum.each(tests, fn %{"context" => ctx, "description" => t, "expectedResult" => expected, "toggleName" => feature} ->
        @context ctx
        @feature feature
        @expected expected

        test t do
          context = entity_from_file(@context)

          result = @expected == Unleash.enabled?(@feature, context)

          Process.sleep(50)

          unless result do
            IO.inspect("------------------------------------------")
            IO.inspect(context)
            IO.inspect(@feature)

            @feature |> Unleash.Repo.get_feature() |> IO.inspect()

            assert result
          end
        end
      end)

      Enum.each(variant_tests, fn %{
                                    "context" => ctx,
                                    "description" => t,
                                    "expectedResult" => expected,
                                    "toggleName" => feature
                                  } ->
        @context ctx
        @feature feature
        @expected Map.delete(expected, "feature_enabled")

        test t do
          context = entity_from_file(@context)

          result = entity_from_file(@expected) == Unleash.get_variant(@feature, context)

          unless result do
            IO.inspect("------------------------------------------")
            IO.inspect(context)
            IO.inspect(@feature)

            @feature |> Unleash.Repo.get_feature() |> IO.inspect()

            assert result
          end
        end
      end)
    end
  end)

  defp entity_from_file(e) do
    Map.new(e, fn
      {"payload", v} -> {:payload, v}
      {k, v} when is_map(v) -> {String.to_atom(Recase.to_snake(k)), entity_from_file(v)}
      {k, v} -> {String.to_atom(Recase.to_snake(k)), v}
    end)
  end
end
