# Parsers integration test

This app recognizes a custom header named `"forwarding"` which is parsed with the app's own custom implementation of the `RemoteIp.Parser` behaviour.

The header is completely made up. Its format is

```
type=ip
```

where

* `type` is either `proxy` or `client`
* `ip` is a valid IP address

Of course, you wouldn't expect to rely on the header _telling_ you if an IP was a proxy. Bad actors could easily spoof the header (at least if it's plaintext like this). In the real world, you'd configure the `RemoteIp` plug. But this format makes for more interesting tests.

This is an integration test so that we can compile remote\_ip with debugging enabled, then make sure that the custom `:parsers` option gets logged.
