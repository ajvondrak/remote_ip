# Algorithm

To avoid IP spoofing vulnerabilities, `RemoteIp` employs a very particular algorithm. Its work is divided into two main phases:

1. Parse the right `req_headers`.
2. Compute the right `remote_ip`.

We will analyze these steps in detail to understand the benefits and caveats of the algorithm. Much of it relies on configuration values given by `RemoteIp.Options`. You may also log the steps of this algorithm using the `RemoteIp.Debugger`.

As a running example, consider the following request route:

* Client at IP `1.2.3.4` sends an HTTP request to Proxy 1 (no forwarding headers)
* Proxy 1 at IP `1.1.1.1` adds an `X-Forwarded-For: 1.2.3.4` header and forwards to Proxy 2
* Proxy 2 at IP `2.2.2.2` adds Proxy 1 to the header with `X-Forwarded-For: 1.2.3.4, 1.1.1.1` and forwards to Proxy 3
* Proxy 3 at IP `3.3.3.3` adds a `Forwarded: for=2.2.2.2` header and forwards to the application
* Application receives the request from IP `3.3.3.3` with forwarding headers `X-Forwarded-For: 1.2.3.4, 1.1.1.1` and `Forwarded: for=2.2.2.2`

## Parsing headers

There are many different forwarding headers in the wild, including `Forwarded`, `X-Forwarded-For`, `X-Client-Ip`, and `X-Real-Ip`. The header that gets used depends on the configuration of the proxy your app sits behind. If there are multiple proxies in play, it's conceivable for you to have more than one such header.

The `:headers` option tells `RemoteIp` which specific headers to parse for IP addresses. The default value casts a wide net, but you should ideally specify only those headers which you're certain you require. Otherwise, it would be trivial for a malicious client to add an extra header that could interfere with finding the correct IP.

To start off the algorithm, all of the configured headers are taken from the `Plug.Conn`'s `req_headers`. Their relative ordering is maintained, because order matters when there are multiple hops between proxies. In our running example, assuming both `Forwarded` and `X-Forwarded-For` were in the `:headers` option (which they are by default), we want to process the list

```elixir
# This is what we want
[{"x-forwarded-for", "1.2.3.4, 1.1.1.1"}, {"forwarded", "for=2.2.2.2"}]
```

and *not* the reverse

```elixir
# This is NOT what we want
[{"forwarded", "for=2.2.2.2"}, {"x-forwarded-for", "1.2.3.4, 1.1.1.1"}]
```

