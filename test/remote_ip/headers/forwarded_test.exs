defmodule RemoteIp.Headers.ForwardedTest do
  use ExUnit.Case, async: true
  alias RemoteIp.Headers.Forwarded

  doctest Forwarded

  describe "parsing" do
    test "RFC 7239 examples" do
      parsed = Forwarded.parse(~S'for="_gazonk"')
      assert parsed == []

      parsed = Forwarded.parse(~S'For="[2001:db8:cafe::17]:4711"')
      assert parsed == [{8193, 3512, 51966, 0, 0, 0, 0, 23}]

      parsed = Forwarded.parse(~S'for=192.0.2.60;proto=http;by=203.0.113.43')
      assert parsed == [{192, 0, 2, 60}]

      parsed = Forwarded.parse(~S'for=192.0.2.43, for=198.51.100.17')
      assert parsed == [{192, 0, 2, 43}, {198, 51, 100, 17}]
    end

    test "case insensitivity" do
      assert [{0, 0, 0, 0}] == Forwarded.parse(~S'for=0.0.0.0')
      assert [{0, 0, 0, 0}] == Forwarded.parse(~S'foR=0.0.0.0')
      assert [{0, 0, 0, 0}] == Forwarded.parse(~S'fOr=0.0.0.0')
      assert [{0, 0, 0, 0}] == Forwarded.parse(~S'fOR=0.0.0.0')
      assert [{0, 0, 0, 0}] == Forwarded.parse(~S'For=0.0.0.0')
      assert [{0, 0, 0, 0}] == Forwarded.parse(~S'FoR=0.0.0.0')
      assert [{0, 0, 0, 0}] == Forwarded.parse(~S'FOr=0.0.0.0')
      assert [{0, 0, 0, 0}] == Forwarded.parse(~S'FOR=0.0.0.0')

      assert [{0, 0, 0, 0, 0, 0, 0, 0}] == Forwarded.parse(~S'for="[::]"')
      assert [{0, 0, 0, 0, 0, 0, 0, 0}] == Forwarded.parse(~S'foR="[::]"')
      assert [{0, 0, 0, 0, 0, 0, 0, 0}] == Forwarded.parse(~S'fOr="[::]"')
      assert [{0, 0, 0, 0, 0, 0, 0, 0}] == Forwarded.parse(~S'fOR="[::]"')
      assert [{0, 0, 0, 0, 0, 0, 0, 0}] == Forwarded.parse(~S'For="[::]"')
      assert [{0, 0, 0, 0, 0, 0, 0, 0}] == Forwarded.parse(~S'FoR="[::]"')
      assert [{0, 0, 0, 0, 0, 0, 0, 0}] == Forwarded.parse(~S'FOr="[::]"')
      assert [{0, 0, 0, 0, 0, 0, 0, 0}] == Forwarded.parse(~S'FOR="[::]"')
    end

    test "IPv4" do
      assert [] == Forwarded.parse(~S'for=')
      assert [] == Forwarded.parse(~S'for=1')
      assert [] == Forwarded.parse(~S'for=1.2')
      assert [] == Forwarded.parse(~S'for=1.2.3')
      assert [] == Forwarded.parse(~S'for=1000.2.3.4')
      assert [] == Forwarded.parse(~S'for=1.2000.3.4')
      assert [] == Forwarded.parse(~S'for=1.2.3000.4')
      assert [] == Forwarded.parse(~S'for=1.2.3.4000')
      assert [] == Forwarded.parse(~S'for=1abc.2.3.4')
      assert [] == Forwarded.parse(~S'for=1.2abc.3.4')
      assert [] == Forwarded.parse(~S'for=1.2.3.4abc')
      assert [] == Forwarded.parse(~S'for=1.2.3abc.4')
      assert [] == Forwarded.parse(~S'for=1.2.3.4abc')
      assert [] == Forwarded.parse(~S'for="1.2.3.4')
      assert [] == Forwarded.parse(~S'for=1.2.3.4"')

      assert [{1, 2, 3, 4}] == Forwarded.parse(~S'for=1.2.3.4')
      assert [{1, 2, 3, 4}] == Forwarded.parse(~S'for="1.2.3.4"')
      assert [{1, 2, 3, 4}] == Forwarded.parse(~S'for="\1.2\.3.\4"')
    end

    test "IPv4 with port" do
      assert [] == Forwarded.parse(~S'for=1.2.3.4:')
      assert [] == Forwarded.parse(~S'for=1.2.3.4:1')
      assert [] == Forwarded.parse(~S'for=1.2.3.4:12')
      assert [] == Forwarded.parse(~S'for=1.2.3.4:123')
      assert [] == Forwarded.parse(~S'for=1.2.3.4:1234')
      assert [] == Forwarded.parse(~S'for=1.2.3.4:12345')
      assert [] == Forwarded.parse(~S'for=1.2.3.4:123456')
      assert [] == Forwarded.parse(~S'for=1.2.3.4:_underscore')
      assert [] == Forwarded.parse(~S'for=1.2.3.4:no_underscore')

      assert [] == Forwarded.parse(~S'for="1.2.3.4:"')
      assert [] == Forwarded.parse(~S'for="1.2.3.4:123456"')
      assert [] == Forwarded.parse(~S'for="1.2.3.4:no_underscore"')
      assert [] == Forwarded.parse(~S'for="1.2\.3.4\:no_un\der\score"')

      assert [{1, 2, 3, 4}] == Forwarded.parse(~S'for="1.2.3.4:1"')
      assert [{1, 2, 3, 4}] == Forwarded.parse(~S'for="1.2.3.4:12"')
      assert [{1, 2, 3, 4}] == Forwarded.parse(~S'for="1.2.3.4:123"')
      assert [{1, 2, 3, 4}] == Forwarded.parse(~S'for="1.2.3.4:1234"')
      assert [{1, 2, 3, 4}] == Forwarded.parse(~S'for="1.2.3.4:12345"')
      assert [{1, 2, 3, 4}] == Forwarded.parse(~S'for="1.2.3.4:_underscore"')
      assert [{1, 2, 3, 4}] == Forwarded.parse(~S'for="\1.2\.3.4\:_po\r\t"')
    end

    test "improperly formatted IPv6" do
      assert [] == Forwarded.parse(~S'for=[127.0.0.1]')
      assert [] == Forwarded.parse(~S'for="[127.0.0.1]"')

      assert [] == Forwarded.parse(~S'for=::127.0.0.1')
      assert [] == Forwarded.parse(~S'for=[::127.0.0.1]')
      assert [] == Forwarded.parse(~S'for="::127.0.0.1"')
      assert [] == Forwarded.parse(~S'for="[::127.0.0.1"')
      assert [] == Forwarded.parse(~S'for="::127.0.0.1]"')

      assert [] == Forwarded.parse(~S'for=1:2:3:4:5:6:7:8')
      assert [] == Forwarded.parse(~S'for=[1:2:3:4:5:6:7:8]')
      assert [] == Forwarded.parse(~S'for="1:2:3:4:5:6:7:8"')
      assert [] == Forwarded.parse(~S'for="[1:2:3:4:5:6:7:8"')
      assert [] == Forwarded.parse(~S'for="1:2:3:4:5:6:7:8]"')
    end

    test "IPv6 with port" do
      assert [] == Forwarded.parse(~S'for=::1.2.3.4:')
      assert [] == Forwarded.parse(~S'for=::1.2.3.4:1')
      assert [] == Forwarded.parse(~S'for=::1.2.3.4:12')
      assert [] == Forwarded.parse(~S'for=::1.2.3.4:123')
      assert [] == Forwarded.parse(~S'for=::1.2.3.4:1234')
      assert [] == Forwarded.parse(~S'for=::1.2.3.4:12345')
      assert [] == Forwarded.parse(~S'for=::1.2.3.4:123456')
      assert [] == Forwarded.parse(~S'for=::1.2.3.4:_underscore')
      assert [] == Forwarded.parse(~S'for=::1.2.3.4:no_underscore')
      assert [] == Forwarded.parse(~S'for=[::1.2.3.4]:')
      assert [] == Forwarded.parse(~S'for=[::1.2.3.4]:1')
      assert [] == Forwarded.parse(~S'for=[::1.2.3.4]:12')
      assert [] == Forwarded.parse(~S'for=[::1.2.3.4]:123')
      assert [] == Forwarded.parse(~S'for=[::1.2.3.4]:1234')
      assert [] == Forwarded.parse(~S'for=[::1.2.3.4]:12345')
      assert [] == Forwarded.parse(~S'for=[::1.2.3.4]:123456')
      assert [] == Forwarded.parse(~S'for=[::1.2.3.4]:_underscore')
      assert [] == Forwarded.parse(~S'for=[::1.2.3.4]:no_underscore')

      assert [] == Forwarded.parse(~S'for="::1.2.3.4:"')
      assert [] == Forwarded.parse(~S'for="::1.2.3.4:123456"')
      assert [] == Forwarded.parse(~S'for="::1.2.3.4:no_underscore"')
      assert [] == Forwarded.parse(~S'for="::1.2\.3.4\:no_un\der\score"')
      assert [] == Forwarded.parse(~S'for="[::1.2.3.4]:"')
      assert [] == Forwarded.parse(~S'for="[::1.2.3.4]:123456"')
      assert [] == Forwarded.parse(~S'for="[::1.2.3.4]:no_underscore"')
      assert [] == Forwarded.parse(~S'for="\[::1.2\.3.4]\:no_un\der\score"')

      assert [] == Forwarded.parse(~S'for="::1.2.3.4:1"')
      assert [] == Forwarded.parse(~S'for="::1.2.3.4:12"')
      assert [] == Forwarded.parse(~S'for="::1.2.3.4:123"')
      assert [] == Forwarded.parse(~S'for="::1.2.3.4:1234"')
      assert [] == Forwarded.parse(~S'for="::1.2.3.4:12345"')
      assert [] == Forwarded.parse(~S'for="::1.2.3.4:_underscore"')
      assert [] == Forwarded.parse(~S'for="::\1.2\.3.4\:_po\r\t"')

      assert [{0, 0, 0, 0, 0, 0, 258, 772}] == Forwarded.parse(~S'for="[::1.2.3.4]:1"')
      assert [{0, 0, 0, 0, 0, 0, 258, 772}] == Forwarded.parse(~S'for="[::1.2.3.4]:12"')
      assert [{0, 0, 0, 0, 0, 0, 258, 772}] == Forwarded.parse(~S'for="[::1.2.3.4]:123"')
      assert [{0, 0, 0, 0, 0, 0, 258, 772}] == Forwarded.parse(~S'for="[::1.2.3.4]:1234"')
      assert [{0, 0, 0, 0, 0, 0, 258, 772}] == Forwarded.parse(~S'for="[::1.2.3.4]:12345"')
      assert [{0, 0, 0, 0, 0, 0, 258, 772}] == Forwarded.parse(~S'for="[::1.2.3.4]:_underscore"')
      assert [{0, 0, 0, 0, 0, 0, 258, 772}] == Forwarded.parse(~S'for="[::\1.2\.3.4\]\:_po\r\t"')

      assert [] == Forwarded.parse(~S'for=1:2:3:4:5:6:7:8:')
      assert [] == Forwarded.parse(~S'for=1:2:3:4:5:6:7:8:1')
      assert [] == Forwarded.parse(~S'for=1:2:3:4:5:6:7:8:12')
      assert [] == Forwarded.parse(~S'for=1:2:3:4:5:6:7:8:123')
      assert [] == Forwarded.parse(~S'for=1:2:3:4:5:6:7:8:1234')
      assert [] == Forwarded.parse(~S'for=1:2:3:4:5:6:7:8:12345')
      assert [] == Forwarded.parse(~S'for=1:2:3:4:5:6:7:8:123456')
      assert [] == Forwarded.parse(~S'for=1:2:3:4:5:6:7:8:_underscore')
      assert [] == Forwarded.parse(~S'for=1:2:3:4:5:6:7:8:no_underscore')
      assert [] == Forwarded.parse(~S'for=[1:2:3:4:5:6:7:8]:')
      assert [] == Forwarded.parse(~S'for=[1:2:3:4:5:6:7:8]:1')
      assert [] == Forwarded.parse(~S'for=[1:2:3:4:5:6:7:8]:12')
      assert [] == Forwarded.parse(~S'for=[1:2:3:4:5:6:7:8]:123')
      assert [] == Forwarded.parse(~S'for=[1:2:3:4:5:6:7:8]:1234')
      assert [] == Forwarded.parse(~S'for=[1:2:3:4:5:6:7:8]:12345')
      assert [] == Forwarded.parse(~S'for=[1:2:3:4:5:6:7:8]:123456')
      assert [] == Forwarded.parse(~S'for=[1:2:3:4:5:6:7:8]:_underscore')
      assert [] == Forwarded.parse(~S'for=[1:2:3:4:5:6:7:8]:no_underscore')

      assert [] == Forwarded.parse(~S'for="1:2:3:4:5:6:7:8:"')
      assert [] == Forwarded.parse(~S'for="1:2:3:4:5:6:7:8:123456"')
      assert [] == Forwarded.parse(~S'for="1:2:3:4:5:6:7:8:no_underscore"')
      assert [] == Forwarded.parse(~S'for="::1.2\.3.4\:no_un\der\score"')
      assert [] == Forwarded.parse(~S'for="[1:2:3:4:5:6:7:8]:"')
      assert [] == Forwarded.parse(~S'for="[1:2:3:4:5:6:7:8]:123456"')
      assert [] == Forwarded.parse(~S'for="[1:2:3:4:5:6:7:8]:no_underscore"')
      assert [] == Forwarded.parse(~S'for="\[1:2\:3:4:5:6:7:8]\:no_un\der\score"')

      assert [] == Forwarded.parse(~S'for="1:2:3:4:5:6:7:8:1"')
      assert [] == Forwarded.parse(~S'for="1:2:3:4:5:6:7:8:12"')
      assert [] == Forwarded.parse(~S'for="1:2:3:4:5:6:7:8:123"')
      assert [] == Forwarded.parse(~S'for="1:2:3:4:5:6:7:8:1234"')
      assert [] == Forwarded.parse(~S'for="1:2:3:4:5:6:7:8:12345"')
      assert [] == Forwarded.parse(~S'for="1:2:3:4:5:6:7:8:_underscore"')
      assert [] == Forwarded.parse(~S'for="\1:2\:3:4:5:6:7:8\:_po\r\t"')

      assert [{1, 2, 3, 4, 5, 6, 7, 8}] == Forwarded.parse(~S'for="[1:2:3:4:5:6:7:8]:1"')
      assert [{1, 2, 3, 4, 5, 6, 7, 8}] == Forwarded.parse(~S'for="[1:2:3:4:5:6:7:8]:12"')
      assert [{1, 2, 3, 4, 5, 6, 7, 8}] == Forwarded.parse(~S'for="[1:2:3:4:5:6:7:8]:123"')
      assert [{1, 2, 3, 4, 5, 6, 7, 8}] == Forwarded.parse(~S'for="[1:2:3:4:5:6:7:8]:1234"')
      assert [{1, 2, 3, 4, 5, 6, 7, 8}] == Forwarded.parse(~S'for="[1:2:3:4:5:6:7:8]:12345"')

      assert [{1, 2, 3, 4, 5, 6, 7, 8}] ==
               Forwarded.parse(~S'for="[1:2:3:4:5:6:7:8]:_underscore"')

      assert [{1, 2, 3, 4, 5, 6, 7, 8}] ==
               Forwarded.parse(~S'for="[1:2:3:4:\5:6\:7:8\]\:_po\r\t"')
    end

    test "IPv6 without ::" do
      assert [{0x0001, 0x0023, 0x0456, 0x7890, 0x000A, 0x00BC, 0x0DEF, 0xD34D}] ==
               Forwarded.parse(~S'for="[1:23:456:7890:a:bc:def:d34d]"')

      assert [{0x0001, 0x0023, 0x0456, 0x7890, 0x000A, 0x00BC, 0x0102, 0x0304}] ==
               Forwarded.parse(~S'for="[1:23:456:7890:a:bc:1.2.3.4]"')
    end

    test "IPv6 with :: at position 0" do
      assert [{0x0000, 0x0023, 0x0456, 0x7890, 0x000A, 0x00BC, 0x0DEF, 0xD34D}] ==
               Forwarded.parse(~S'for="[::23:456:7890:a:bc:def:d34d]"')

      assert [{0x0000, 0x0023, 0x0456, 0x7890, 0x000A, 0x00BC, 0x0102, 0x0304}] ==
               Forwarded.parse(~S'for="[::23:456:7890:a:bc:1.2.3.4]"')

      assert [{0x0000, 0x0000, 0x0456, 0x7890, 0x000A, 0x00BC, 0x0DEF, 0xD34D}] ==
               Forwarded.parse(~S'for="[::456:7890:a:bc:def:d34d]"')

      assert [{0x0000, 0x0000, 0x0456, 0x7890, 0x000A, 0x00BC, 0x0102, 0x0304}] ==
               Forwarded.parse(~S'for="[::456:7890:a:bc:1.2.3.4]"')

      assert [{0x0000, 0x0000, 0x0000, 0x7890, 0x000A, 0x00BC, 0x0DEF, 0xD34D}] ==
               Forwarded.parse(~S'for="[::7890:a:bc:def:d34d]"')

      assert [{0x0000, 0x0000, 0x0000, 0x7890, 0x000A, 0x00BC, 0x0102, 0x0304}] ==
               Forwarded.parse(~S'for="[::7890:a:bc:1.2.3.4]"')

      assert [{0x0000, 0x0000, 0x0000, 0x0000, 0x000A, 0x00BC, 0x0DEF, 0xD34D}] ==
               Forwarded.parse(~S'for="[::a:bc:def:d34d]"')

      assert [{0x0000, 0x0000, 0x0000, 0x0000, 0x000A, 0x00BC, 0x0102, 0x0304}] ==
               Forwarded.parse(~S'for="[::a:bc:1.2.3.4]"')

      assert [{0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x00BC, 0x0DEF, 0xD34D}] ==
               Forwarded.parse(~S'for="[::bc:def:d34d]"')

      assert [{0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x00BC, 0x0102, 0x0304}] ==
               Forwarded.parse(~S'for="[::bc:1.2.3.4]"')

      assert [{0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0DEF, 0xD34D}] ==
               Forwarded.parse(~S'for="[::def:d34d]"')

      assert [{0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0102, 0x0304}] ==
               Forwarded.parse(~S'for="[::1.2.3.4]"')

      assert [{0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0xD34D}] ==
               Forwarded.parse(~S'for="[::d34d]"')

      assert [{0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000}] ==
               Forwarded.parse(~S'for="[::]"')
    end

    test "IPv6 with :: at position 1" do
      assert [{0x0001, 0x000, 0x0456, 0x7890, 0x000A, 0x00BC, 0x0DEF, 0xD34D}] ==
               Forwarded.parse(~S'for="[1::456:7890:a:bc:def:d34d]"')

      assert [{0x0001, 0x000, 0x0456, 0x7890, 0x000A, 0x00BC, 0x0102, 0x0304}] ==
               Forwarded.parse(~S'for="[1::456:7890:a:bc:1.2.3.4]"')

      assert [{0x0001, 0x000, 0x0000, 0x7890, 0x000A, 0x00BC, 0x0DEF, 0xD34D}] ==
               Forwarded.parse(~S'for="[1::7890:a:bc:def:d34d]"')

      assert [{0x0001, 0x000, 0x0000, 0x7890, 0x000A, 0x00BC, 0x0102, 0x0304}] ==
               Forwarded.parse(~S'for="[1::7890:a:bc:1.2.3.4]"')

      assert [{0x0001, 0x000, 0x0000, 0x0000, 0x000A, 0x00BC, 0x0DEF, 0xD34D}] ==
               Forwarded.parse(~S'for="[1::a:bc:def:d34d]"')

      assert [{0x0001, 0x000, 0x0000, 0x0000, 0x000A, 0x00BC, 0x0102, 0x0304}] ==
               Forwarded.parse(~S'for="[1::a:bc:1.2.3.4]"')

      assert [{0x0001, 0x000, 0x0000, 0x0000, 0x0000, 0x00BC, 0x0DEF, 0xD34D}] ==
               Forwarded.parse(~S'for="[1::bc:def:d34d]"')

      assert [{0x0001, 0x000, 0x0000, 0x0000, 0x0000, 0x00BC, 0x0102, 0x0304}] ==
               Forwarded.parse(~S'for="[1::bc:1.2.3.4]"')

      assert [{0x0001, 0x000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0DEF, 0xD34D}] ==
               Forwarded.parse(~S'for="[1::def:d34d]"')

      assert [{0x0001, 0x000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0102, 0x0304}] ==
               Forwarded.parse(~S'for="[1::1.2.3.4]"')

      assert [{0x0001, 0x000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0xD34D}] ==
               Forwarded.parse(~S'for="[1::d34d]"')

      assert [{0x0001, 0x000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000}] ==
               Forwarded.parse(~S'for="[1::]"')
    end

    test "IPv6 with :: at position 2" do
      assert [{0x0001, 0x023, 0x0000, 0x7890, 0x000A, 0x00BC, 0x0DEF, 0xD34D}] ==
               Forwarded.parse(~S'for="[1:23::7890:a:bc:def:d34d]"')

      assert [{0x0001, 0x023, 0x0000, 0x7890, 0x000A, 0x00BC, 0x0102, 0x0304}] ==
               Forwarded.parse(~S'for="[1:23::7890:a:bc:1.2.3.4]"')

      assert [{0x0001, 0x023, 0x0000, 0x0000, 0x000A, 0x00BC, 0x0DEF, 0xD34D}] ==
               Forwarded.parse(~S'for="[1:23::a:bc:def:d34d]"')

      assert [{0x0001, 0x023, 0x0000, 0x0000, 0x000A, 0x00BC, 0x0102, 0x0304}] ==
               Forwarded.parse(~S'for="[1:23::a:bc:1.2.3.4]"')

      assert [{0x0001, 0x023, 0x0000, 0x0000, 0x0000, 0x00BC, 0x0DEF, 0xD34D}] ==
               Forwarded.parse(~S'for="[1:23::bc:def:d34d]"')

      assert [{0x0001, 0x023, 0x0000, 0x0000, 0x0000, 0x00BC, 0x0102, 0x0304}] ==
               Forwarded.parse(~S'for="[1:23::bc:1.2.3.4]"')

      assert [{0x0001, 0x023, 0x0000, 0x0000, 0x0000, 0x0000, 0x0DEF, 0xD34D}] ==
               Forwarded.parse(~S'for="[1:23::def:d34d]"')

      assert [{0x0001, 0x023, 0x0000, 0x0000, 0x0000, 0x0000, 0x0102, 0x0304}] ==
               Forwarded.parse(~S'for="[1:23::1.2.3.4]"')

      assert [{0x0001, 0x023, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0xD34D}] ==
               Forwarded.parse(~S'for="[1:23::d34d]"')

      assert [{0x0001, 0x023, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000}] ==
               Forwarded.parse(~S'for="[1:23::]"')
    end

    test "IPv6 with :: at position 3" do
      assert [{0x0001, 0x023, 0x0456, 0x0000, 0x000A, 0x00BC, 0x0DEF, 0xD34D}] ==
               Forwarded.parse(~S'for="[1:23:456::a:bc:def:d34d]"')

      assert [{0x0001, 0x023, 0x0456, 0x0000, 0x000A, 0x00BC, 0x0102, 0x0304}] ==
               Forwarded.parse(~S'for="[1:23:456::a:bc:1.2.3.4]"')

      assert [{0x0001, 0x023, 0x0456, 0x0000, 0x0000, 0x00BC, 0x0DEF, 0xD34D}] ==
               Forwarded.parse(~S'for="[1:23:456::bc:def:d34d]"')

      assert [{0x0001, 0x023, 0x0456, 0x0000, 0x0000, 0x00BC, 0x0102, 0x0304}] ==
               Forwarded.parse(~S'for="[1:23:456::bc:1.2.3.4]"')

      assert [{0x0001, 0x023, 0x0456, 0x0000, 0x0000, 0x0000, 0x0DEF, 0xD34D}] ==
               Forwarded.parse(~S'for="[1:23:456::def:d34d]"')

      assert [{0x0001, 0x023, 0x0456, 0x0000, 0x0000, 0x0000, 0x0102, 0x0304}] ==
               Forwarded.parse(~S'for="[1:23:456::1.2.3.4]"')

      assert [{0x0001, 0x023, 0x0456, 0x0000, 0x0000, 0x0000, 0x0000, 0xD34D}] ==
               Forwarded.parse(~S'for="[1:23:456::d34d]"')

      assert [{0x0001, 0x023, 0x0456, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000}] ==
               Forwarded.parse(~S'for="[1:23:456::]"')
    end

    test "IPv6 with :: at position 4" do
      assert [{0x0001, 0x023, 0x0456, 0x7890, 0x0000, 0x00BC, 0x0DEF, 0xD34D}] ==
               Forwarded.parse(~S'for="[1:23:456:7890::bc:def:d34d]"')

      assert [{0x0001, 0x023, 0x0456, 0x7890, 0x0000, 0x00BC, 0x0102, 0x0304}] ==
               Forwarded.parse(~S'for="[1:23:456:7890::bc:1.2.3.4]"')

      assert [{0x0001, 0x023, 0x0456, 0x7890, 0x0000, 0x0000, 0x0DEF, 0xD34D}] ==
               Forwarded.parse(~S'for="[1:23:456:7890::def:d34d]"')

      assert [{0x0001, 0x023, 0x0456, 0x7890, 0x0000, 0x0000, 0x0102, 0x0304}] ==
               Forwarded.parse(~S'for="[1:23:456:7890::1.2.3.4]"')

      assert [{0x0001, 0x023, 0x0456, 0x7890, 0x0000, 0x0000, 0x0000, 0xD34D}] ==
               Forwarded.parse(~S'for="[1:23:456:7890::d34d]"')

      assert [{0x0001, 0x023, 0x0456, 0x7890, 0x0000, 0x0000, 0x0000, 0x0000}] ==
               Forwarded.parse(~S'for="[1:23:456:7890::]"')
    end

    test "IPv6 with :: at position 5" do
      assert [{0x0001, 0x023, 0x0456, 0x7890, 0x000A, 0x0000, 0x0DEF, 0xD34D}] ==
               Forwarded.parse(~S'for="[1:23:456:7890:a::def:d34d]"')

      assert [{0x0001, 0x023, 0x0456, 0x7890, 0x000A, 0x0000, 0x0102, 0x0304}] ==
               Forwarded.parse(~S'for="[1:23:456:7890:a::1.2.3.4]"')

      assert [{0x0001, 0x023, 0x0456, 0x7890, 0x000A, 0x0000, 0x0000, 0xD34D}] ==
               Forwarded.parse(~S'for="[1:23:456:7890:a::d34d]"')

      assert [{0x0001, 0x023, 0x0456, 0x7890, 0x000A, 0x0000, 0x0000, 0x0000}] ==
               Forwarded.parse(~S'for="[1:23:456:7890:a::]"')
    end

    test "IPv6 with :: at position 6" do
      assert [{0x0001, 0x023, 0x0456, 0x7890, 0x000A, 0x00BC, 0x0000, 0xD34D}] ==
               Forwarded.parse(~S'for="[1:23:456:7890:a:bc::d34d]"')

      assert [{0x0001, 0x023, 0x0456, 0x7890, 0x000A, 0x00BC, 0x0000, 0x0000}] ==
               Forwarded.parse(~S'for="[1:23:456:7890:a:bc::]"')
    end

    test "IPv6 with leading zeroes" do
      assert [{0x0000, 0x0001, 0x0002, 0x0003, 0x0000, 0x0000, 0x0000, 0x0000}] ==
               Forwarded.parse(~S'for="[0:01:002:0003:0000::]"')

      assert [{0x000A, 0x001A, 0x002A, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000}] ==
               Forwarded.parse(~S'for="[0a:01a:002a::]"')

      assert [{0x00AB, 0x01AB, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000}] ==
               Forwarded.parse(~S'for="[0ab:01ab::]"')

      assert [{0x0ABC, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000}] ==
               Forwarded.parse(~S'for="[0abc::]"')
    end

    test "IPv6 with mixed case" do
      assert [{0xABCD, 0xABCD, 0xABCD, 0xABCD, 0xABCD, 0xABCD, 0xABCD, 0xABCD}] ==
               Forwarded.parse(~S'for="[abcd:abcD:abCd:abCD:aBcd:aBcD:aBCd:aBCD]"')

      assert [{0xABCD, 0xABCD, 0xABCD, 0xABCD, 0xABCD, 0xABCD, 0xABCD, 0xABCD}] ==
               Forwarded.parse(~S'for="[Abcd:AbcD:AbCd:AbCD:ABcd:ABcD:ABCd:ABCD]"')
    end

    test "semicolons" do
      assert [{1, 2, 3, 4}] == Forwarded.parse(~S'for=1.2.3.4;proto=http;by=2.3.4.5')
      assert [{1, 2, 3, 4}] == Forwarded.parse(~S'proto=http;for=1.2.3.4;by=2.3.4.5')
      assert [{1, 2, 3, 4}] == Forwarded.parse(~S'proto=http;by=2.3.4.5;for=1.2.3.4')

      assert [] == Forwarded.parse(~S'for=1.2.3.4proto=http;by=2.3.4.5')
      assert [] == Forwarded.parse(~S'proto=httpfor=1.2.3.4;by=2.3.4.5')
      assert [] == Forwarded.parse(~S'proto=http;by=2.3.4.5for=1.2.3.4')

      assert [] == Forwarded.parse(~S'for=1.2.3.4;proto=http;by=2.3.4.5;')
      assert [] == Forwarded.parse(~S'proto=http;for=1.2.3.4;by=2.3.4.5;')
      assert [] == Forwarded.parse(~S'proto=http;by=2.3.4.5;for=1.2.3.4;')

      assert [] == Forwarded.parse(~S'for=1.2.3.4;proto=http;for=2.3.4.5')
      assert [] == Forwarded.parse(~S'for=1.2.3.4;for=2.3.4.5;proto=http')
      assert [] == Forwarded.parse(~S'proto=http;for=1.2.3.4;for=2.3.4.5')
    end

    test "parameters other than `for`" do
      assert [] == Forwarded.parse(~S'by=1.2.3.4')
      assert [] == Forwarded.parse(~S'host=example.com')
      assert [] == Forwarded.parse(~S'proto=http')
      assert [] == Forwarded.parse(~S'by=1.2.3.4;proto=http;host=example.com')
    end

    test "bad whitespace" do
      assert [] == Forwarded.parse(~S'for= 1.2.3.4')
      assert [] == Forwarded.parse(~S'for = 1.2.3.4')
      assert [] == Forwarded.parse(~S'for=1.2.3.4; proto=http')
      assert [] == Forwarded.parse(~S'for=1.2.3.4 ;proto=http')
      assert [] == Forwarded.parse(~S'for=1.2.3.4 ; proto=http')
      assert [] == Forwarded.parse(~S'proto=http; for=1.2.3.4')
      assert [] == Forwarded.parse(~S'proto=http ;for=1.2.3.4')
      assert [] == Forwarded.parse(~S'proto=http ; for=1.2.3.4')
    end

    test "commas" do
      assert [{1, 2, 3, 4}, {2, 3, 4, 5}] == Forwarded.parse(~S'for=1.2.3.4, for=2.3.4.5')

      assert [{1, 2, 3, 4}, {0, 0, 0, 0, 2, 3, 4, 5}] ==
               Forwarded.parse(~S'for=1.2.3.4, for="[::2:3:4:5]"')

      assert [{1, 2, 3, 4}, {0, 0, 0, 0, 2, 3, 4, 5}] ==
               Forwarded.parse(~S'for=1.2.3.4, for="[::2:3:4:5]"')

      assert [{0, 0, 0, 0, 1, 2, 3, 4}, {2, 3, 4, 5}] ==
               Forwarded.parse(~S'for="[::1:2:3:4]", for=2.3.4.5')

      assert [{0, 0, 0, 0, 1, 2, 3, 4}, {0, 0, 0, 0, 2, 3, 4, 5}] ==
               Forwarded.parse(~S'for="[::1:2:3:4]", for="[::2:3:4:5]"')
    end

    test "optional whitespace" do
      assert [{1, 2, 3, 4}, {2, 3, 4, 5}, {3, 4, 5, 6}, {4, 5, 6, 7}, {5, 6, 7, 8}] ==
               Forwarded.parse(
                 "for=1.2.3.4,for=2.3.4.5,\sfor=3.4.5.6\s,for=4.5.6.7\s,\sfor=5.6.7.8"
               )

      assert [{1, 2, 3, 4}, {2, 3, 4, 5}, {3, 4, 5, 6}, {4, 5, 6, 7}, {5, 6, 7, 8}] ==
               Forwarded.parse(
                 "for=1.2.3.4,for=2.3.4.5,\tfor=3.4.5.6\t,for=4.5.6.7\t,\tfor=5.6.7.8"
               )

      assert [{1, 2, 3, 4}, {2, 3, 4, 5}] == Forwarded.parse("for=1.2.3.4\s\s,\s\sfor=2.3.4.5")
      assert [{1, 2, 3, 4}, {2, 3, 4, 5}] == Forwarded.parse("for=1.2.3.4\s\s,\s\tfor=2.3.4.5")
      assert [{1, 2, 3, 4}, {2, 3, 4, 5}] == Forwarded.parse("for=1.2.3.4\s\s,\t\sfor=2.3.4.5")
      assert [{1, 2, 3, 4}, {2, 3, 4, 5}] == Forwarded.parse("for=1.2.3.4\s\s,\t\tfor=2.3.4.5")
      assert [{1, 2, 3, 4}, {2, 3, 4, 5}] == Forwarded.parse("for=1.2.3.4\s\t,\s\sfor=2.3.4.5")
      assert [{1, 2, 3, 4}, {2, 3, 4, 5}] == Forwarded.parse("for=1.2.3.4\s\t,\s\tfor=2.3.4.5")
      assert [{1, 2, 3, 4}, {2, 3, 4, 5}] == Forwarded.parse("for=1.2.3.4\s\t,\t\sfor=2.3.4.5")
      assert [{1, 2, 3, 4}, {2, 3, 4, 5}] == Forwarded.parse("for=1.2.3.4\s\t,\t\tfor=2.3.4.5")
      assert [{1, 2, 3, 4}, {2, 3, 4, 5}] == Forwarded.parse("for=1.2.3.4\t\s,\s\sfor=2.3.4.5")
      assert [{1, 2, 3, 4}, {2, 3, 4, 5}] == Forwarded.parse("for=1.2.3.4\t\s,\s\tfor=2.3.4.5")
      assert [{1, 2, 3, 4}, {2, 3, 4, 5}] == Forwarded.parse("for=1.2.3.4\t\s,\t\sfor=2.3.4.5")
      assert [{1, 2, 3, 4}, {2, 3, 4, 5}] == Forwarded.parse("for=1.2.3.4\t\s,\t\tfor=2.3.4.5")
      assert [{1, 2, 3, 4}, {2, 3, 4, 5}] == Forwarded.parse("for=1.2.3.4\t\t,\s\sfor=2.3.4.5")
      assert [{1, 2, 3, 4}, {2, 3, 4, 5}] == Forwarded.parse("for=1.2.3.4\t\t,\s\tfor=2.3.4.5")
      assert [{1, 2, 3, 4}, {2, 3, 4, 5}] == Forwarded.parse("for=1.2.3.4\t\t,\t\sfor=2.3.4.5")
      assert [{1, 2, 3, 4}, {2, 3, 4, 5}] == Forwarded.parse("for=1.2.3.4\t\t,\t\tfor=2.3.4.5")

      assert [{1, 2, 3, 4}, {2, 3, 4, 5}] ==
               Forwarded.parse("for=1.2.3.4\t\s\s\s\s\t\s\t\s\t,\t\s\s\t\tfor=2.3.4.5")
    end

    test "commas and semicolons" do
      assert [{1, 2, 3, 4}, {0, 0, 0, 0, 2, 3, 4, 5}, {3, 4, 5, 6}, {0, 0, 0, 0, 4, 5, 6, 7}] ==
               Forwarded.parse(
                 ~S'for=1.2.3.4, for="[::2:3:4:5]";proto=http;host=example.com, proto=http;for=3.4.5.6;by=127.0.0.1, proto=http;host=example.com;for="[::4:5:6:7]"'
               )
    end
  end
end
