# Contributing

**Table Of Contents**
* [Issues](#issues)
  * [Getting the wrong IP](#getting-the-wrong-ip)
  * [Other issues](#other-issues)
* [Pull Requests](#pull-requests)
  * [Adding a new header](#adding-a-new-header)
  * [Other enhancements](#other-enhancements)
  * [General guidelines](#general-guidelines)

## Issues

### Getting the wrong IP

There are many reasons you might not be getting the `remote_ip` value you expect. Before opening an issue, [enable debug-level logging](https://hexdocs.pm/logger/Logger.html#module-configuration) and reproduce your problematic request. You should see logs that look something like this:

```
[debug] RemoteIp is configured with %RemoteIp.Config{
  clients: [],
  headers: #MapSet<["forwarded", "x-client-ip", "x-forwarded-for", "x-real-ip"]>,
  proxies: [
    {{127, 0, 0, 0}, {127, 255, 255, 255}, 8},
    {{0, 0, 0, 0, 0, 0, 0, 1}, {0, 0, 0, 0, 0, 0, 0, 1}, 128},
    {{64512, 0, 0, 0, 0, 0, 0, 0},
     {65023, 65535, 65535, 65535, 65535, 65535, 65535, 65535}, 7},
    {{10, 0, 0, 0}, {10, 255, 255, 255}, 8},
    {{172, 16, 0, 0}, {172, 31, 255, 255}, 12},
    {{192, 168, 0, 0}, {192, 168, 255, 255}, 16}
  ]
}
[debug] RemoteIp.Headers is parsing IPs from the request headers [
  {"accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"},
  {"accept-encoding", "gzip, deflate"},
  {"accept-language", "en-US,en;q=0.5"},
  {"connection", "keep-alive"},
  {"dnt", "1"},
  {"host", "localhost:4000"},
  {"upgrade-insecure-requests", "1"},
  {"user-agent",
   "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.14; rv:69.0) Gecko/20100101 Firefox/69.0"},
  {"x-forwarded-for", "1.2.3.4, 2.3.4.5, 192.168.0.1, 127.0.0.1"}
]
[debug] RemoteIp.Headers is only considering the request headers [{"x-forwarded-for", "1.2.3.4, 2.3.4.5, 192.168.0.1, 127.0.0.1"}]
[debug] RemoteIp.Headers parsed the request headers into the IPs [{1, 2, 3, 4}, {2, 3, 4, 5}, {192, 168, 0, 1}, {127, 0, 0, 1}]
[debug] RemoteIp thinks {127, 0, 0, 1} is a known proxy IP
[debug] RemoteIp thinks {192, 168, 0, 1} is a known proxy IP
[debug] RemoteIp assumes {2, 3, 4, 5} is a client IP
[debug] RemoteIp determined the remote IP is {2, 3, 4, 5}
```

This can help you narrow down the issue:

* Do you see these logs at all? If not, `RemoteIp` might not even be called by your pipeline. Try debugging your code.
* Are you getting the request headers you expect? Your particular proxies might not be sending the forwarding headers they should be.
* Did you configure `:headers` right? `RemoteIp` only pays attention to the forwarding headers you specify.
* Did you configure `:proxies` right? If you don't configure an IP as a known proxy, `RemoteIp` assumes it's a legitimate client.
* Did you configure `:clients` right? Loopback or private IPs are automatically identified as proxies. If you need to carve out exceptions, you should add the relevant IP ranges to the list of known clients.
* Are all the IPs being parsed correctly? `RemoteIp` will ignore values that it cannot parse. Either this is a bug in `RemoteIp` or a bad header.
* Are the forwarding headers in the right order? IPs are processed last-to-first to prevent spoofing. Make sure you understand the [algorithm](README.md#algorithm).
* Are there multiple "competing" forwarding headers? The order we see the `req_headers` in the `Plug.Conn` matters for the last-to-first processing. Unfortunately, servers like [cowboy](https://github.com/ninenines/cowboy) can distort the order of incoming headers, since [Erlang maps](http://erlang.org/doc/man/maps.html) do not [preserve ordering](https://medium.com/@jlouis666/breaking-erlang-maps-1-31952b8729e6) (cf. [[1]](https://github.com/elixir-plug/plug_cowboy/blob/7bf68cd757c1a052e227112b681b77066fd84d2b/lib/plug/cowboy/conn.ex#L125-L127), [[2]](https://github.com/erlang/otp/blob/2c882ec2d504019f07104b3240a989148dfc1fa3/lib/stdlib/doc/src/maps.xml#L409)). For example, notice how the header lines appear in one order from `curl`, but a different order in the Elixir logs:

    ```console
    $ curl -v -H'X-Forwarded-For: 1.2.3.4' -H'Forwarded: for=2.3.4.5' localhost:4000
    * Rebuilt URL to: localhost:4000/
    *   Trying ::1...
    * TCP_NODELAY set
    * Connection failed
    * connect to ::1 port 4000 failed: Connection refused
    *   Trying 127.0.0.1...
    * TCP_NODELAY set
    * Connected to localhost (127.0.0.1) port 4000 (#0)
    > GET / HTTP/1.1
    > Host: localhost:4000
    > User-Agent: curl/7.54.0
    > Accept: */*
    > X-Forwarded-For: 1.2.3.4
    > Forwarded: for=2.3.4.5
    [...]
    ```

    ```
    [debug] RemoteIp is configured with %RemoteIp.Config{
      clients: [],
      headers: #MapSet<["forwarded", "x-client-ip", "x-forwarded-for", "x-real-ip"]>,
      proxies: [
        {{127, 0, 0, 0}, {127, 255, 255, 255}, 8},
        {{0, 0, 0, 0, 0, 0, 0, 1}, {0, 0, 0, 0, 0, 0, 0, 1}, 128},
        {{64512, 0, 0, 0, 0, 0, 0, 0},
         {65023, 65535, 65535, 65535, 65535, 65535, 65535, 65535}, 7},
        {{10, 0, 0, 0}, {10, 255, 255, 255}, 8},
        {{172, 16, 0, 0}, {172, 31, 255, 255}, 12},
        {{192, 168, 0, 0}, {192, 168, 255, 255}, 16}
      ]
    }
    [debug] RemoteIp.Headers is parsing IPs from the request headers [
      {"accept", "*/*"},
      {"forwarded", "for=2.3.4.5"},
      {"host", "localhost:4000"},
      {"user-agent", "curl/7.54.0"},
      {"x-forwarded-for", "1.2.3.4"}
    ]
    [debug] RemoteIp.Headers is only considering the request headers [{"forwarded", "for=2.3.4.5"}, {"x-forwarded-for", "1.2.3.4"}]
    [debug] RemoteIp.Headers parsed the request headers into the IPs [{2, 3, 4, 5}, {1, 2, 3, 4}]
    [debug] RemoteIp assumes {1, 2, 3, 4} is a client IP
    [debug] RemoteIp determined the remote IP is {1, 2, 3, 4}
    ```

    You *might* be able to [configure `RemoteIp`](README.md#configuration) to avoid your particular problematic situation.

If none of the above apply, you may have found a bug in `RemoteIp`, so please go ahead and open an issue.

### Other issues

All manner of issues are welcome. However, I don't often have much time to work on open source things, so my turnaround is usually pretty slow. You can help by giving as much context as possible:

* :bug: Bugs
  * How can it be reproduced?
  * Do the logs help?
  * What was the expected behavior?
  * What was the actual behavior?
* :sparkles: Feature requests
  * What problem would it solve?
  * How would it work?
  * Why does it belong in this library?
* :question: Questions
  * Before asking why you're getting the wrong IP, do your [due diligence](#getting-the-wrong-ip).
  * The more details you can provide, the better!

## Pull Requests

### Adding a new header

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

### Other enhancements

If there's some other bug or feature not related to parsing a new header, open pull request through the usual means:

1. Fork this project.
2. Commit your changes.
3. Open a pull request.

### General guidelines

A few notes about getting your pull request accepted:

* [Write good commit messages.](https://chris.beams.io/posts/git-commit/)
> **The seven rules of a great Git commit message**
>
> > Keep in mind: [This](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html) [has](https://www.git-scm.com/book/en/v2/Distributed-Git-Contributing-to-a-Project#_commit_guidelines) [all](https://github.com/torvalds/subsurface-for-dirk/blob/master/README#L92-L120) [been](http://who-t.blogspot.co.at/2009/12/on-commit-messages.html) [said](https://github.com/erlang/otp/wiki/writing-good-commit-messages) [before](https://github.com/spring-projects/spring-framework/blob/30bce7/CONTRIBUTING.md#format-commit-messages).
>
> 1. Separate subject from body with a blank line
> 2. Limit the subject line to 50 characters
> 3. Capitalize the subject line
> 4. Do not end the subject line with a period
> 5. Use the imperative mood in the subject line
> 6. Wrap the body at 72 characters
> 7. Use the body to explain *what* and *why* vs. *how*
* Keep the scope of your PR tight.
  * **Do** make sure your PR accomplishes one specific thing.
  * **Don't** make unnecessary or unrelated changes.
* Keep your history clean.
  * **Do** make sure each commit pertains conceptually to a single change.
  * **Dont'** leave your commits disorganized with various works-in-progress. [Rewrite](https://git-scm.com/book/id/v2/Git-Tools-Rewriting-History) [history](https://git-rebase.io/) [if](https://programmerfriend.com/git-best-practices/) [necessary](http://justinhileman.info/article/changing-history/).
* Write a good PR description.
  * What problem are you trying to solve?
  * Who does the problem affect?
  * When did this problem happen? Is it tied to a specific version?
  * Where is the source of the issue? Is it an external project? Can you link to a relevant discussion?
  * How did you solve it?
  * Why is this the proper solution?
* Write tests, if appropriate.
* Proper documentation is appreciated.
