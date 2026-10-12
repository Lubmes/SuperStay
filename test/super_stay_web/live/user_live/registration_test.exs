defmodule SuperStayWeb.UserLive.RegistrationTest do
  use ExUnit.Case, async: true

  test "public account registration is not routed" do
    refute Enum.any?(Phoenix.Router.routes(SuperStayWeb.Router), fn route ->
             route.path == "/users/register"
           end)
  end
end
