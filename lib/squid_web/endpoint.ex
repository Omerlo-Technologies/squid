defmodule SquidWeb.Endpoint do
  @moduledoc """
  Endpoint helper to import everthing needs as `Phoenix.Endpoint` does.

  Before using this module, you should add the following configuration:

      config :your_tentacle, :squid,
        pubsub_server: YourPubSub,
        endpoint: ShellWeb.Endpoint

  The specified app should be the one that defined generic phoenix things
  such as the `PubSub` server.

  ## Examples

      defmodule TentacleWeb.Endpoint do
        use SquidWeb.Endpoint, otp_app: :your_tentacle
      end

  """

  defmacro __using__(opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)

    quote do
      alias Phoenix.Channel.Server, as: ChannelServer
      alias Phoenix.PubSub

      def subscribe(topic, opts \\ []) when is_binary(topic) do
        PubSub.subscribe(pubsub_server!(), topic, opts)
      end

      def unsubscribe(topic) do
        PubSub.unsubscribe(pubsub_server!(), topic)
      end

      def broadcast_from(from, topic, event, msg) do
        ChannelServer.broadcast_from(pubsub_server!(), from, topic, event, msg)
      end

      def broadcast_from!(from, topic, event, msg) do
        ChannelServer.broadcast_from!(pubsub_server!(), from, topic, event, msg)
      end

      def broadcast(topic, event, msg) do
        ChannelServer.broadcast(pubsub_server!(), topic, event, msg)
      end

      def broadcast!(topic, event, msg) do
        ChannelServer.broadcast!(pubsub_server!(), topic, event, msg)
      end

      def local_broadcast(topic, event, msg) do
        ChannelServer.local_broadcast(pubsub_server!(), topic, event, msg)
      end

      def local_broadcast_from(from, topic, event, msg) do
        ChannelServer.local_broadcast_from(pubsub_server!(), from, topic, event, msg)
      end

      defp pubsub_server! do
        Application.get_env(unquote(otp_app), :squid)[:pubsub_server] ||
          "no :pubsub_server configured for #{inspect(unquote(otp_app))}"
      end

      def config(key, default \\ nil) do
        endpoint = Application.get_env(unquote(otp_app), :squid)[:endpoint]
        endpoint.config(key, default)
      end
    end
  end
end
