defmodule Unleash.Strategy.ConstraintTest do
  use ExUnit.Case
  use ExUnitProperties

  alias Unleash.Strategy.Constraint

  describe "IN" do
    property "returns false if the list is empty" do
      check all context_name <- string(:alphanumeric, min_length: 1),
                value <- string(:alphanumeric, min_length: 1) do
        refute Constraint.verify_all(
                 [%{"contextName" => context_name, "operator" => "IN", "values" => []}],
                 %{properties: %{String.to_atom(context_name) => value}}
               )
      end
    end

    property "returns false if it's not in the list" do
      check all context_name <- string(?a..?z, min_length: 1),
                value <- string(:alphanumeric, min_length: 1),
                values <-
                  list_of(string(:alphanumeric, min_length: 1)) do
        values = values -- [value]

        refute Constraint.verify_all(
                 [%{"contextName" => context_name, "operator" => "IN", "values" => values}],
                 %{properties: %{String.to_atom(context_name) => value}}
               )
      end
    end

    property "returns true if it's not in the list" do
      check all context_name <- string(?a..?z, min_length: 1),
                value <- string(:alphanumeric, min_length: 1),
                values <-
                  list_of(string(:alphanumeric, min_length: 1)) do
        values = values ++ [value]

        assert Constraint.verify_all(
                 [%{"contextName" => context_name, "operator" => "IN", "values" => values}],
                 %{properties: %{String.to_atom(context_name) => value}}
               )
      end
    end
  end

  describe "NOT_IN" do
    property "returns true if the list is empty" do
      check all context_name <- string(:alphanumeric, min_length: 1),
                value <- string(:alphanumeric, min_length: 1) do
        assert Constraint.verify_all(
                 [%{"contextName" => context_name, "operator" => "NOT_IN", "values" => []}],
                 %{properties: %{String.to_atom(context_name) => value}}
               )
      end
    end

    property "returns true if it's not in the list" do
      check all context_name <- string(?a..?z, min_length: 1),
                value <- string(:alphanumeric, min_length: 1),
                values <-
                  list_of(string(:alphanumeric, min_length: 1)) do
        values = values -- [value]

        assert Constraint.verify_all(
                 [%{"contextName" => context_name, "operator" => "NOT_IN", "values" => values}],
                 %{properties: %{String.to_atom(context_name) => value}}
               )
      end
    end

    property "returns false if it's not in the list" do
      check all context_name <- string(?a..?z, min_length: 1),
                value <- string(:alphanumeric, min_length: 1),
                values <-
                  list_of(string(:alphanumeric, min_length: 1)) do
        values = values ++ [value]

        refute Constraint.verify_all(
                 [%{"contextName" => context_name, "operator" => "NOT_IN", "values" => values}],
                 %{properties: %{String.to_atom(context_name) => value}}
               )
      end
    end
  end

  describe "DATE_AFTER" do
    test "date eq" do
      refute Constraint.verify_all(
               [%{"contextName" => "date", "operator" => "DATE_AFTER", "value" => "2024-06-06T12:12:12Z"}],
               %{properties: %{date: "2024-06-06T12:12:12.0Z"}}
             )
    end

    test "date lt" do
      refute Constraint.verify_all(
               [%{"contextName" => "date", "operator" => "DATE_AFTER", "value" => "2024-06-06T12:12:12Z"}],
               %{properties: %{date: "2023-06-01T12:12:12.0Z"}}
             )

      refute Constraint.verify_all(
               [%{"contextName" => "date", "operator" => "DATE_AFTER", "value" => "2024-06-06T12:12:12Z"}],
               %{properties: %{date: "2024-06-06T12:12:11.0Z"}}
             )
    end

    test "date gt" do
      assert Constraint.verify_all(
               [%{"contextName" => "date", "operator" => "DATE_AFTER", "value" => "2024-06-06T12:12:12Z"}],
               %{properties: %{date: "2024-06-06T12:12:13.0Z"}}
             )

      assert Constraint.verify_all(
               [%{"contextName" => "date", "operator" => "DATE_AFTER", "value" => "2024-06-06T12:12:12Z"}],
               %{properties: %{date: "2025-06-06T12:12:12.0Z"}}
             )
    end
  end

  describe "DATE_BEFORE" do
    test "date eq" do
      refute Constraint.verify_all(
               [%{"contextName" => "date", "operator" => "DATE_BEFORE", "value" => "2024-06-06T12:12:12Z"}],
               %{properties: %{date: "2024-06-06T12:12:12.0Z"}}
             )
    end

    test "date lt" do
      assert Constraint.verify_all(
               [%{"contextName" => "date", "operator" => "DATE_BEFORE", "value" => "2024-06-06T12:12:12Z"}],
               %{properties: %{date: "2023-06-01T12:12:12.0Z"}}
             )

      assert Constraint.verify_all(
               [%{"contextName" => "date", "operator" => "DATE_BEFORE", "value" => "2024-06-06T12:12:12Z"}],
               %{properties: %{date: "2024-06-06T12:12:11.0Z"}}
             )
    end

    test "date gt" do
      refute Constraint.verify_all(
               [%{"contextName" => "date", "operator" => "DATE_BEFORE", "value" => "2024-06-06T12:12:12Z"}],
               %{properties: %{date: "2024-06-06T12:12:13.0Z"}}
             )

      refute Constraint.verify_all(
               [%{"contextName" => "date", "operator" => "DATE_BEFORE", "value" => "2024-06-06T12:12:12Z"}],
               %{properties: %{date: "2025-06-06T12:12:12.0Z"}}
             )
    end
  end

  describe "all NUM types" do
    test "test in loop" do
      for_result =
        for operator <- ~w[NUM_EQ NUM_LT NUM_LTE NUM_GT NUM_GTE], value1 <- [0, 1], value2 <- [0, 1] do
          result =
            Constraint.verify_all(
              [%{"contextName" => "num", "operator" => operator, "value" => to_string(value2)}],
              %{properties: %{num: to_string(value1)}}
            )

          IO.iodata_to_binary([to_string(result), " = ", to_string(value1), " ", operator, " ", to_string(value2), "\n"])
        end

      assert Enum.join(for_result, "") == """
             true = 0 NUM_EQ 0
             false = 0 NUM_EQ 1
             false = 1 NUM_EQ 0
             true = 1 NUM_EQ 1
             false = 0 NUM_LT 0
             true = 0 NUM_LT 1
             false = 1 NUM_LT 0
             false = 1 NUM_LT 1
             true = 0 NUM_LTE 0
             true = 0 NUM_LTE 1
             false = 1 NUM_LTE 0
             true = 1 NUM_LTE 1
             false = 0 NUM_GT 0
             false = 0 NUM_GT 1
             true = 1 NUM_GT 0
             false = 1 NUM_GT 1
             true = 0 NUM_GTE 0
             false = 0 NUM_GTE 1
             true = 1 NUM_GTE 0
             true = 1 NUM_GTE 1
             """
    end
  end

  describe "all STR types" do
    test "STARTS_WITH" do
      assert Constraint.verify_all(
               [%{"contextName" => "str", "operator" => "STR_STARTS_WITH", "values" => ["ac"]}],
               %{properties: %{str: "ac"}}
             )

      refute Constraint.verify_all(
               [%{"contextName" => "str", "operator" => "STR_STARTS_WITH", "values" => ["ac"]}],
               %{properties: %{str: "a"}}
             )

      assert Constraint.verify_all(
               [%{"contextName" => "str", "operator" => "STR_STARTS_WITH", "values" => ["ac"]}],
               %{properties: %{str: "acd"}}
             )

      refute Constraint.verify_all(
               [%{"contextName" => "str", "operator" => "STR_STARTS_WITH", "values" => ["ac"]}],
               %{properties: %{str: "c"}}
             )
    end

    test "ENDS_WITH" do
      assert Constraint.verify_all(
               [%{"contextName" => "str", "operator" => "STR_ENDS_WITH", "values" => ["ac"]}],
               %{properties: %{str: "ac"}}
             )

      refute Constraint.verify_all(
               [%{"contextName" => "str", "operator" => "STR_ENDS_WITH", "values" => ["ac"]}],
               %{properties: %{str: "a"}}
             )

      assert Constraint.verify_all(
               [%{"contextName" => "str", "operator" => "STR_ENDS_WITH", "values" => ["ac"]}],
               %{properties: %{str: "aac"}}
             )

      refute Constraint.verify_all(
               [%{"contextName" => "str", "operator" => "STR_ENDS_WITH", "values" => ["ac"]}],
               %{properties: %{str: "c"}}
             )
    end

    test "CONTAINS" do
      assert Constraint.verify_all(
               [%{"contextName" => "str", "operator" => "STR_CONTAINS", "values" => ["ac"]}],
               %{properties: %{str: "ac"}}
             )

      refute Constraint.verify_all(
               [%{"contextName" => "str", "operator" => "STR_CONTAINS", "values" => ["ac"]}],
               %{properties: %{str: "aaa"}}
             )

      assert Constraint.verify_all(
               [%{"contextName" => "str", "operator" => "STR_CONTAINS", "values" => ["ac"]}],
               %{properties: %{str: "aacaa"}}
             )

      refute Constraint.verify_all(
               [%{"contextName" => "str", "operator" => "STR_CONTAINS", "values" => ["ac"]}],
               %{properties: %{str: "ca"}}
             )
    end
  end

  describe "SEMVER" do
    test "EQ" do
      assert Constraint.verify_all(
               [%{"contextName" => "ver", "operator" => "SEMVER_EQ", "value" => "1.0.1"}],
               %{properties: %{ver: "1.0.1"}}
             )

      refute Constraint.verify_all(
               [%{"contextName" => "ver", "operator" => "SEMVER_EQ", "value" => "1.0.0"}],
               %{properties: %{ver: "1.0.1"}}
             )
    end

    test "LT" do
      refute Constraint.verify_all(
               [%{"contextName" => "ver", "operator" => "SEMVER_LT", "value" => "1.0.1"}],
               %{properties: %{ver: "1.0.1"}}
             )

      assert Constraint.verify_all(
               [%{"contextName" => "ver", "operator" => "SEMVER_LT", "value" => "1.0.2"}],
               %{properties: %{ver: "1.0.0"}}
             )

      refute Constraint.verify_all(
               [%{"contextName" => "ver", "operator" => "SEMVER_LT", "value" => "1.0.2"}],
               %{properties: %{ver: "1.0.3"}}
             )
    end

    test "GT" do
      refute Constraint.verify_all(
               [%{"contextName" => "ver", "operator" => "SEMVER_GT", "value" => "1.0.1"}],
               %{properties: %{ver: "1.0.1"}}
             )

      assert Constraint.verify_all(
               [%{"contextName" => "ver", "operator" => "SEMVER_GT", "value" => "1.0.1"}],
               %{properties: %{ver: "1.0.2"}}
             )

      refute Constraint.verify_all(
               [%{"contextName" => "ver", "operator" => "SEMVER_GT", "value" => "1.0.1"}],
               %{properties: %{ver: "1.0.0"}}
             )
    end
  end
end
