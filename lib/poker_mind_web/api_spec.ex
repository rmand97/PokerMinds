defmodule PokerMindWeb.ApiSpec do
  # TODO: missing OpenApiSpex.Components for reusable schemas and authorization
  alias OpenApiSpex.Info
  alias OpenApiSpex.OpenApi
  alias OpenApiSpex.Paths
  alias OpenApiSpex.Server
  alias PokerMindWeb.Endpoint
  alias PokerMindWeb.Router
  @behaviour OpenApi

  # TODO: Add authorization as a security scheme
  @impl OpenApi
  def spec do
    %OpenApi{
      servers: [
        Server.from_endpoint(Endpoint)
      ],
      info: %Info{
        title: "PokerMind",
        version: "0.1.0"
      },
      paths: Paths.from_router(Router)
    }
    |> OpenApiSpex.resolve_schema_modules()
  end
end