Let's assume we get the former. In reality, however, we usually can't rely on the stable ordering of headers in an HTTP request. For example, the [Cowboy](https://github.com/ninenines/cowboy/) server presently [uses maps](https://github.com/elixir-plug/plug_cowboy/blob/f82f2ff982f04fb4faa3a12fd2b08a7cc56ebe15/lib/plug/cowboy/conn.ex#L125-L127) to represent headers, which don't preserve key order, so everything could get jumbled up.

Configuring multiple headers might still be useful if, for example, you expect some requests to only have header A and other requests to only have header B, but never both at the same time. So `RemoteIp` doesn't limit you to just the one choice.

After selecting the allowed headers, each string is parsed for its IP addresses. In the common case, we parse comma-separated IPs with `RemoteIp.Parsers.Generic`. This works for headers like `X-Forwarded-For`, `X-Client-Ip` and `X-Real-Ip`. But you can also configure custom parsers using the `:parsers` option. For instance, by default we include `RemoteIp.Parsers.Forwarded` to parse the format specified by RFC 7239.

Each parser returns a list of IPs, each of the [`:inet.ip_address/0` type](http://erlang.org/doc/man/inet.html#type-ip_address). If there were any errors (e.g., a malformed header), this should be an empty list. But any one header may also specify multiple IPs, so once again it's important that the relative order is maintained. Thus, in our running example, the `X-Forwarded-For` header should parse as

```elixir
# This is what we want
[{1, 2, 3, 4}, {1, 1, 1, 1}]
```

and *not* another order like

```elixir
# This is NOT what we want
[{1, 1, 1, 1}, {1, 2, 3, 4}]
```

The lists returned by each parser are then concatenated together to form one chain of IPs. In our running example, the resulting addresses are

```elixir
[{1, 2, 3, 4}, {1, 1, 1, 1}, {2, 2, 2, 2}]
```

## Finding the client

With the list of IPs parsed, `RemoteIp` must then calculate the proper `remote_ip`. To [prevent IP spoofing](http://blog.gingerlime.com/2012/rails-ip-spoofing-vulnerabilities-and-protection/), IPs are processed right-to-left. You can think of it as going backwards through the chain of hops:

1. Application is receiving a request from Proxy 3
2. The Proxy 3 to Application hop set the header `Forwarded: for=2.2.2.2`
3. The Proxy 2 to Proxy 3 hop added `1.1.1.1` to the `X-Forwarded-For` header
4. The Proxy 1 to Proxy 2 hop set the `X-Forwarded-For: 1.2.3.4` header
5. Client is sending a request to Proxy 1

We work backwards until we find something that looks like a client IP. This is dictated by the `:proxies` option, which configures the list of known proxy IPs. Any IP that is *not* a known proxy is assumed to be a client. In our running example:

1. The peer address `{3, 3, 3, 3}` is automatically assumed to be a proxy IP, so go through the headers
2. `{2, 2, 2, 2}` is a known proxy IP, so go one hop back
3. `{1, 1, 1, 1}` is a known proxy IP, so go one hop back
4. `{1, 2, 3, 4}` is not a known proxy IP, so we assume it's the client

Notice that the peer address is *always* assumed to be "wrong". Therefore, you should not use `RemoteIp` unless your app is behind at least one proxy. Otherwise, it would be trivial for a malicious client to spoof their IP address: if they just set a header themselves, we'll automatically use it to rewrite the `Plug.Conn`'s original (correct) peer address.

It's also important to go *backwards* through the chain, or else the client could similarly spoof their IP. For instance, consider if the client in the running example had initially sent the header `Forwarded: for=6.7.8.9`. Then the headers would have come in as

```elixir
[{"forwarded", "for=6.7.8.9"}, {"x-forwarded-for", "1.2.3.4, 1.1.1.1"}, {"forwarded", "for=2.2.2.2"}]
```

which would parse out as the IPs

```elixir
[{6, 7, 8, 9}, {1, 2, 3, 4}, {1, 1, 1, 1}, {2, 2, 2, 2}]
```

If we were to go *forwards* through this list, we'd immediately return `{6, 7, 8, 9}` as the client IP, even though it was being spoofed by our malicious user. Instead, going backwards still gives us `{1, 2, 3, 4}` even though the client is attempting to spoof the IP with their own headers. This works no matter how many extra headers the client sends.

This logic generalizes to any bad actors in the middle of the chain, too. If we add an IP to the `:proxies` list, we're trusting the forwarding headers that it sets. As such, we're implicitly trusting the incoming peer address, even without configuring it. So in our running example, it's impossible not to trust Proxy 3. We believe it when it says the request came from Proxy 2. But if we didn't trust Proxy 2, that's where we stop: we say the client is `{2, 2, 2, 2}` and won't dig further because we don't trust the `X-Forwarded-For` header that came from Proxy 2.

Not only are known proxies' headers trusted, but also requests forwarded for [loopback](https://en.wikipedia.org/wiki/Loopback) and [private](https://en.wikipedia.org/wiki/Private_network) IPs:

* IPv4 loopback - `127.0.0.0/8`
* IPv6 loopback - `::1/128`
* IPv4 private network - `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`
* IPv6 unique local address - `fc00::/7`

These IPs are skipped automatically because they are used internally and are thus generally not the actual client address in production. However, if (say) your app is only deployed in a [VPN](https://en.wikipedia.org/wiki/Virtual_private_network)/[LAN](https://en.wikipedia.org/wiki/Local_area_network), then your clients might actually have these internal IPs. To prevent loopback/private addresses from being considered proxies, configure them as known clients using the `:clients` option. This goes for anything you have listed in `:proxies` as well. For example, you might say that a whole CIDR block belongs to proxies, but then carve out an exception for a single client in that block.
