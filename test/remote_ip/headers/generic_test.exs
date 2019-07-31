defmodule RemoteIp.Headers.GenericTest do
  use ExUnit.Case, async: true
  alias RemoteIp.Headers.Generic

  doctest Generic

  describe "parsing" do
    test "bad IPs" do
      assert [] == Generic.parse("")
      assert [] == Generic.parse("      ")
      assert [] == Generic.parse("not_an_ip")
      assert [] == Generic.parse("unknown")
    end

    test "bad IPv4" do
      assert [] == Generic.parse("1")
      assert [] == Generic.parse("1.2")
      assert [] == Generic.parse("1.2.3")
      assert [] == Generic.parse("1000.2.3.4")
      assert [] == Generic.parse("1.2000.3.4")
      assert [] == Generic.parse("1.2.3000.4")
      assert [] == Generic.parse("1.2.3.4000")
      assert [] == Generic.parse("1abc.2.3.4")
      assert [] == Generic.parse("1.2abc.3.4")
      assert [] == Generic.parse("1.2.3.4abc")
      assert [] == Generic.parse("1.2.3abc.4")
      assert [] == Generic.parse("1.2.3.4abc")
      assert [] == Generic.parse("1.2.3.4.5")
    end

    test "bad IPv6" do
      assert [] == Generic.parse("1:")
      assert [] == Generic.parse("1:2")
      assert [] == Generic.parse("1:2:3")
      assert [] == Generic.parse("1:2:3:4")
      assert [] == Generic.parse("1:2:3:4:5")
      assert [] == Generic.parse("1:2:3:4:5:6")
      assert [] == Generic.parse("1:2:3:4:5:6:7")
      assert [] == Generic.parse("1:2:3:4:5:6:7:8:")
      assert [] == Generic.parse("1:2:3:4:5:6:7:8:9")
      assert [] == Generic.parse("1:::2:3:4:5:6:7:8")
      assert [] == Generic.parse("a:b:c:d:e:f::g")
    end

    test "IPv4" do
      assert [{1, 2, 3, 4}] == Generic.parse("1.2.3.4")
      assert [{1, 2, 3, 4}] == Generic.parse("   1.2.3.4   ")
    end

    test "IPv6 without ::" do
      assert [{0x0001, 0x0023, 0x0456, 0x7890, 0x000A, 0x00BC, 0x0DEF, 0xD34D}] ==
               Generic.parse("1:23:456:7890:a:bc:def:d34d")

      assert [{0x0001, 0x0023, 0x0456, 0x7890, 0x000A, 0x00BC, 0x0102, 0x0304}] ==
               Generic.parse("1:23:456:7890:a:bc:1.2.3.4")
    end

    test "IPv6 with :: at position 0" do
      assert [{0x0000, 0x0023, 0x0456, 0x7890, 0x000A, 0x00BC, 0x0DEF, 0xD34D}] ==
               Generic.parse("::23:456:7890:a:bc:def:d34d")

      assert [{0x0000, 0x0023, 0x0456, 0x7890, 0x000A, 0x00BC, 0x0102, 0x0304}] ==
               Generic.parse("::23:456:7890:a:bc:1.2.3.4")

      assert [{0x0000, 0x0000, 0x0456, 0x7890, 0x000A, 0x00BC, 0x0DEF, 0xD34D}] ==
               Generic.parse("::456:7890:a:bc:def:d34d")

      assert [{0x0000, 0x0000, 0x0456, 0x7890, 0x000A, 0x00BC, 0x0102, 0x0304}] ==
               Generic.parse("::456:7890:a:bc:1.2.3.4")

      assert [{0x0000, 0x0000, 0x0000, 0x7890, 0x000A, 0x00BC, 0x0DEF, 0xD34D}] ==
               Generic.parse("::7890:a:bc:def:d34d")

      assert [{0x0000, 0x0000, 0x0000, 0x7890, 0x000A, 0x00BC, 0x0102, 0x0304}] ==
               Generic.parse("::7890:a:bc:1.2.3.4")

      assert [{0x0000, 0x0000, 0x0000, 0x0000, 0x000A, 0x00BC, 0x0DEF, 0xD34D}] ==
               Generic.parse("::a:bc:def:d34d")

      assert [{0x0000, 0x0000, 0x0000, 0x0000, 0x000A, 0x00BC, 0x0102, 0x0304}] ==
               Generic.parse("::a:bc:1.2.3.4")

      assert [{0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x00BC, 0x0DEF, 0xD34D}] ==
               Generic.parse("::bc:def:d34d")

      assert [{0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x00BC, 0x0102, 0x0304}] ==
               Generic.parse("::bc:1.2.3.4")

      assert [{0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0DEF, 0xD34D}] ==
               Generic.parse("::def:d34d")

      assert [{0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0102, 0x0304}] ==
               Generic.parse("::1.2.3.4")

      assert [{0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0xD34D}] ==
               Generic.parse("::d34d")

      assert [{0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000}] ==
               Generic.parse("::")
    end

    test "IPv6 with :: at position 1" do
      assert [{0x0001, 0x000, 0x0456, 0x7890, 0x000A, 0x00BC, 0x0DEF, 0xD34D}] ==
               Generic.parse("1::456:7890:a:bc:def:d34d")

      assert [{0x0001, 0x000, 0x0456, 0x7890, 0x000A, 0x00BC, 0x0102, 0x0304}] ==
               Generic.parse("1::456:7890:a:bc:1.2.3.4")

      assert [{0x0001, 0x000, 0x0000, 0x7890, 0x000A, 0x00BC, 0x0DEF, 0xD34D}] ==
               Generic.parse("1::7890:a:bc:def:d34d")

      assert [{0x0001, 0x000, 0x0000, 0x7890, 0x000A, 0x00BC, 0x0102, 0x0304}] ==
               Generic.parse("1::7890:a:bc:1.2.3.4")

      assert [{0x0001, 0x000, 0x0000, 0x0000, 0x000A, 0x00BC, 0x0DEF, 0xD34D}] ==
               Generic.parse("1::a:bc:def:d34d")

      assert [{0x0001, 0x000, 0x0000, 0x0000, 0x000A, 0x00BC, 0x0102, 0x0304}] ==
               Generic.parse("1::a:bc:1.2.3.4")

      assert [{0x0001, 0x000, 0x0000, 0x0000, 0x0000, 0x00BC, 0x0DEF, 0xD34D}] ==
               Generic.parse("1::bc:def:d34d")

      assert [{0x0001, 0x000, 0x0000, 0x0000, 0x0000, 0x00BC, 0x0102, 0x0304}] ==
               Generic.parse("1::bc:1.2.3.4")

      assert [{0x0001, 0x000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0DEF, 0xD34D}] ==
               Generic.parse("1::def:d34d")

      assert [{0x0001, 0x000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0102, 0x0304}] ==
               Generic.parse("1::1.2.3.4")

      assert [{0x0001, 0x000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0xD34D}] ==
               Generic.parse("1::d34d")

      assert [{0x0001, 0x000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000}] ==
               Generic.parse("1::")
    end

    test "IPv6 with :: at position 2" do
      assert [{0x0001, 0x023, 0x0000, 0x7890, 0x000A, 0x00BC, 0x0DEF, 0xD34D}] ==
               Generic.parse("1:23::7890:a:bc:def:d34d")

      assert [{0x0001, 0x023, 0x0000, 0x7890, 0x000A, 0x00BC, 0x0102, 0x0304}] ==
               Generic.parse("1:23::7890:a:bc:1.2.3.4")

      assert [{0x0001, 0x023, 0x0000, 0x0000, 0x000A, 0x00BC, 0x0DEF, 0xD34D}] ==
               Generic.parse("1:23::a:bc:def:d34d")

      assert [{0x0001, 0x023, 0x0000, 0x0000, 0x000A, 0x00BC, 0x0102, 0x0304}] ==
               Generic.parse("1:23::a:bc:1.2.3.4")

      assert [{0x0001, 0x023, 0x0000, 0x0000, 0x0000, 0x00BC, 0x0DEF, 0xD34D}] ==
               Generic.parse("1:23::bc:def:d34d")

      assert [{0x0001, 0x023, 0x0000, 0x0000, 0x0000, 0x00BC, 0x0102, 0x0304}] ==
               Generic.parse("1:23::bc:1.2.3.4")

      assert [{0x0001, 0x023, 0x0000, 0x0000, 0x0000, 0x0000, 0x0DEF, 0xD34D}] ==
               Generic.parse("1:23::def:d34d")

      assert [{0x0001, 0x023, 0x0000, 0x0000, 0x0000, 0x0000, 0x0102, 0x0304}] ==
               Generic.parse("1:23::1.2.3.4")

      assert [{0x0001, 0x023, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0xD34D}] ==
               Generic.parse("1:23::d34d")

      assert [{0x0001, 0x023, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000}] ==
               Generic.parse("1:23::")
    end

    test "IPv6 with :: at position 3" do
      assert [{0x0001, 0x023, 0x0456, 0x0000, 0x000A, 0x00BC, 0x0DEF, 0xD34D}] ==
               Generic.parse("1:23:456::a:bc:def:d34d")

      assert [{0x0001, 0x023, 0x0456, 0x0000, 0x000A, 0x00BC, 0x0102, 0x0304}] ==
               Generic.parse("1:23:456::a:bc:1.2.3.4")

      assert [{0x0001, 0x023, 0x0456, 0x0000, 0x0000, 0x00BC, 0x0DEF, 0xD34D}] ==
               Generic.parse("1:23:456::bc:def:d34d")

      assert [{0x0001, 0x023, 0x0456, 0x0000, 0x0000, 0x00BC, 0x0102, 0x0304}] ==
               Generic.parse("1:23:456::bc:1.2.3.4")

      assert [{0x0001, 0x023, 0x0456, 0x0000, 0x0000, 0x0000, 0x0DEF, 0xD34D}] ==
               Generic.parse("1:23:456::def:d34d")

      assert [{0x0001, 0x023, 0x0456, 0x0000, 0x0000, 0x0000, 0x0102, 0x0304}] ==
               Generic.parse("1:23:456::1.2.3.4")

      assert [{0x0001, 0x023, 0x0456, 0x0000, 0x0000, 0x0000, 0x0000, 0xD34D}] ==
               Generic.parse("1:23:456::d34d")

      assert [{0x0001, 0x023, 0x0456, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000}] ==
               Generic.parse("1:23:456::")
    end

    test "IPv6 with :: at position 4" do
      assert [{0x0001, 0x023, 0x0456, 0x7890, 0x0000, 0x00BC, 0x0DEF, 0xD34D}] ==
               Generic.parse("1:23:456:7890::bc:def:d34d")

      assert [{0x0001, 0x023, 0x0456, 0x7890, 0x0000, 0x00BC, 0x0102, 0x0304}] ==
               Generic.parse("1:23:456:7890::bc:1.2.3.4")

      assert [{0x0001, 0x023, 0x0456, 0x7890, 0x0000, 0x0000, 0x0DEF, 0xD34D}] ==
               Generic.parse("1:23:456:7890::def:d34d")

      assert [{0x0001, 0x023, 0x0456, 0x7890, 0x0000, 0x0000, 0x0102, 0x0304}] ==
               Generic.parse("1:23:456:7890::1.2.3.4")

      assert [{0x0001, 0x023, 0x0456, 0x7890, 0x0000, 0x0000, 0x0000, 0xD34D}] ==
               Generic.parse("1:23:456:7890::d34d")

      assert [{0x0001, 0x023, 0x0456, 0x7890, 0x0000, 0x0000, 0x0000, 0x0000}] ==
               Generic.parse("1:23:456:7890::")
    end

    test "IPv6 with :: at position 5" do
      assert [{0x0001, 0x023, 0x0456, 0x7890, 0x000A, 0x0000, 0x0DEF, 0xD34D}] ==
               Generic.parse("1:23:456:7890:a::def:d34d")

      assert [{0x0001, 0x023, 0x0456, 0x7890, 0x000A, 0x0000, 0x0102, 0x0304}] ==
               Generic.parse("1:23:456:7890:a::1.2.3.4")

      assert [{0x0001, 0x023, 0x0456, 0x7890, 0x000A, 0x0000, 0x0000, 0xD34D}] ==
               Generic.parse("1:23:456:7890:a::d34d")

      assert [{0x0001, 0x023, 0x0456, 0x7890, 0x000A, 0x0000, 0x0000, 0x0000}] ==
               Generic.parse("1:23:456:7890:a::")
    end

    test "IPv6 with :: at position 6" do
      assert [{0x0001, 0x023, 0x0456, 0x7890, 0x000A, 0x00BC, 0x0000, 0xD34D}] ==
               Generic.parse("1:23:456:7890:a:bc::d34d")

      assert [{0x0001, 0x023, 0x0456, 0x7890, 0x000A, 0x00BC, 0x0000, 0x0000}] ==
               Generic.parse("1:23:456:7890:a:bc::")
    end

    test "IPv6 with leading zeroes" do
      assert [{0x0000, 0x0001, 0x0002, 0x0003, 0x0000, 0x0000, 0x0000, 0x0000}] ==
               Generic.parse("0:01:002:0003:0000::")

      assert [{0x000A, 0x001A, 0x002A, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000}] ==
               Generic.parse("0a:01a:002a::")

      assert [{0x00AB, 0x01AB, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000}] ==
               Generic.parse("0ab:01ab::")

      assert [{0x0ABC, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000}] ==
               Generic.parse("0abc::")
    end

    test "IPv6 with mixed case" do
      assert [{0xABCD, 0xABCD, 0xABCD, 0xABCD, 0xABCD, 0xABCD, 0xABCD, 0xABCD}] ==
               Generic.parse("abcd:abcD:abCd:abCD:aBcd:aBcD:aBCd:aBCD")

      assert [{0xABCD, 0xABCD, 0xABCD, 0xABCD, 0xABCD, 0xABCD, 0xABCD, 0xABCD}] ==
               Generic.parse("Abcd:AbcD:AbCd:AbCD:ABcd:ABcD:ABCd:ABCD")
    end

    test "commas with optional whitespace" do
      assert [{127, 0, 0, 1}, {0, 0, 0, 0, 0, 0, 0, 1}] == Generic.parse("127.0.0.1,::1")
      assert [{127, 0, 0, 1}, {0, 0, 0, 0, 0, 0, 0, 1}] == Generic.parse("127.0.0.1,\s::1")
      assert [{127, 0, 0, 1}, {0, 0, 0, 0, 0, 0, 0, 1}] == Generic.parse("127.0.0.1\s,::1")
      assert [{127, 0, 0, 1}, {0, 0, 0, 0, 0, 0, 0, 1}] == Generic.parse("127.0.0.1\s,\s::1")

      assert [{127, 0, 0, 1}, {0, 0, 0, 0, 0, 0, 0, 1}] ==
               Generic.parse("\s\t\s\t127.0.0.1\t\t\s\s,\s\t\t\s::1\t")
    end
  end
end
