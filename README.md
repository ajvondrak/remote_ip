# RemoteIp

A [plug](https://github.com/elixir-lang/plug) to overwrite the [`Conn`'s](https://hexdocs.pm/plug/Plug.Conn.html) `remote_ip` based on headers such as `X-Forwarded-For`.

IPs are processed last-to-first to prevent IP spoofing, as thoroughly explained in [a blog post](http://blog.gingerlime.com/2012/rails-ip-spoofing-vulnerabilities-and-protection/) by [@gingerlime](https://github.com/gingerlime). Loopback/private IPs are always ignored and known proxies are configurable, so neither type will be erroneously treated as the original client IP. You can configure any number of arbitrary forwarding headers to use. If there's a special way to parse your particular header, the architecture of this project should [make it easy](#contributing) to open a pull request so `RemoteIp` can accommodate.

**If your app is not behind at least one proxy, you should not use this plug.** See [below](#algorithm) for more detailed reasoning.

## Installation

Add `:remote_ip` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:remote_ip, "~> 0.1.0"}]
end
```

## Usage

Add the `RemoteIp` plug to your app's plug pipeline:

```elixir
defmodule MyApp do
  use Plug.Builder

  plug RemoteIp
end
```

There are 2 options that can be passed in:

* `:headers` - A list of strings naming the `req_headers` to use when deriving the `remote_ip`. Order does not matter. Defaults to `~w[forwarded x-forwarded-for x-client-ip x-real-ip]`.

* `:proxies` - A list of strings in [CIDR](https://en.wikipedia.org/wiki/CIDR) notation specifying the IPs of known proxies. Defaults to `[]`.

For example, if you know you are behind proxies in the IP block 1.2.x.x that use the `X-Foo`, `X-Bar`, and `X-Baz` headers, you could say

```elixir
defmodule MyApp do
  use Plug.Builder

  plug RemoteIp, headers: ~w[x-foo x-bar x-baz], proxies: ~w[1.2.0.0/16]
end
```

Note that, due to limitations in the [inet_cidr](https://github.com/Cobenian/inet_cidr) library used to parse them, `:proxies` **must** be written in full CIDR notation, even if specifying just a single IP. So instead of `"127.0.0.1"` and `"a:b::c:d"`, you would use `"127.0.0.1/32"` and `"a:b::c:d/128"`.

## Background

### Problem: Your app is behind a proxy and you want to know the original client's IP address.

[Proxies](https://en.wikipedia.org/wiki/Proxy_server) are pervasive for some purpose or another in modern HTTP infrastructure: encryption, load balancing, caching, compression, and more can be done via proxies. But a proxy makes HTTP requests appear to your app as if they came from the proxy's IP address. How is your app to know the "actual" requesting IP address (e.g., so you can geolocate a user)?

**Solution:** Many proxies prevent this information loss by adding HTTP headers to communicate the requesting client's IP address. There is no single, universal header. Though [`X-Forwarded-For`](https://en.wikipedia.org/wiki/X-Forwarded-For) is common, options include [`X-Real-IP`](http://nginx.org/en/docs/http/ngx_http_realip_module.html), [`X-Client-IP`](http://httpd.apache.org/docs/trunk/mod/mod_remoteip.html), and [others](http://stackoverflow.com/a/916157). Due to this lack of standardization, [RFC 7239](https://tools.ietf.org/html/rfc7239) defines the `Forwarded` header, fulfilling a [relevant XKCD truism](https://xkcd.com/927).

### Problem: Plug does not derive `remote_ip` from headers such as `X-Forwarded-For`.

Per the [`Plug.Conn` docs](https://hexdocs.pm/plug/Plug.Conn.html#module-request-fields):

> * `remote_ip` - the IP of the client, example: `{151, 236, 219, 228}`. This
>   field is meant to be overwritten by plugs that understand e.g. the
>   `X-Forwarded-For` header or HAProxy's PROXY protocol. It defaults to peer's
>   IP.

Note that the field is _meant_ to be overwritten. Plug does not actually do any overwriting itself. The [Cowboy changelog](https://github.com/ninenines/cowboy/blob/master/CHANGELOG.md#084) espouses a similar platform of non-involvement:

> Because each server's proxy situation differs, it is better that this function is implemented by the application directly.

**Solution:** As definitively verified in [elixir-lang/plug#319](https://github.com/elixir-lang/plug/issues/319), users are intended to hand-roll their own header parsers.

### Problem: Ain't nobody got time for that.

**Solution:** There are a handful of plugs available on [Hex](https://hex.pm). There are also the comments left in the [elixir-lang/plug#319](https://github.com/elixir-lang/plug/issues/319) thread that may give you some ideas, but I consider them to be non-starters - copying/pasting code from github comments isn't much better than hand-rolling an implementation.

### Problem: Existing solutions are incomplete and have subtle bugs.

None of the available solutions I have seen are ideal. In this sort of plug, you want:

* **Configurable Headers:**  With so many different headers being used, you should be able to configure the ones you need with minimal work.
* **Configurable Proxies:** With multiple proxy hops, there may be several IPs in the forwarding headers. Without being able to tell the plug which of those IPs are actually known to be proxies, you may get one of them back as the `remote_ip`.
* **Correctness:** Parsing forwarding headers can be surprisingly subtle. Most available libraries get it wrong.

The table below summarizes the problems with existing packages.

|                                                                      | Headers?                 | Proxies?                 | Correct?                 | Notes                                                                                                                                                                                      |
|----------------------------------------------------------------------|--------------------------|--------------------------|--------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [plug_cloudflare](https://hex.pm/packages/plug_cloudflare)           | :heavy_multiplication_x: | :heavy_multiplication_x: | :heavy_minus_sign:       | Just for `CF-Connecting-IP`, not really a general purpose library                                                                                                                          |
| [plug_forwarded_peer](https://hex.pm/packages/plug_forwarded_peer)   | :heavy_multiplication_x: | :heavy_multiplication_x: | :heavy_multiplication_x: | Only parses `Forwarded` and `X-Forwarded-For`, `X-Forwarded-For` takes precedence over `Forwarded`, does not parse all of RFC 7239's supported syntax correctly, vulnerable to IP spoofing |
| [plug_x_forwarded_for](https://hex.pm/packages/plug_x_forwarded_for) | :heavy_minus_sign:       | :heavy_multiplication_x: | :heavy_multiplication_x: | Can only configure one header, all headers parsed the same as `X-Forwarded-For`, vulnerable to IP spoofing                                                                                 |
| [remote_ip_rewriter](https://hex.pm/packages/remote_ip_rewriter)     | :heavy_multiplication_x: | :heavy_minus_sign:       | :heavy_check_mark:       | Only parses `X-Forwarded-For`, recognizes private/loopback IPs but known proxies are not configurable                                                                                      |

**Solution:** These are the sorts of things application developers should not have to worry about. `RemoteIp` aims to be the proper solution to all of these problems.

## Algorithm

There are 2 main tasks this plug has to do:

1. Parse the right `req_headers`.
2. Compute the right `remote_ip`.

### Parsing Headers

When `RemoteIp` parses the `Conn`'s `req_headers`, it first selects only the headers specified in the [`:headers` option](#usage). Their relative ordering is maintained, because order matters when there are multiple hops between proxies. Consider this request:

* Client at IP 1.2.3.4 sends an HTTP request to Proxy 1 (no forwarding headers)
* Proxy 1 at IP 1.1.1.1 adds a `Forwarded: for=1.2.3.4` header and forwards to Proxy 2
* Proxy 2 at IP 2.2.2.2 adds an `X-Forwarded-For: 1.1.1.1` header and forwards to the application
* The application at IP 3.3.3.3 receives the request from IP 2.2.2.2 with the headers `Forwarded: for=1.2.3.4` & `X-Forwarded-For: 1.1.1.1`

Thus, if `RemoteIp` is configured to accept both `Forwarded` and `X-Forwarded-For` headers (which it is by default), it would process the list

```elixir
[{"forwarded", "for=1.2.3.4"}, {"x-forwarded-for", "1.1.1.1"}] # this is what we get
```

**not** the reverse

```elixir
[{"x-forwarded-for", "1.1.1.1"}, {"forwarded", "for=1.2.3.4"}] # this is NOT what we get
```

After selecting the allowed headers, each string is parsed for its IP addresses (each IP address being the [tuple returned by `:inet` functions](http://erlang.org/doc/man/inet.html#type-ip_address)). Each type of header may be parsed in a different way. For instance, `Forwarded` has a key-value pair format specified by RFC 7239, whereas `X-Forwarded-For` contains a comma-separate list of IPs.

Currently, `Forwarded` is the only header with a format specifically recognized by `RemoteIp`. All other headers are parsed _generically_. That is, they are parsed as comma-separated IPs. This should work for `X-Forwarded-For` and, as far as I can tell, `X-Real-IP` & `X-Client-IP` as well. New formats are [easy to add](#contributing) - pull requests welcome.

### Computing the IP

With the list of IPs parsed, `RemoteIp` must then calculate the proper `remote_ip`. Continuing with the above example, we'd have the list of IPv4 addresses

```elixir
[{1, 2, 3, 4}, {1, 1, 1, 1}]
```

To [prevent IP spoofing](http://blog.gingerlime.com/2012/rails-ip-spoofing-vulnerabilities-and-protection/), IPs are processed right-to-left. You can think of it as working backwards through the chain of hops:

1. The `2.2.2.2 -> 3.3.3.3` hop set `X-Forwarded-For: 1.1.1.1`. Do we trust this header? **Yes**, because `RemoteIp` assumes that there is _at least_ one proxy sitting between your app & the client that sets a forwarding header, meaning that 2.2.2.2 is tacitly a "known" proxy.
2. The `1.1.1.1 -> 2.2.2.2` hop set `Forwarded: for=1.2.3.4`. Do we trust this header? **It depends**, because we would need to configure `RemoteIp` with the [`:proxies` option](#usage) to know that 1.1.1.1 is a proxy. If we didn't, we wouldn't trust the header, and thus should stop here and say the original client was at 1.1.1.1. Otherwise, we should keep working backwards through the hops. Assuming we do...
3. The `1.2.3.4 -> 1.1.1.1` hop set no headers, so we've arrived at the original client address, 1.2.3.4.

Now suppose a client was trying to spoof the IP by setting their own `X-Forwarded-For` header:

* Client at IP 1.2.3.4 sends HTTP request to Proxy 1 with `X-Forwarded-For: 2.3.4.5`
* Proxy 1 at IP 1.1.1.1 adds to the header so it now reads `X-Forwarded-For: 2.3.4.5, 1.2.3.4` and forwards to Proxy 2
* Proxy 2 at IP 2.2.2.2 adds to the header so it now reads `X-Forwarded-For: 2.3.4.5, 1.2.3.4, 1.1.1.1` and forwards to the application
* The application at IP 3.3.3.3 receives the request from IP 2.2.2.2 and `RemoteIp` parses out the IPs `[{2, 3, 4, 5}, {1, 2, 3, 4}, {1, 1, 1, 1}]`

If we configure 1.1.1.1 as a known proxy but _not_ 1.2.3.4, then the right-to-left processing gives us the correct client IP 1.2.3.4 - instead of the attempted spoof, 2.3.4.5.

Not only are known proxies' headers trusted, but also requests forwarded for [loopback](https://en.wikipedia.org/wiki/Loopback) and [private](https://en.wikipedia.org/wiki/Private_network) IPs, namely:

* 127.0.0.0/8
* ::1/128
* fc00::/7
* 10.0.0.0/8
* 172.16.0.0/12
* 192.168.0.0/16

These IPs are filtered because they are used internally and are thus guaranteed not to be the actual client address in production.

### :warning: Caveats :warning:

1. **Only use `RemoteIp` if your app is behind at least one proxy.** Because the last forwarding header is always tacitly trusted, it would be trivial to spoof an IP if your app _wasn't actually_ behind a proxy: just set a forwarding header. Besides, there isn't much to be gained from this library if your app isn't behind a proxy.

2. The relative order of IPs can still be messed up by proxies amending prior headers. For instance,

* Request starts from IP 1.1.1.1 (no forwarding headers)
* Proxy 1 with IP 2.2.2.2 adds `Forwarded: for=1.1.1.1`
* Proxy 2 with IP 3.3.3.3 adds `X-Forwarded-For: 2.2.2.2`
* Proxy 3 with IP 4.4.4.4 adds to `Forwarded` so it says `Forwarded: for=1.1.1.1, for=3.3.3.3`

Thus, `RemoteIp` processes the request from 4.4.4.4 with the first-to-last list of forwarded IPs

```elixir
[{1, 1, 1, 1}, {3, 3, 3, 3}, {2, 2, 2, 2}] # what we get
```

even though the _actual_ order was

```elixir
[{1, 1, 1, 1}, {2, 2, 2, 2}, {3, 3, 3, 3}] # actual forwarding order
```

The solution to this problem is to add both 2.2.2.2 and 3.3.3.3 as known proxies. Then either way the original client address will be reported as 1.1.1.1. As always, be sure to test in your particular environment.

## Contributing

If there's some header that `RemoteIp` does not parse properly, support is easy to add:

1. Fork this project.
2. Add a module under `RemoteIp.Headers.YourNewHeader`.
3. In this new module, export the function `parse/1` that takes in the string value of a single header and returns a list of 0 or more IP addresses parsed from that value. You should use [`:inet.parse_strict_address/1`](http://erlang.org/doc/man/inet.html#parse_strict_address-1) or related functions to do the "dirty work" of parsing the actual IP values. The `parse/1` function is just to find the IPs buried within the string.
4. Add tests for your new `RemoteIp.Headers.YourNewHeader.parse/1` function.
5. Add a clause to the private function `RemoteIp.Headers.parse_ips/1` that calls `RemoteIp.Headers.YourNewHeader.parse`.
6. Open a pull request!

For an example of just such an extension, check out:

* [`RemoteIp.Headers.Forwarded`](https://github.com/ajvondrak/remote_ip/blob/master/lib/remote_ip/headers/forwarded.ex)
* [`RemoteIp.Headers.ForwardedTest`](https://github.com/ajvondrak/remote_ip/blob/master/test/remote_ip/headers/forwarded_test.exs)
* [The corresponding `RemoteIp.Headers.parse_ips/1` clause](https://github.com/ajvondrak/remote_ip/blob/ab2d6fe17ea7361dd998e3d0664142f2b4c8b2ea/lib/remote_ip/headers.ex#L16-L18)

If there's demand, I'm open to `RemoteIp` supporting user-configurable parsers. For now, I think the pull request workflow should be sufficient.

If there's some other bug or enhancement not related to parsing a new header, open an issue or pull request and let me know!

## Prior Art

While `RemoteIp` has morphed into something distinct from the Rails middleware of the same name, the Rails code was definitely where I started. So I'd like to explicitly acknowledge the inspiration: this plug would not have been possible without poring over the existing implementation, discussions, documentation, and commits that went into the Rails code. :heart:

Required reading for anyone who wants to think way too much about forwarding headers:

* [@gingerlime](https://github.com/gingerlime)'s [blog post](http://blog.gingerlime.com/2012/rails-ip-spoofing-vulnerabilities-and-protection/) explaining IP spoofing
* Rails' [`RemoteIp` middleware](https://github.com/rails/rails/blob/v4.1.4/actionpack/lib/action_dispatch/middleware/remote_ip.rb)
* Rails' [tests](https://github.com/rails/rails/blob/92703a9ea5d8b96f30e0b706b801c9185ef14f0e/actionpack/test/dispatch/request_test.rb#L62)
* The extensive discussion on [rails/rails#7980](https://github.com/rails/rails/pull/7980)
