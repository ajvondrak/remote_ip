# Debug integration test

This app compiles remote\_ip with the configuration

```elixir
config :remote_ip, debug: true
```

and calls `RemoteIp.call/2` & `RemoteIp.from/2` directly to inspect their debug logs on some basic examples. This gives us coverage on all the possible types of debug messages across the remote\_ip codebase.
