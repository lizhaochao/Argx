defmodule MatcherTest do
  use ExUnit.Case

  alias Argx.Matcher

  @curr_m __MODULE__

  describe "argx match ok" do
    test "1 field" do
      with args <- [one: "a"],
           configs <- [one: get_config(:string)],
           {errors, _} <- argx_match().(args, configs, @curr_m) do
        assert [] == errors
      else
        err -> flunk("#{inspect(err)}")
      end
    end

    test "2 fields" do
      with args <- [one: "a", two: 2],
           configs <- [one: get_config(:string), two: get_config(:integer)],
           {errors, _} <- argx_match().(args, configs, @curr_m) do
        assert [] == errors
      else
        err -> flunk("#{inspect(err)}")
      end
    end

    test "complex" do
      with range_expr <- quote(do: 2..10),
           args <- [one: "", two: 3, three: [], four: 1.2, five: true, six: %{a: 1}],
           configs <- [
             one: get_config(:string, empty: true, default: "hello"),
             two: get_config(:integer, auto: true, range: range_expr),
             three: get_config(:list),
             four: get_config(:float),
             five: get_config(:boolean),
             six: get_config(:map, empty: true)
           ],
           {errors, _} <- argx_match().(args, configs, @curr_m) do
        assert [] == errors
      else
        err -> flunk("#{inspect(err)}")
      end
    end

    test "return new args - fill default value, auto convert value" do
      with args <- [one: "", two: "3"],
           configs <- [
             one: get_config(:string, default: "hello"),
             two: get_config(:integer, auto: true)
           ],
           {errors, new_args} <- argx_match().(args, configs, @curr_m) do
        assert [] == errors
        assert [one: "hello", two: 3] == new_args
      else
        err -> flunk("#{inspect(err)}")
      end
    end
  end

  describe "argx match error" do
    test "1 field" do
      with args <- [one: 1],
           configs <- [one: get_config(:string)],
           {errors, _} <- argx_match().(args, configs, @curr_m) do
        assert [{:error_type, [:one]}] == errors
      else
        err -> flunk("#{inspect(err)}")
      end
    end

    test "2 fields" do
      with args <- [one: 1, two: "a"],
           configs <- [one: get_config(:string), two: get_config(:integer)],
           {errors, _} <- argx_match().(args, configs, @curr_m) do
        assert [{:error_type, [:two, :one]}] == errors
      else
        err -> flunk("#{inspect(err)}")
      end

      with args <- [one: 1, two: nil],
           configs <- [one: get_config(:string), two: get_config(:integer)],
           {errors, _} <- argx_match().(args, configs, @curr_m) do
        assert [{:lacked, [:two]}, {:error_type, [:one]}] == errors
      else
        err -> flunk("#{inspect(err)}")
      end
    end

    test "complex" do
      with range_expr <- quote(do: 2..10),
           args <- [one: 1, two: 22, three: 1, four: "a", five: "1", six: %{}],
           configs <- [
             one: get_config(:string, empty: true, default: "hello"),
             two: get_config(:integer, auto: true, range: range_expr),
             three: get_config(:list),
             four: get_config(:float),
             five: get_config(:boolean),
             six: get_config(:map, empty: true)
           ],
           {errors, _} <- argx_match().(args, configs, @curr_m) do
        assert [
                 lacked: [:six],
                 out_of_range: [:two],
                 error_type: [:five, :four, :three, :one]
               ] == errors
      else
        err -> flunk("#{inspect(err)}")
      end
    end
  end

  describe "argx match nested ok" do
    test "nested - depth 2 - list->map->string" do
      configs = [
        one: %Argx.Config{
          type: :list,
          auto: false,
          range: nil,
          default: nil,
          optional: false,
          empty: false,
          nested: %{
            a: %Argx.Config{
              type: :string,
              auto: false,
              range: nil,
              default: nil,
              optional: false,
              empty: false,
              nested: nil
            }
          }
        }
      ]

      args = [one: [%{a: "a"}]]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [] == errors
    end

    test "nested - depth 3 - list->map->list->integer" do
      configs = [
        one: %Argx.Config{
          type: :list,
          auto: false,
          range: nil,
          default: nil,
          optional: false,
          empty: false,
          nested: %{
            a: %Argx.Config{
              type: :list,
              auto: false,
              range: nil,
              default: nil,
              optional: false,
              empty: false,
              nested: %{
                _: %Argx.Config{
                  type: :integer,
                  auto: true,
                  range: nil,
                  default: nil,
                  optional: false,
                  empty: false,
                  nested: nil
                }
              }
            }
          }
        }
      ]

      args1 = [one: [%{a: [1]}]]
      args2 = [one: [%{a: ["1"]}]]
      args3 = [one: [%{a: [1, 2]}]]
      args4 = [one: [%{a: ["1", "2"]}]]
      args5 = [one: [%{a: []}]]

      [args1, args2, args3, args4, args5]
      |> Enum.each(fn args ->
        {errors, _} = argx_match().(args, configs, @curr_m)
        assert [] == errors
      end)
    end

    test "nested - depth 4 - list->map->list->map->list->integer" do
      configs = [
        one: %Argx.Config{
          type: :list,
          auto: false,
          range: nil,
          default: nil,
          optional: false,
          empty: false,
          nested: %{
            a: %Argx.Config{
              type: :list,
              auto: false,
              range: nil,
              default: nil,
              optional: false,
              empty: false,
              nested: %{
                b: %Argx.Config{
                  type: :list,
                  auto: true,
                  range: nil,
                  default: nil,
                  optional: false,
                  empty: false,
                  nested: %{
                    _: %Argx.Config{
                      type: :integer,
                      auto: true,
                      range: nil,
                      default: nil,
                      optional: false,
                      empty: false,
                      nested: nil
                    }
                  }
                }
              }
            }
          }
        }
      ]

      args1 = [one: [%{a: [%{b: [1]}]}]]
      args2 = [one: [%{a: [%{b: ["1"]}]}]]
      args3 = [one: [%{a: [%{b: [1, 2]}]}]]
      args4 = [one: [%{a: [%{b: ["1", "2"]}]}]]
      args5 = [one: [%{a: [%{b: []}]}]]

      [args1, args2, args3, args4, args5]
      |> Enum.each(fn args ->
        {errors, _} = argx_match().(args, configs, @curr_m)
        assert [] == errors
      end)
    end

    ##
    test "nested - depth 2 - map->map" do
      configs = [
        one: %Argx.Config{
          type: :map,
          auto: false,
          range: nil,
          default: nil,
          optional: false,
          empty: false,
          nested: %{
            a: %Argx.Config{
              type: :map,
              auto: false,
              range: nil,
              default: nil,
              optional: false,
              empty: false,
              nested: nil
            }
          }
        }
      ]

      args = [one: %{a: %{}}]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [] == errors
    end

    test "nested - depth 3 - map->list->map" do
      configs = [
        one: %Argx.Config{
          type: :map,
          auto: false,
          range: nil,
          default: nil,
          optional: false,
          empty: false,
          nested: %{
            a: %Argx.Config{
              type: :list,
              auto: false,
              range: nil,
              default: nil,
              optional: false,
              empty: false,
              nested: %{
                b: %Argx.Config{
                  type: :map,
                  auto: false,
                  range: nil,
                  default: nil,
                  optional: false,
                  empty: false,
                  nested: nil
                }
              }
            }
          }
        }
      ]

      args = [one: %{a: [%{b: %{}}]}]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [] == errors
    end

    test "nested - depth 3 - map->map->map" do
      configs = [
        one: %Argx.Config{
          type: :map,
          auto: false,
          range: nil,
          default: nil,
          optional: false,
          empty: false,
          nested: %{
            a: %Argx.Config{
              type: :map,
              auto: false,
              range: nil,
              default: nil,
              optional: false,
              empty: false,
              nested: %{
                b: %Argx.Config{
                  type: :map,
                  auto: false,
                  range: nil,
                  default: nil,
                  optional: false,
                  empty: false,
                  nested: nil
                }
              }
            }
          }
        }
      ]

      args = [one: %{a: %{b: %{}}}]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [] == errors
    end

    test "nested - depth 4 - map->map->map->map" do
      configs = [
        one: %Argx.Config{
          type: :map,
          auto: false,
          range: nil,
          default: nil,
          optional: false,
          empty: false,
          nested: %{
            a: %Argx.Config{
              type: :map,
              auto: false,
              range: nil,
              default: nil,
              optional: false,
              empty: false,
              nested: %{
                b: %Argx.Config{
                  type: :map,
                  auto: false,
                  range: nil,
                  default: nil,
                  optional: false,
                  empty: false,
                  nested: %{
                    c: %Argx.Config{
                      type: :map,
                      auto: false,
                      range: nil,
                      default: nil,
                      optional: false,
                      empty: false,
                      nested: nil
                    }
                  }
                }
              }
            }
          }
        }
      ]

      args = [one: %{a: %{b: %{c: %{}}}}]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [] == errors
    end

    test "nested - depth 4 - map->map->list->integer" do
      configs = [
        one: %Argx.Config{
          type: :map,
          auto: false,
          range: nil,
          default: nil,
          optional: false,
          empty: false,
          nested: %{
            a: %Argx.Config{
              type: :map,
              auto: false,
              range: nil,
              default: nil,
              optional: false,
              empty: false,
              nested: %{
                b: %Argx.Config{
                  type: :list,
                  auto: false,
                  range: nil,
                  default: nil,
                  optional: false,
                  empty: false,
                  nested: %{
                    _: %Argx.Config{
                      type: :integer,
                      auto: false,
                      range: nil,
                      default: nil,
                      optional: false,
                      empty: false,
                      nested: nil
                    }
                  }
                }
              }
            }
          }
        }
      ]

      args = [one: %{a: %{b: [1, 2, 3]}}]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [] == errors
    end

    ##
    test "nested - depth 2 - list->list" do
      configs = [
        one: %Argx.Config{
          type: :list,
          auto: false,
          range: nil,
          default: nil,
          optional: false,
          empty: false,
          nested: %{
            _: %Argx.Config{
              type: :list,
              auto: false,
              range: nil,
              default: nil,
              optional: false,
              empty: false,
              nested: nil
            }
          }
        }
      ]

      args = [one: [[1], [2]]]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [] == errors
    end

    test "nested - depth 3 - list->list->list" do
      configs = [
        one: %Argx.Config{
          type: :list,
          auto: false,
          range: nil,
          default: nil,
          optional: false,
          empty: false,
          nested: %{
            _: %Argx.Config{
              type: :list,
              auto: false,
              range: nil,
              default: nil,
              optional: false,
              empty: false,
              nested: %{
                _: %Argx.Config{
                  type: :list,
                  auto: false,
                  range: nil,
                  default: nil,
                  optional: false,
                  empty: false,
                  nested: nil
                }
              }
            }
          }
        }
      ]

      args = [one: [[[1]], [[2]]]]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [] == errors
    end

    test "nested - depth 3 - list->list->integer" do
      configs = [
        one: %Argx.Config{
          type: :list,
          auto: false,
          range: nil,
          default: nil,
          optional: false,
          empty: false,
          nested: %{
            _: %Argx.Config{
              type: :list,
              auto: false,
              range: nil,
              default: nil,
              optional: false,
              empty: false,
              nested: %{
                _: %Argx.Config{
                  type: :integer,
                  auto: false,
                  range: nil,
                  default: nil,
                  optional: false,
                  empty: false,
                  nested: nil
                }
              }
            }
          }
        }
      ]

      args = [one: [[1], [2]]]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [] == errors
    end

    test "nested - depth 4 - list->list->list->integer" do
      configs = [
        one: %Argx.Config{
          type: :list,
          auto: false,
          range: nil,
          default: nil,
          optional: false,
          empty: false,
          nested: %{
            _: %Argx.Config{
              type: :list,
              auto: false,
              range: nil,
              default: nil,
              optional: false,
              empty: false,
              nested: %{
                _: %Argx.Config{
                  type: :list,
                  auto: false,
                  range: nil,
                  default: nil,
                  optional: false,
                  empty: false,
                  nested: %{
                    _: %Argx.Config{
                      type: :integer,
                      auto: false,
                      range: nil,
                      default: nil,
                      optional: false,
                      empty: false,
                      nested: nil
                    }
                  }
                }
              }
            }
          }
        }
      ]

      args = [one: [[[1]], [[2]]]]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [] == errors
    end

    ##
    test "nested - depth 4 - complex" do
      configs = [
        one: %Argx.Config{
          type: :list,
          auto: false,
          range: nil,
          default: nil,
          optional: false,
          empty: false,
          nested: %{
            b: %Argx.Config{
              type: :boolean,
              auto: true,
              range: nil,
              default: nil,
              optional: true,
              empty: false,
              nested: nil
            },
            a: %Argx.Config{
              type: :list,
              auto: false,
              range: nil,
              default: nil,
              optional: false,
              empty: false,
              nested: %{
                z: %Argx.Config{
                  type: :list,
                  auto: false,
                  range: nil,
                  default: nil,
                  optional: false,
                  empty: false,
                  nested: %{
                    _: %Argx.Config{
                      type: :integer,
                      auto: true,
                      range: nil,
                      default: nil,
                      optional: true,
                      empty: true,
                      nested: nil
                    }
                  }
                }
              }
            }
          }
        },
        two: %Argx.Config{
          type: :string,
          auto: false,
          range: nil,
          default: "hi",
          optional: false,
          empty: false,
          nested: nil
        }
      ]

      args1 = [one: [%{a: [%{z: [1]}], b: true}], two: "string"]
      args2 = [one: [%{a: [%{z: [1, 2]}], b: true}], two: "string"]
      args3 = [one: [%{a: [%{z: ["1", "2"]}], b: 0}], two: "string"]
      args4 = [one: [%{a: [%{z: [nil]}], b: 1}], two: "string"]
      args5 = [one: [%{a: [%{z: [0, 2, 3, nil]}], b: nil}], two: nil]

      [args1, args2, args3, args4, args5]
      |> Enum.each(fn args ->
        {errors, _} = argx_match().(args, configs, @curr_m)
        assert [] == errors
      end)
    end
  end

  describe "argx match nested error" do
    test "nested - depth 2 - list->map->string" do
      configs = [
        one: %Argx.Config{
          type: :list,
          auto: false,
          range: 1,
          default: nil,
          optional: false,
          empty: false,
          nested: %{
            a: %Argx.Config{
              type: :string,
              auto: false,
              range: nil,
              default: nil,
              optional: false,
              empty: false,
              nested: nil
            }
          }
        }
      ]

      args = [one: 1]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [{:error_type, [:one]}] == errors

      args = [one: [%{a: 1}]]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [{:error_type, ["one:1:a"]}] == errors

      args = [one: nil]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [lacked: [:one]] == errors

      args = [one: []]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [{:lacked, ["one:a"]}, {:out_of_range, [:one]}] == errors
    end

    test "nested - depth 3 - list->map->list->integer" do
      configs = [
        one: %Argx.Config{
          type: :list,
          auto: false,
          range: nil,
          default: nil,
          optional: false,
          empty: false,
          nested: %{
            a: %Argx.Config{
              type: :list,
              auto: false,
              range: 1,
              default: nil,
              optional: false,
              empty: false,
              nested: %{
                _: %Argx.Config{
                  type: :integer,
                  auto: true,
                  range: nil,
                  default: nil,
                  optional: false,
                  empty: false,
                  nested: nil
                }
              }
            }
          }
        }
      ]

      args = [one: [%{a: ["a"]}]]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [{:error_type, ["one:1:a:1"]}] == errors

      args = [one: [%{a: ["a", "b"]}]]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [{:out_of_range, ["one:1:a"]}, {:error_type, ["one:1:a:1", "one:1:a:2"]}] == errors

      args = [one: [%{a: nil}]]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [lacked: ["one:1:a"]] == errors
    end

    test "nested - depth 4 - list->map->list->map->list->integer" do
      configs = [
        one: %Argx.Config{
          type: :list,
          auto: false,
          range: nil,
          default: nil,
          optional: false,
          empty: false,
          nested: %{
            a: %Argx.Config{
              type: :list,
              auto: false,
              range: nil,
              default: nil,
              optional: false,
              empty: false,
              nested: %{
                b: %Argx.Config{
                  type: :list,
                  auto: true,
                  range: nil,
                  default: nil,
                  optional: false,
                  empty: false,
                  nested: %{
                    _: %Argx.Config{
                      type: :integer,
                      auto: true,
                      range: nil,
                      default: nil,
                      optional: false,
                      empty: false,
                      nested: nil
                    }
                  }
                }
              }
            }
          }
        }
      ]

      args = [one: [%{a: [%{b: ["a"]}]}]]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [{:error_type, ["one:1:a:1:b:1"]}] == errors

      args = [one: [%{a: [%{b: ["a", "b"]}]}]]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [error_type: ["one:1:a:1:b:1", "one:1:a:1:b:2"]] == errors

      args = [one: [%{a: [%{b: nil}]}]]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [lacked: ["one:1:a:1:b"]] == errors
    end

    ##
    test "nested - depth 2 - map->map" do
      configs = [
        one: %Argx.Config{
          type: :map,
          auto: false,
          range: nil,
          default: nil,
          optional: false,
          empty: false,
          nested: %{
            a: %Argx.Config{
              type: :map,
              auto: false,
              range: nil,
              default: nil,
              optional: false,
              empty: false,
              nested: nil
            }
          }
        }
      ]

      args = [one: %{a: 1}]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [{:error_type, ["one:a"]}] == errors

      args = [one: 1]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [{:error_type, [:one]}] == errors

      args = [one: %{a: nil}]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [lacked: ["one:a"]] == errors
    end

    test "nested - depth 3 - map->map->map" do
      configs = [
        one: %Argx.Config{
          type: :map,
          auto: false,
          range: nil,
          default: nil,
          optional: false,
          empty: false,
          nested: %{
            a: %Argx.Config{
              type: :map,
              auto: false,
              range: nil,
              default: nil,
              optional: false,
              empty: false,
              nested: %{
                b: %Argx.Config{
                  type: :map,
                  auto: false,
                  range: nil,
                  default: nil,
                  optional: false,
                  empty: false,
                  nested: nil
                }
              }
            }
          }
        }
      ]

      args = [one: %{a: %{b: 1}}]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [{:error_type, ["one:a:b"]}] == errors

      args = [one: %{a: %{b: nil}}]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [lacked: ["one:a:b"]] == errors
    end

    test "nested - depth 4 - map->map->map->map" do
      configs = [
        one: %Argx.Config{
          type: :map,
          auto: false,
          range: nil,
          default: nil,
          optional: false,
          empty: false,
          nested: %{
            a: %Argx.Config{
              type: :map,
              auto: false,
              range: nil,
              default: nil,
              optional: false,
              empty: false,
              nested: %{
                b: %Argx.Config{
                  type: :map,
                  auto: false,
                  range: nil,
                  default: nil,
                  optional: false,
                  empty: false,
                  nested: %{
                    c: %Argx.Config{
                      type: :map,
                      auto: false,
                      range: nil,
                      default: nil,
                      optional: false,
                      empty: false,
                      nested: nil
                    }
                  }
                }
              }
            }
          }
        }
      ]

      args = [one: %{a: %{b: %{c: 1}}}]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [{:error_type, ["one:a:b:c"]}] == errors

      args = [one: %{a: %{b: %{c: nil}}}]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [{:lacked, ["one:a:b:c"]}] == errors
    end

    ##
    test "nested - depth 2 - list->list" do
      configs = [
        one: %Argx.Config{
          type: :list,
          auto: false,
          range: nil,
          default: nil,
          optional: false,
          empty: false,
          nested: %{
            _: %Argx.Config{
              type: :list,
              auto: false,
              range: nil,
              default: nil,
              optional: false,
              empty: false,
              nested: nil
            }
          }
        }
      ]

      args = [one: [1]]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [{:error_type, ["one:1"]}] == errors

      args = [one: [nil]]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [lacked: ["one:1"]] == errors
    end

    test "nested - depth 3 - list->list->list" do
      configs = [
        one: %Argx.Config{
          type: :list,
          auto: false,
          range: nil,
          default: nil,
          optional: false,
          empty: false,
          nested: %{
            _: %Argx.Config{
              type: :list,
              auto: false,
              range: nil,
              default: nil,
              optional: false,
              empty: false,
              nested: %{
                _: %Argx.Config{
                  type: :list,
                  auto: false,
                  range: nil,
                  default: nil,
                  optional: false,
                  empty: false,
                  nested: nil
                }
              }
            }
          }
        }
      ]

      args = [one: [[1], [2]]]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [{:error_type, ["one:1:1", "one:2:1"]}] == errors

      args = [one: [[1, 3], [2, 4]]]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [error_type: ["one:1:1", "one:1:2", "one:2:1", "one:2:2"]] == errors

      args = [one: [[nil], [nil]]]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [lacked: ["one:1:1", "one:2:1"]] == errors
    end

    test "nested - depth 3 - list->list->integer" do
      configs = [
        one: %Argx.Config{
          type: :list,
          auto: false,
          range: nil,
          default: nil,
          optional: false,
          empty: false,
          nested: %{
            _: %Argx.Config{
              type: :list,
              auto: false,
              range: nil,
              default: nil,
              optional: false,
              empty: false,
              nested: %{
                _: %Argx.Config{
                  type: :integer,
                  auto: false,
                  range: nil,
                  default: nil,
                  optional: false,
                  empty: false,
                  nested: nil
                }
              }
            }
          }
        }
      ]

      args = [one: [["a"], [2]]]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [{:error_type, ["one:1:1"]}] == errors
    end

    test "nested - depth 4 - list->list->list->integer" do
      configs = [
        one: %Argx.Config{
          type: :list,
          auto: false,
          range: nil,
          default: nil,
          optional: false,
          empty: false,
          nested: %{
            _: %Argx.Config{
              type: :list,
              auto: false,
              range: nil,
              default: nil,
              optional: false,
              empty: false,
              nested: %{
                _: %Argx.Config{
                  type: :list,
                  auto: false,
                  range: nil,
                  default: nil,
                  optional: false,
                  empty: false,
                  nested: %{
                    _: %Argx.Config{
                      type: :integer,
                      auto: false,
                      range: nil,
                      default: nil,
                      optional: false,
                      empty: false,
                      nested: nil
                    }
                  }
                }
              }
            }
          }
        }
      ]

      args = [one: [[[nil]], [["a"]]]]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [{:lacked, ["one:1:1:1"]}, {:error_type, ["one:2:1:1"]}] == errors
    end

    ##
    test "nested - depth 4 - complex" do
      configs = [
        one: %Argx.Config{
          type: :list,
          auto: false,
          range: nil,
          default: nil,
          optional: false,
          empty: false,
          nested: %{
            b: %Argx.Config{
              type: :boolean,
              auto: true,
              range: nil,
              default: nil,
              optional: true,
              empty: false,
              nested: nil
            },
            a: %Argx.Config{
              type: :list,
              auto: false,
              range: nil,
              default: nil,
              optional: false,
              empty: false,
              nested: %{
                z: %Argx.Config{
                  type: :list,
                  auto: false,
                  range: nil,
                  default: nil,
                  optional: false,
                  empty: false,
                  nested: %{
                    _: %Argx.Config{
                      type: :integer,
                      auto: true,
                      range: nil,
                      default: nil,
                      optional: true,
                      empty: true,
                      nested: nil
                    }
                  }
                }
              }
            }
          }
        },
        two: %Argx.Config{
          type: :string,
          auto: false,
          range: nil,
          default: "hi",
          optional: false,
          empty: false,
          nested: nil
        }
      ]

      args = [one: [%{a: [%{z: ["a"]}], b: "a"}], two: 1]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [error_type: [:two, "one:1:b", "one:1:a:1:z:1"]] == errors

      args = [one: [%{a: [1], b: nil}], two: nil]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [{:error_type, ["one:1:a"]}] == errors

      args = [one: [%{a: [1, 2, 3], b: nil}], two: nil]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [{:error_type, ["one:1:a"]}] == errors

      args = [one: [1], two: "string"]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [{:error_type, [:one]}] == errors

      args = [one: nil, two: nil]
      {errors, _} = argx_match().(args, configs, @curr_m)
      assert [lacked: [:one]] == errors
    end
  end

  ###
  describe "with check match ok" do
    # the same as argx match
  end

  describe "with check match error" do
    # the same as argx match
  end

  ### helper
  def argx_match, do: Matcher.match(:argx)

  def get_config(type, opts \\ []) do
    %Argx.Config{
      type: type,
      auto: Keyword.get(opts, :auto, false),
      range: Keyword.get(opts, :range, nil),
      default: Keyword.get(opts, :default, nil),
      optional: Keyword.get(opts, :optional, false),
      empty: Keyword.get(opts, :empty, false),
      nested: Keyword.get(opts, :nested, nil)
    }
  end
end
