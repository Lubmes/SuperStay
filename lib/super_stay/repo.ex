defmodule SuperStay.Repo do
  use Ecto.Repo,
    otp_app: :super_stay,
    adapter: Ecto.Adapters.Postgres
end
