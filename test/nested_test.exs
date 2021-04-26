defmodule NestedTest do
  @moduledoc false

  use ExUnit.Case

  ###
  describe "list container - nested map" do
    defmodule NestedA do
      use Argx

      defconfig(MapRule, [
        a(:string, 2..8) || get_default(),
        b(:integer, :empty),
        c(:float, :auto),
        d(:boolean, :optional)
      ])

      defconfig(OneRule, [one({:list, MapRule}), another(:string)])

      def get(params), do: match(params, [OneRule])

      def get_default, do: "default"
      def fmt_errors({:error, _} = errors), do: errors
      def fmt_errors(new_args), do: new_args
    end

    test "list -> map - mixed ok & errors" do
      list_data = [
        # line 1: all are invalid
        %{a: "a", b: 0, c: "a", d: "boolean"},
        # line 2: all are invalid
        %{a: "a", b: "b", c: "a", d: "true"},
        # line 3: all are valid
        %{a: "hello", b: 1, c: "1.2", d: true}
      ]

      args = %{one: list_data}

      expected =
        {:error,
         [
           error_type: ["one:1:c", "one:1:d", "one:2:b", "one:2:c", "one:2:d"],
           lacked: [:another, "one:1:b"],
           out_of_range: ["one:1:a", "one:2:a"]
         ]}

      assert expected == NestedA.get(args)
    end

    test "list -> map - case 1 - params is map - ok" do
      list_data = [
        %{a: "hello", b: 1, c: "1.2", d: true}
      ]

      args = %{one: list_data, another: "another"}

      expected_list_data = [
        %{a: "hello", b: 1, c: 1.2, d: true}
      ]

      expected_args = %{one: expected_list_data, another: "another"}

      assert expected_args == NestedA.get(args)
    end

    ###
    test "ok - ignore more fields" do
      list_data = [
        %{a: "hello1", b: 1, c: "1.1", d: true, e: 1, f: 2},
        %{a: "hello2", b: 2, c: "1.2", d: true, e: 1, f: 2}
      ]

      args = %{one: list_data, another: "another", more: "more", more_more: "more more"}

      expected_list_data = [
        %{a: "hello1", b: 1, c: 1.1, d: true},
        %{a: "hello2", b: 2, c: 1.2, d: true}
      ]

      expected_args = %{one: expected_list_data, another: "another"}

      assert expected_args == NestedA.get(args)
    end

    test "ok - nested list - empty" do
      args = %{
        one: [],
        another: "another"
      }

      expected_args = %{
        one: [],
        another: "another"
      }

      assert expected_args == NestedA.get(args)
    end

    test "ok - nested list - 1 records" do
      args = %{
        one: [
          %{a: "hello1", b: 1, c: "1.1", d: true}
        ],
        another: "another"
      }

      expected_args = %{
        one: [
          %{a: "hello1", b: 1, c: 1.1, d: true}
        ],
        another: "another"
      }

      assert expected_args == NestedA.get(args)
    end

    test "ok - nested list - 2 records" do
      args = %{
        one: [
          %{a: "hello1", b: 1, c: "1.1", d: true},
          %{a: "hello2", b: 2, c: "2.2", d: true}
        ],
        another: "another"
      }

      expected_args = %{
        one: [
          %{a: "hello1", b: 1, c: 1.1, d: true},
          %{a: "hello2", b: 2, c: 2.2, d: true}
        ],
        another: "another"
      }

      assert expected_args == NestedA.get(args)
    end
  end

  describe "list container - nested list" do
  end

  describe "list container - nested value" do
  end

  ###
  describe "map container - nested map" do
  end

  describe "map container - nested list" do
  end

  describe "map container - nested value" do
  end

  ###
  describe "N level nested" do
    defmodule NestedN do
      @moduledoc false

      use Argx

      defconfig(MapRule, [
        a(:string, 2..8) || get_default(),
        b(:integer, :empty),
        c(:float, :auto),
        d(:boolean, :optional)
      ])

      defconfig(ListRule, [aa(:string), bb({:list, MapRule})])
      defconfig(OneRule, [two({:list, ListRule}), another(:integer)])

      def get(params), do: match(params, [OneRule])

      def get_default, do: "default"
      def fmt_errors({:error, _} = errors), do: errors
      def fmt_errors(new_args), do: new_args
    end

    test "list -> map -> list - mixed ok & errors" do
      list_data = [
        %{aa: 1, bb: "bb"},
        %{
          aa: 1,
          bb: [
            # line 1: all are invalid
            %{a: "a", b: 0, c: "a", d: "boolean"},
            # line 2: all are invalid
            %{a: "a", b: "b", c: "a", d: "true"},
            # line 3: all are valid
            %{a: "hello", b: 1, c: "1.2", d: true}
          ]
        },
        %{aa: nil, bb: nil}
      ]

      args = %{two: list_data}

      expected = {
        :error,
        [
          error_type: [
            "two:1:aa",
            "two:1:bb",
            "two:2:aa",
            "two:2:bb:1:c",
            "two:2:bb:1:d",
            "two:2:bb:2:b",
            "two:2:bb:2:c",
            "two:2:bb:2:d"
          ],
          lacked: [:another, "two:2:bb:1:b", "two:3:aa", "two:3:bb"],
          out_of_range: ["two:2:bb:1:a", "two:2:bb:2:a"]
        ]
      }

      assert expected == NestedN.get(args)
    end

    test "list -> map -> list - ok" do
      list_data = [
        %{aa: "aa", bb: []},
        %{
          aa: "aaa",
          bb: [
            %{a: "hello1", b: 1, c: "1.1", d: true},
            %{a: "hello2", b: 2, c: "1.2", d: false}
          ]
        },
        %{aa: "aaaa", bb: []}
      ]

      args = %{two: list_data, another: 1}

      expected_list_data = [
        %{aa: "aa", bb: []},
        %{
          aa: "aaa",
          bb: [
            %{a: "hello1", b: 1, c: 1.1, d: true},
            %{a: "hello2", b: 2, c: 1.2, d: false}
          ]
        },
        %{aa: "aaaa", bb: []}
      ]

      expected_args = %{two: expected_list_data, another: 1}
      assert expected_args == NestedN.get(args)
    end
  end

  # TODO: return args should be sorted as origin args
  #  test "list -> map - case 2 - params is keyword - ok" do
  #      list_data = [
  #        %{a: "hello", b: 1, c: "1.2", d: true}
  #      ]
  #
  #      args = [one: list_data, another: "another"]
  #
  #      expected_list_data = [
  #        %{a: "hello", b: 1, c: 1.2, d: true}
  #      ]
  #
  #      expected_args = [one: expected_list_data, another: "another"]
  #
  #      assert expected_args == NestedN.get(args)
  #    end
  #
  #  test "ok - order - params is keyword" do
  #    args = [a: "a", b: "a", c: "a", yes: "a", no: "a", h: "a"]
  #    assert args == NestedN.get_more(args)
  #  end
end
