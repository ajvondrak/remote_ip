# Algorithm

There are 2 main things `RemoteIp` has to do:

1. Parse the right `req_headers`.
2. Compute the right `remote_ip`.

## Parsing Headers

When `RemoteIp` parses the `Conn`'s `req_headers`, it first selects only the headers specified in the [`:headers` option](#configuration). Their relative ordering is maintained, because order matters when there are multiple hops between proxies. Consider this request:

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

## Computing the IP

With the list of IPs parsed, `RemoteIp` must then calculate the proper `remote_ip`. Continuing with the above example, we'd have the list of IPv4 addresses

```elixir
[{1, 2, 3, 4}, {1, 1, 1, 1}]
```

To [prevent IP spoofing](http://blog.gingerlime.com/2012/rails-ip-spoofing-vulnerabilities-and-protection/), IPs are processed right-to-left. You can think of it as working backwards through the chain of hops:

1. The `2.2.2.2 -> 3.3.3.3` hop set `X-Forwarded-For: 1.1.1.1`. Do we trust this header? **Yes**, because `RemoteIp` assumes that there is _at least_ one proxy sitting between your app & the client that sets a forwarding header, meaning that 2.2.2.2 is tacitly a "known" proxy.
2. The `1.1.1.1 -> 2.2.2.2` hop set `Forwarded: for=1.2.3.4`. Do we trust this header? **It depends**, because we would need to configure `RemoteIp` with the [`:proxies` option](#configuration) to know that 1.1.1.1 is a proxy. If we didn't, we wouldn't trust the header, and thus should stop here and say the original client was at 1.1.1.1. Otherwise, we should keep working backwards through the hops. Assuming we do...
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

These IPs are filtered because they are used internally and are thus generally not the actual client address in production.

However, if (say) your app is only deployed in a [VPN](https://en.wikipedia.org/wiki/Virtual_private_network)/[LAN](https://en.wikipedia.org/wiki/Local_area_network), then your clients might actually have these internal IPs. To prevent loopback/private addresses from being considered proxies, configure them as known clients using the [`:clients` option](#configuration).

## :warning: Caveats :warning:

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

    A potential solution to this problem is to add both 2.2.2.2 and 3.3.3.3 as known proxies. Then either way the original client address will be reported as 1.1.1.1. As always, be sure to test in your particular environment.
