defmodule SquidWeb.HeadRouter do
  @moduledoc """
  The main purpose of the HeadRouter is to dispatch requests and
  act as a proxy. We highly recommend to not use it in your code.

  """

  def init(opts), do: opts

  def call(_, _opts) do
    raise """
    The HeadRouter is not correctly configured, verify have the
    following code in one of your applications:

        SquidWeb.create_dynamic_router()

    """
  end
end
