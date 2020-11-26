defmodule RemoteIp.HeadersTest do
  use ExUnit.Case, async: true
  alias RemoteIp.Headers

  @abc_headers [
    {"a", "1.1.1.1"},
    {"x", "0.0.0.0"},
    {"b", "2.2.2.2"},
    {"y", "0.0.0.0"},
    {"c", "3.3.3.3"},
    {"z", "0.0.0.0"}
  ]

  @abc_allowed MapSet.new(~w[a b c])

  test "parsing an empty list of headers" do
    assert Headers.parse([], @abc_allowed) == []
  end

  test "parsing with no allowed headers" do
    assert Headers.parse(@abc_headers, MapSet.new()) == []
  end

  test "only allowed headers get parsed" do
    assert Headers.parse(@abc_headers, @abc_allowed) == [{1, 1, 1, 1}, {2, 2, 2, 2}, {3, 3, 3, 3}]
  end

  test "parsing Forwarded headers" do
    ips = [{1, 2, 3, 4}, {0, 0, 0, 0, 2, 3, 4, 5}, {3, 4, 5, 6}, {0, 0, 0, 0, 4, 5, 6, 7}]

    assert ips ==
             Headers.parse(
               [
                 {"forwarded", ~S'for=1.2.3.4'},
                 {"forwarded", ~S'for="[::2:3:4:5]";proto=http;host=example.com'},
                 {"forwarded", ~S'proto=http;for=3.4.5.6;by=127.0.0.1'},
                 {"forwarded", ~S'proto=http;host=example.com;for="[::4:5:6:7]"'}
               ],
               MapSet.new(~w[forwarded])
             )

    assert ips ==
             Headers.parse(
               [
                 {"forwarded", ~S'for=1.2.3.4, for="[::2:3:4:5]";proto=http;host=example.com'},
                 {"forwarded", ~S'proto=http;for=3.4.5.6;by=127.0.0.1'},
                 {"forwarded", ~S'proto=http;host=example.com;for="[::4:5:6:7]"'}
               ],
               MapSet.new(~w[forwarded])
             )

    assert ips ==
             Headers.parse(
               [
                 {"forwarded",
                  ~S'for=1.2.3.4, for="[::2:3:4:5]";proto=http;host=example.com, proto=http;for=3.4.5.6;by=127.0.0.1'},
                 {"forwarded", ~S'proto=http;host=example.com;for="[::4:5:6:7]"'}
               ],
               MapSet.new(~w[forwarded])
             )

    assert ips ==
             Headers.parse(
               [
                 {"forwarded", ~S'for=1.2.3.4'},
                 {"forwarded", ~S'for="[::2:3:4:5]";proto=http;host=example.com'},
                 {"forwarded",
                  ~S'proto=http;for=3.4.5.6;by=127.0.0.1, proto=http;host=example.com;for="[::4:5:6:7]"'}
               ],
               MapSet.new(~w[forwarded])
             )

    assert ips ==
             Headers.parse(
               [
                 {"forwarded", ~S'for=1.2.3.4'},
                 {"forwarded",
                  ~S'for="[::2:3:4:5]";proto=http;host=example.com, proto=http;for=3.4.5.6;by=127.0.0.1, proto=http;host=example.com;for="[::4:5:6:7]"'}
               ],
               MapSet.new(~w[forwarded])
             )
  end

  test "parsing generic headers" do
    headers = [
      {"generic", "1.1.1.1, unknown, 2.2.2.2"},
      {"generic", "   3.3.3.3 ,  4.4.4.4,not_an_ip"},
      {"generic", "5.5.5.5,::6:6:6:6"},
      {"generic", "unknown,5,7.7.7.7"}
    ]

    ips = [
      {1, 1, 1, 1},
      {2, 2, 2, 2},
      {3, 3, 3, 3},
      {4, 4, 4, 4},
      {5, 5, 5, 5},
      {0, 0, 0, 0, 6, 6, 6, 6},
      {7, 7, 7, 7}
    ]

    assert Headers.parse(headers, MapSet.new(~w[generic])) == ips
  end

  test "parsing an unrecognized header falls back to generic parsing" do
    headers = [
      {"x-forwarded-for", "1.1.1.1,2.2.2.2"},
      {"x-real-ip", "3.3.3.3, 4.4.4.4"},
      {"x-client-ip", "5.5.5.5"}
    ]

    allowed = MapSet.new(~w[x-forwarded-for x-real-ip x-client-ip])

    ips = [
      {1, 1, 1, 1},
      {2, 2, 2, 2},
      {3, 3, 3, 3},
      {4, 4, 4, 4},
      {5, 5, 5, 5}
    ]

    assert Headers.parse(headers, allowed) == ips
  end

  test "parsing multiple kinds of headers" do
    headers = [
      {"forwarded", "for=1.1.1.1"},
      {"x-forwarded-for", "2.2.2.2"},
      {"forwarded", "for=3.3.3.3, for=4.4.4.4"},
      {"not-allowed", "0.0.0.0"},
      {"forwarded", "for=5.5.5.5"},
      {"x-forwarded-for", "6.6.6.6"},
      {"x-forwarded-for", "7.7.7.7"},
      {"not-allowed", "10.10.10.10"}
    ]

    allowed = MapSet.new(~w[forwarded x-forwarded-for])

    ips = [
      {1, 1, 1, 1},
      {2, 2, 2, 2},
      {3, 3, 3, 3},
      {4, 4, 4, 4},
      {5, 5, 5, 5},
      {6, 6, 6, 6},
      {7, 7, 7, 7}
    ]

    assert Headers.parse(headers, allowed) == ips
  end
end
