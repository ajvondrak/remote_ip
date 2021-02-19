defmodule Integration.Tests do
  @path Path.join(__DIR__, "tests")

  if IO.ANSI.enabled?() do
    @color "--color"
  else
    @color "--no-color"
  end

  def run do
    {:ok, _} = Agent.start_link(fn -> [] end, name: :summary)
    File.ls!(@path) |> Enum.each(&run/1)
    summarize()
  end

  def run(app) do
    IO.puts("---> Running integration tests on #{app} app")

    with :ok <- mix(app, "deps.clean", ["--build", "remote_ip"]),
         :ok <- mix(app, "deps.get"),
         :ok <- mix(app, "test", [@color]) do
      track(app, :pass)
    else
      :error -> track(app, :fail)
    end
  end

  def mix(app, task, args \\ []) do
    cmd = [task | args]
    dir = Path.expand(app, @path)
    out = IO.binstream(:stdio, :line)

    IO.puts(["-->", "mix" | cmd] |> Enum.join(" "))
    {_, status} = System.cmd("mix", cmd, cd: dir, into: out)

    if status == 0 do
      :ok
    else
      :error
    end
  end

  def track(app, flag) do
    Agent.update(:summary, fn flags -> flags ++ [{app, flag}] end)
  end

  def summarize do
    Agent.get(:summary, fn summary ->
      counts(summary)

      Enum.each(summary, fn
        {app, :pass} -> pass(app)
        {app, :fail} -> fail(app)
      end)
    end)
  end

  def counts(summary) do
    tests = length(summary)
    fails = Enum.count(summary, fn {_, flag} -> flag == :fail end)
    msg = [plural(tests, "integration test"), ", ", plural(fails, "failure")]

    IO.puts("")

    if fails > 0 do
      IO.ANSI.format([:red | msg]) |> IO.puts()
    else
      IO.ANSI.format([:green | msg]) |> IO.puts()
    end
  end

  def plural(1, string), do: "1 #{string}"
  def plural(n, string), do: "#{n} #{string}s"

  def pass(app) do
    IO.ANSI.format([:green, "  ✓ #{app}"]) |> IO.puts()
  end

  def fail(app) do
    IO.ANSI.format([:red, "  ✗ #{app}"]) |> IO.puts()
    System.at_exit(fn _ -> exit({:shutdown, 1}) end)
  end
end

Integration.Tests.run()
