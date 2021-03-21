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

There are many reasons you might not be getting the `remote_ip` value you expect. Before opening an issue, enable `RemoteIp.Debugger` and reproduce your problematic request.

```elixir
config :remote_ip, debug: true
```

```console
$ mix deps.compile --force remote_ip
```

Then you should see logs like these:

```
[debug] Processing remote IP
  headers: ["x-forwarded-for"]
  parsers: %{"forwarded" => RemoteIp.Parsers.Forwarded}
  proxies: ["1.2.0.0/16", "2.3.4.5/32"]
  clients: ["1.2.3.4/32"]
[debug] Taking forwarding headers from [{"accept", "*/*"}, {"x-forwarded-for", "1.2.3.4, 10.0.0.1, 2.3.4.5"}]
[debug] Parsing IPs from forwarding headers: [{"x-forwarded-for", "1.2.3.4, 10.0.0.1, 2.3.4.5"}]
[debug] Parsed IPs from forwarding headers: [{1, 2, 3, 4}, {10, 0, 0, 1}, {2, 3, 4, 5}]
[debug] {2, 3, 4, 5} is a known proxy IP
[debug] {10, 0, 0, 1} is a reserved IP
[debug] {1, 2, 3, 4} is a known client IP
[debug] Processed remote IP, found client {1, 2, 3, 4} to replace {127, 0, 0, 1}
```

This can help you narrow down the issue:

* Do you see these logs at all? If not, `RemoteIp` might not even be called by your pipeline. Try debugging your code.
* Are you getting the request headers you expect? Your particular proxies might not be sending the forwarding headers they should be.
* Did you configure `:headers` right? `RemoteIp` only pays attention to the forwarding headers you specify.
* Did you configure `:proxies` right? If you don't configure an IP as a known proxy, `RemoteIp` assumes it's a legitimate client.
* Did you configure `:clients` right? Loopback or private IPs are automatically identified as proxies. If you need to carve out exceptions, you should add the relevant IP ranges to the list of known clients.
* Are all the IPs being parsed correctly? `RemoteIp` will ignore values that it cannot parse. Either this is a bug in `RemoteIp` or a bad header.
* Are the forwarding headers in the right order? IPs are processed last-to-first to prevent spoofing. Make sure you understand [the algorithm](extras/algorithm.md).
* Are there multiple "competing" forwarding headers? The order we see the `req_headers` in the `Plug.Conn` matters for the last-to-first processing. Unfortunately, servers like [cowboy](https://github.com/ninenines/cowboy) can distort the order of incoming headers, since [Erlang maps](http://erlang.org/doc/man/maps.html) do not [preserve ordering](https://medium.com/@jlouis666/breaking-erlang-maps-1-31952b8729e6) (cf. [[1]](https://github.com/elixir-plug/plug_cowboy/blob/7bf68cd757c1a052e227112b681b77066fd84d2b/lib/plug/cowboy/conn.ex#L125-L127), [[2]](https://github.com/erlang/otp/blob/2c882ec2d504019f07104b3240a989148dfc1fa3/lib/stdlib/doc/src/maps.xml#L409)). You *might* be able to configure `RemoteIp` to avoid your particular problematic situation.

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

If there's some bug you've fixed or feature you've implemented, contribute your changes through the usual means:

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
  * **Don't** leave your commits disorganized with various works-in-progress. [Rewrite](https://git-scm.com/book/id/v2/Git-Tools-Rewriting-History) [history](https://git-rebase.io/) [if](https://programmerfriend.com/git-best-practices/) [necessary](http://justinhileman.info/article/changing-history/).
* Write a good PR description.
  * What problem are you trying to solve?
  * Who does the problem affect?
  * When did this problem happen? Is it tied to a specific version?
  * Where is the source of the issue? Is it an external project? Can you link to a relevant discussion?
  * How did you solve it?
  * Why is this the proper solution?
* Write tests, if appropriate.
* Proper documentation is appreciated.
