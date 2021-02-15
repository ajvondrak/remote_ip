defmodule RemoteIp.HeadersTest do
  use ExUnit.Case, async: true

  doctest RemoteIp.Headers

  test "taking from an empty list of headers" do
    headers = []
    allowed = ["a", "b", "c"]
    assert RemoteIp.Headers.take(headers, allowed) == []
  end

  test "taking no headers" do
    headers = [{"a", "1"}, {"b", "2"}, {"c", "3"}]
    allowed = []
    assert RemoteIp.Headers.take(headers, allowed) == []
  end

  test "taking all headers" do
    headers = [{"a", "1"}, {"b", "2"}, {"c", "3"}]
    allowed = ["a", "b", "c"]
    assert RemoteIp.Headers.take(headers, allowed) == headers
  end

  test "taking a subset of headers" do
    headers = [{"a", "1"}, {"b", "2"}, {"c", "3"}]
    allowed = ["a", "c"]
    assert RemoteIp.Headers.take(headers, allowed) == [{"a", "1"}, {"c", "3"}]
  end

  test "taking a superset of headers" do
    headers = [{"a", "1"}, {"b", "2"}, {"c", "3"}]
    allowed = ["a", "z"]
    assert RemoteIp.Headers.take(headers, allowed) == [{"a", "1"}]
  end

  test "taking a disjoint set of headers" do
    headers = [{"a", "1"}, {"b", "2"}, {"c", "3"}]
    allowed = ["x", "y", "z"]
    assert RemoteIp.Headers.take(headers, allowed) == []
  end

  test "taking duplicate headers" do
    headers = [{"a", "1"}, {"a", "2"}, {"b", "3"}]
    allowed = ["a"]
    assert RemoteIp.Headers.take(headers, allowed) == [{"a", "1"}, {"a", "2"}]
  end

  test "parsing Forwarded headers" do
    ips = [
      {1, 2, 3, 4},
      {0, 0, 0, 0, 2, 3, 4, 5},
      {3, 4, 5, 6},
      {0, 0, 0, 0, 4, 5, 6, 7}
    ]

    headers = [
      {"forwarded", ~S'for=1.2.3.4'},
      {"forwarded", ~S'for="[::2:3:4:5]";proto=http;host=example.com'},
      {"forwarded", ~S'proto=http;for=3.4.5.6;by=127.0.0.1'},
      {"forwarded", ~S'proto=http;host=example.com;for="[::4:5:6:7]"'}
    ]

    assert RemoteIp.Headers.parse(headers) == ips

    headers = [
      {"forwarded", ~S'for=1.2.3.4, for="[::2:3:4:5]";proto=http;host=example.com'},
      {"forwarded", ~S'proto=http;for=3.4.5.6;by=127.0.0.1'},
      {"forwarded", ~S'proto=http;host=example.com;for="[::4:5:6:7]"'}
    ]

    assert RemoteIp.Headers.parse(headers) == ips

    headers = [
      {"forwarded", ~S'for=1.2.3.4, for="[::2:3:4:5]";proto=http;host=example.com, proto=http;for=3.4.5.6;by=127.0.0.1'},
      {"forwarded", ~S'proto=http;host=example.com;for="[::4:5:6:7]"'}
    ]

    assert RemoteIp.Headers.parse(headers) == ips

    headers = [
      {"forwarded", ~S'for=1.2.3.4'},
      {"forwarded", ~S'for="[::2:3:4:5]";proto=http;host=example.com'},
      {"forwarded", ~S'proto=http;for=3.4.5.6;by=127.0.0.1, proto=http;host=example.com;for="[::4:5:6:7]"'}
    ]

    assert RemoteIp.Headers.parse(headers) == ips

    headers = [
      {"forwarded", ~S'for=1.2.3.4'},
      {"forwarded", ~S'for="[::2:3:4:5]";proto=http;host=example.com, proto=http;for=3.4.5.6;by=127.0.0.1, proto=http;host=example.com;for="[::4:5:6:7]"'}
    ]

    assert RemoteIp.Headers.parse(headers) == ips
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

    assert RemoteIp.Headers.parse(headers) == ips
  end

  test "parsing an unrecognized header falls back to generic parsing" do
    headers = [
      {"x-forwarded-for", "1.1.1.1,2.2.2.2"},
      {"x-real-ip", "3.3.3.3, 4.4.4.4"},
      {"x-client-ip", "5.5.5.5"}
    ]

    ips = [
      {1, 1, 1, 1},
      {2, 2, 2, 2},
      {3, 3, 3, 3},
      {4, 4, 4, 4},
      {5, 5, 5, 5}
    ]

    assert RemoteIp.Headers.parse(headers) == ips
  end

  test "parsing multiple kinds of headers" do
    headers = [
      {"forwarded", "for=1.1.1.1"},
      {"x-forwarded-for", "2.2.2.2"},
      {"forwarded", "for=3.3.3.3, for=4.4.4.4"},
      {"x-forwarded-for", "invalid"},
      {"forwarded", "for=5.5.5.5"},
      {"x-forwarded-for", "6.6.6.6, 7.7.7.7"},
      {"invalid", "header"}
    ]

    ips = [
      {1, 1, 1, 1},
      {2, 2, 2, 2},
      {3, 3, 3, 3},
      {4, 4, 4, 4},
      {5, 5, 5, 5},
      {6, 6, 6, 6},
      {7, 7, 7, 7}
    ]

    assert RemoteIp.Headers.parse(headers) == ips
  end
end
