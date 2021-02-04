# Purge integration test

This app customizes the `RemoteIp.Debug` log level, just like the [level](../level) integration test. However, it also adjusts the `Logger` configuration to make sure that the [`:compile_time_purge_matching` option](https://hexdocs.pm/logger/1.11.3/Logger.html#module-application-configuration) still works when remote\_ip gets recompiled.

Specifically, we follow these steps:

1. Configure remote\_ip to log at the `:info` level.
2. Configure logger to purge all messages below the `:error` level at compile-time.
3. Compile remote\_ip.
4. When the tests are running, set the log level to `:info`.
5. Capture logs from `RemoteIp.call/2` & `RemoteIp.from/2`.

If the remote\_ip log messages were purged in step 3, then step 4 should have no effect and step 5 should generate no logs. However, if this purging failed, then logs _will_ be generated in step 5. This could happen if remote\_ip didn't pass literal atoms (like `:info`) into `Logger.log/3`: since the macro can't (or shouldn't) evaluate a non-literal expression at compile time, it'll expand into a run-time level check!

This is an important regression to test because older versions of remote\_ip instructed people to disable debug logs using `:compile_time_purge_matching` (cf. [`4512fe5`](https://github.com/ajvondrak/remote_ip/commit/4512fe53cd2b9c2e03924b12961e48a1ff5b0299)), so we should make an effort to ensure their configurations keep working. Of course, it's still possible they used a `:module`/`:function` matcher that is no longer relevant due to the changing internals of the remote\_ip code. But that's on them for matching against private implementation details. 🙃
