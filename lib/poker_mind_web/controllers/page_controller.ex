defmodule PokerMindWeb.PageController do
  use PokerMindWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
