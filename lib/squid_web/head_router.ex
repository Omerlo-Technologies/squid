defmodule SquidWeb.HeadRouter do
  def init(opts), do: opts

  def call(_, _opts) do
    raise """
    The HeadRouter is not correctly configured, verify have the
    following code in one of your applications:

        SquidWeb.create_dynamic_router()

    """
  end
end
