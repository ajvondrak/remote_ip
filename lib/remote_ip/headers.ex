defmodule RemoteIp.Headers do
  def parse(headers, %MapSet{} = allowed) when is_list(headers) do
    headers
    |> allow(allowed)
    |> parse_each
  end

  defp allow(headers, allowed) do
    Enum.filter(headers, fn {header, _} -> MapSet.member?(allowed, header) end)
  end

  defp parse_each(headers) do
    Enum.flat_map(headers, &parse_ips/1)
  end

  defp parse_ips({"forwarded", value}) when is_binary(value) do
    RemoteIp.Headers.Forwarded.parse(value)
  end

  defp parse_ips({header, value}) when is_binary(header) and is_binary(value) do
    RemoteIp.Headers.Generic.parse(value)
  end
end
