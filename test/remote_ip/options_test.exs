defmodule RemoteIp.OptionsTest do
  use ExUnit.Case, async: true

  defmodule MFA do
    use Agent

    def setup do
      {:ok, _} = Agent.start_link(fn -> [] end, name: __MODULE__)
      :ok
    end

    def get(opt) do
      Agent.get(__MODULE__, fn opts -> Keyword.get(opts, opt) end)
    end

    def put(opt, val) do
      Agent.update(__MODULE__, fn opts -> Keyword.put(opts, opt, val) end)
    end
  end

  setup do
    MFA.setup()
  end

  describe "pack" do
    test "unknown option" do
      packed = RemoteIp.Options.pack(unknown: :option)
      refute Keyword.has_key?(packed, :unknown)
      assert Keyword.has_key?(packed, :headers)
      assert Keyword.has_key?(packed, :proxies)
      assert Keyword.has_key?(packed, :clients)
    end

    test ":headers default" do
      packed = RemoteIp.Options.pack([])
      assert "forwarded" in packed[:headers]
      assert "x-forwarded-for" in packed[:headers]
      assert "x-client-ip" in packed[:headers]
      assert "x-real-ip" in packed[:headers]
    end

    test ":headers list" do
      packed = RemoteIp.Options.pack(headers: ~w[a b c])
      assert packed[:headers] == ~w[a b c]
      assert Keyword.has_key?(packed, :proxies)
      assert Keyword.has_key?(packed, :clients)
    end

    test ":headers mfa" do
      packed = RemoteIp.Options.pack(headers: {MFA, :get, [:headers]})
      assert packed[:headers] == {MFA, :get, [:headers]}
      assert Keyword.has_key?(packed, :proxies)
      assert Keyword.has_key?(packed, :clients)
    end

    test ":proxies default" do
      packed = RemoteIp.Options.pack([])
      assert packed[:proxies] == []
      assert Keyword.has_key?(packed, :headers)
      assert Keyword.has_key?(packed, :clients)
    end

    test ":proxies list" do
      packed = RemoteIp.Options.pack(proxies: ~w[123.0.0.0/8])
      assert packed[:proxies] == [{{123, 0, 0, 0}, {123, 255, 255, 255}, 8}]
      assert Keyword.has_key?(packed, :headers)
      assert Keyword.has_key?(packed, :clients)
    end

    test ":proxies mfa" do
      packed = RemoteIp.Options.pack(proxies: {MFA, :get, [:proxies]})
      assert packed[:proxies] == {MFA, :get, [:proxies]}
      assert Keyword.has_key?(packed, :headers)
      assert Keyword.has_key?(packed, :clients)
    end

    test ":clients default" do
      packed = RemoteIp.Options.pack([])
      assert packed[:clients] == []
      assert Keyword.has_key?(packed, :headers)
      assert Keyword.has_key?(packed, :proxies)
    end

    test ":clients list" do
      packed = RemoteIp.Options.pack(clients: ~w[234.0.0.0/8])
      assert packed[:clients] == [{{234, 0, 0, 0}, {234, 255, 255, 255}, 8}]
      assert Keyword.has_key?(packed, :headers)
      assert Keyword.has_key?(packed, :proxies)
    end

    test ":clients mfa" do
      packed = RemoteIp.Options.pack(clients: {MFA, :get, [:clients]})
      assert packed[:clients] == {MFA, :get, [:clients]}
      assert Keyword.has_key?(packed, :headers)
      assert Keyword.has_key?(packed, :proxies)
    end
  end

  describe "unpack" do
    test ":headers default" do
      packed = RemoteIp.Options.pack([])
      unpacked = RemoteIp.Options.unpack(packed)
      assert unpacked[:headers] == packed[:headers]
    end

    test ":headers list" do
      packed = RemoteIp.Options.pack(headers: ~w[a b c])
      unpacked = RemoteIp.Options.unpack(packed)
      assert unpacked[:headers] == packed[:headers]
    end

    test ":headers mfa" do
      packed = RemoteIp.Options.pack(headers: {MFA, :get, [:headers]})

      MFA.put(:headers, ~w[a b c])
      unpacked = RemoteIp.Options.unpack(packed)
      assert unpacked[:headers] == ~w[a b c]

      MFA.put(:headers, ~w[d e f])
      unpacked = RemoteIp.Options.unpack(packed)
      assert unpacked[:headers] == ~w[d e f]
    end

    test ":proxies default" do
      packed = RemoteIp.Options.pack([])
      unpacked = RemoteIp.Options.unpack(packed)
      assert unpacked[:proxies] == packed[:proxies]
    end

    test ":proxies list" do
      packed = RemoteIp.Options.pack(proxies: ~w[123.0.0.0/8 234.0.0.0/8])
      unpacked = RemoteIp.Options.unpack(packed)
      assert unpacked[:proxies] == packed[:proxies]
    end

    test ":proxies mfa" do
      packed = RemoteIp.Options.pack(proxies: {MFA, :get, [:proxies]})

      MFA.put(:proxies, ~w[123.0.0.0/8])
      unpacked = RemoteIp.Options.unpack(packed)
      assert unpacked[:proxies] == [{{123, 0, 0, 0}, {123, 255, 255, 255}, 8}]

      MFA.put(:proxies, ~w[234.0.0.0/8])
      unpacked = RemoteIp.Options.unpack(packed)
      assert unpacked[:proxies] == [{{234, 0, 0, 0}, {234, 255, 255, 255}, 8}]
    end

    test ":clients default" do
      packed = RemoteIp.Options.pack([])
      unpacked = RemoteIp.Options.unpack(packed)
      assert unpacked[:clients] == packed[:clients]
    end

    test ":clients list" do
      packed = RemoteIp.Options.pack(clients: ~w[123.0.0.0/8 234.0.0.0/8])
      unpacked = RemoteIp.Options.unpack(packed)
      assert unpacked[:clients] == packed[:clients]
    end

    test ":clients mfa" do
      packed = RemoteIp.Options.pack(clients: {MFA, :get, [:clients]})

      MFA.put(:clients, ~w[123.0.0.0/8])
      unpacked = RemoteIp.Options.unpack(packed)
      assert unpacked[:clients] == [{{123, 0, 0, 0}, {123, 255, 255, 255}, 8}]

      MFA.put(:clients, ~w[234.0.0.0/8])
      unpacked = RemoteIp.Options.unpack(packed)
      assert unpacked[:clients] == [{{234, 0, 0, 0}, {234, 255, 255, 255}, 8}]
    end
  end
end
