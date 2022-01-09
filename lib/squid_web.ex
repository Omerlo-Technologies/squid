defmodule SquidWeb do
  @doc """
  Return registered routers.
  """
  def registered_routers do
    load_tentacles_cfg(:router)
  end

  @doc """
  Return registered menu builders.
  """
  def registered_menu_builders() do
    load_tentacles_cfg(:menu)
  end

  defp load_tentacles_cfg(config_key) do
    func = &{&1, Application.get_env(&1, :squid)[config_key]}

    Application.get_env(:squid, :tentacles, [])
    |> Enum.map(&func.(&1))
    |> Enum.filter(&elem(&1, 1))
  end
end
