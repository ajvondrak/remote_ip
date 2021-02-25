# Purge integration test

This app enables remote\_ip debugging, just like the [debug](../debug) integration test. However, it also adjusts the `Logger` configuration to make sure that the [`:compile_time_purge_matching` option](https://hexdocs.pm/logger/1.11.3/Logger.html#module-application-configuration) still works when remote\_ip gets recompiled.

Specifically, we purge messages with a level lower than `:info`, which includes the `:debug` messages that `RemoteIp.Debugger` generates. This means that when we compile remote\_ip, none of the debug statements should survive. Even when we set the log level to `:debug` at runtime in the tests, the logs should have been purged at compile-time.

This is an important regression to test because older versions of remote\_ip instructed people to disable debug logs using `:compile_time_purge_matching` (cf. [`4512fe5`](https://github.com/ajvondrak/remote_ip/commit/4512fe53cd2b9c2e03924b12961e48a1ff5b0299)), so we should make an effort to ensure their configurations keep working. Of course, it's still possible they used a `:module`/`:function` matcher that is no longer relevant due to the changing internals of the remote\_ip code. But that's on them for matching against private implementation details. 🙃
