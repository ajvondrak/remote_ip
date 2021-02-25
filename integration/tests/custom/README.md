# Custom integration test

This app customizes the subset of debug messages it wants remote\_ip to actually log. All the others should be removed at compile time. We test this by directly calling `RemoteIp.call/2` & `RemoteIp.from/2` to inspect their log output.

This doesn't enumerate all the possible customizations or anything, but it does provide a smoke test. Here, we log the parsed IPs and the resulting remote IP.

```elixir
config :remote_ip, debug: [:ips, :ip]
```
