defmodule SuperStayWeb.PageController do
  use SuperStayWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
