defmodule ArgxBench do
  use Benchfella

  @nested_configs [
    one: %Argx.Config{
      type: :list,
      auto: false,
      optional: false,
      empty: false,
      nested: %{
        a: %Argx.Config{
          type: :list,
          auto: false,
          optional: false,
          empty: false,
          nested: %{
            b: %Argx.Config{
              type: :list,
              auto: true,
              optional: false,
              empty: false,
              nested: %{
                _: %Argx.Config{
                  type: :integer,
                  auto: true,
                  optional: false,
                  empty: false
                }
              }
            }
          }
        }
      }
    }
  ]

  bench "deep match (4 nested level)" do
    args = [one: [%{a: [%{b: ["1", "2"]}]}]]
    argx_match = Argx.Matcher.match(:argx)
    argx_match.(args, @nested_configs, __MODULE__)
  end
end
