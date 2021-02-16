[
  inputs: ["**/*.exs"],
  import_deps: [:plug],

  # This is an arbitrarily long line length. While most of the code conforms to
  # an 80-character limit, many of the parsing tests involve gnarly strings &
  # IP tuples that are just nicer to have on a single line. There's no good way
  # of expressing this at a finer granularity (e.g., flagging specific sections
  # of code), so we just let the tests get away with murder in general.
  line_length: 800
]
