# RemoteIp

[![build status](https://github.com/ajvondrak/remote_ip/workflows/build/badge.svg)](https://github.com/ajvondrak/remote_ip/actions?query=workflow%3Abuild)
[![coverage status](https://coveralls.io/repos/github/ajvondrak/remote_ip/badge.svg?branch=main)](https://coveralls.io/github/ajvondrak/remote_ip?branch=main)
[![hex.pm version](https://img.shields.io/hexpm/v/remote_ip)](https://hex.pm/packages/remote_ip)

A [plug](https://github.com/elixir-lang/plug) to overwrite the [`Conn`'s](https://hexdocs.pm/plug/Plug.Conn.html) `remote_ip` based on forwarding headers.

Generic comma-separated headers like `X-Forwarded-For`, `X-Real-Ip`, and `X-Client-Ip` are all recognized, as well as the [RFC 7239](https://tools.ietf.org/html/rfc7239) `Forwarded` header. You can specify any number of forwarding headers to recognize and even configure your own parsers.

IPs are processed last-to-first to prevent IP spoofing. Loopback/private IPs are ignored by default, but known proxies & clients are configurable, so you have full control over which IPs are considered legitimate.

**If your app is not behind at least one proxy, you should not use this plug.** See [the algorithm](extras/algorithm.md) for more details.

## Installation

Add `:remote_ip` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:remote_ip, "~> 0.2.0"}]
end
```

## Usage

Add the `RemoteIp` plug to your app's plug pipeline:

```elixir
defmodule MyApp do
  use Plug.Router

  plug RemoteIp

  plug :match
  plug :dispatch

  # get "/" do ...
end
```

You can also use `RemoteIp.from/2` outside of a plug pipeline to extract the remote IP from a list of headers:

```elixir
x_headers = [{"x-forwarded-for", "1.2.3.4"}]
RemoteIp.from(x_headers)
```

See the [documentation](https://hexdocs.pm/remote_ip) for full details on usage, configuration options, and troubleshooting.

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
* **Configurable Proxies and Clients:** With multiple proxy hops, there may be several IPs in the forwarding headers. Without being able to tell the plug which of those IPs are actually known to be proxies, you may get one of them back as the `remote_ip`.
* **Correctness:** Parsing forwarding headers can be surprisingly subtle. Most available libraries get it wrong.

The table below summarizes the problems with existing packages.

|                                                                      | Headers?                 | Proxies?                 | Correct?                 | Notes                                                                                                                                                                                      |
|----------------------------------------------------------------------|--------------------------|--------------------------|--------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [plug_cloudflare](https://hex.pm/packages/plug_cloudflare)           | :heavy_multiplication_x: | :heavy_multiplication_x: | :heavy_minus_sign:       | Just for `CF-Connecting-IP`, not really a general purpose library                                                                                                                          |
| [plug_forwarded_peer](https://hex.pm/packages/plug_forwarded_peer)   | :heavy_multiplication_x: | :heavy_multiplication_x: | :heavy_multiplication_x: | Only parses `Forwarded` and `X-Forwarded-For`, `X-Forwarded-For` takes precedence over `Forwarded`, does not parse all of RFC 7239's supported syntax correctly, vulnerable to IP spoofing |
| [plug_x_forwarded_for](https://hex.pm/packages/plug_x_forwarded_for) | :heavy_minus_sign:       | :heavy_multiplication_x: | :heavy_multiplication_x: | Can only configure one header, all headers parsed the same as `X-Forwarded-For`, vulnerable to IP spoofing                                                                                 |
| [remote_ip_rewriter](https://hex.pm/packages/remote_ip_rewriter)     | :heavy_multiplication_x: | :heavy_minus_sign:       | :heavy_check_mark:       | Only parses `X-Forwarded-For`, recognizes private/loopback IPs but known proxies are not configurable                                                                                      |

**Solution:** These are the sorts of things application developers should not have to worry about. `RemoteIp` aims to be the proper solution to all of these problems.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for instructions on how to open issues or pull requests.

## Prior Art

While `RemoteIp` has morphed into something distinct from the Rails middleware of the same name, the Rails code was definitely where I started. So I'd like to explicitly acknowledge the inspiration: this plug would not have been possible without poring over the existing implementation, discussions, documentation, and commits that went into the Rails code. :heart:

Required reading for anyone who wants to think way too much about forwarding headers:

* [@gingerlime](https://github.com/gingerlime)'s [blog post](http://blog.gingerlime.com/2012/rails-ip-spoofing-vulnerabilities-and-protection/) explaining IP spoofing
* Rails' [`RemoteIp` middleware](https://github.com/rails/rails/blob/v4.1.4/actionpack/lib/action_dispatch/middleware/remote_ip.rb)
* Rails' [tests](https://github.com/rails/rails/blob/92703a9ea5d8b96f30e0b706b801c9185ef14f0e/actionpack/test/dispatch/request_test.rb#L62)
* The extensive discussion on [rails/rails#7980](https://github.com/rails/rails/pull/7980)
