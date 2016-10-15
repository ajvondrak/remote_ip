defmodule RemoteIp.Headers.Generic do
  def parse(header) when is_binary(header) do
    header
    |> split_commas
    |> parse_ips
  end

  defp split_commas(header) do
    header |> String.trim |> String.split(~r/\s*,\s*/)
  end

  defp parse_ips(strings) do
    Enum.reduce(strings, [], fn string, ips ->
      case parse_ip(string) do
        {:ok, ip}         -> [ip | ips]
        {:error, :einval} -> ips
      end
    end) |> Enum.reverse
  end

  defp parse_ip(string) do
    string |> to_char_list |> :inet.parse_strict_address
  end
end
