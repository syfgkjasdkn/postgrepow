config = []

data = fn size ->
  Enum.map(1..size, fn key ->
    {to_string(key), %{some: :data, for: key}}
  end)
end

reset_db = fn input ->
  # clean
  PostgrePow.Repo.truncate(PostgrePow.SessionStore)

  # insert
  input
  |> Stream.chunk_every(1000)
  |> Stream.map(fn chunk ->
    Enum.map(chunk, fn {key, value} ->
      %{
        key: PostgrePow._key(config, key),
        value: value
      }
    end)
  end)
  |> Stream.each(fn chunk ->
    PostgrePow.Repo.insert_all(PostgrePow.SessionStore, chunk)
  end)
  |> Stream.run()
end

## TODO
# clean_ets = fn ->
#   nil
# end

restart_postgrepow = fn input ->
  reset_db.(input)
  PostgrePow.clean_ets()
end

{:ok, _pid} = PostgrePow.start_link(config)

Benchee.run(
  %{
    ## TODO
    # "cold cache" =>
    #   {fn input ->
    #      Enum.each(input, fn {key, _data} ->
    #        PostgrePow.get(config, key)
    #      end)
    #    end,
    #    before_scenario: fn input ->
    #      clean_ets.()
    #      input
    #    end},
    "cold -> hot cache" => fn input ->
      Enum.each(input, fn {key, _data} ->
        PostgrePow.get(config, key)
      end)
    end,
    "starting with hot cache" =>
      {fn input ->
         Enum.each(input, fn {key, _data} ->
           PostgrePow.get(config, key)
         end)
       end,
       before_scenario: fn input ->
         Enum.each(input, fn {key, _data} ->
           PostgrePow.get(config, key)
         end)

         input
       end}
  },
  inputs: %{
    "small (1k)" => data.(1_000),
    "middle (10k)" => data.(10_000),
    "big (100k)" => data.(100_000)
  },
  before_scenario: fn input ->
    restart_postgrepow.(input)
    input
  end,
  save: [tag: "first-try"]
)
