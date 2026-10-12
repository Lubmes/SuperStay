defmodule Mix.Tasks.SuperStay.CreateAdmin do
  use Mix.Task

  @shortdoc "Creates a SuperStay admin account"

  @impl Mix.Task
  def run([email, role]) when role in ["support", "catalog_admin"] do
    password =
      System.get_env("ADMIN_PASSWORD") || Mix.raise("Set ADMIN_PASSWORD in the environment.")

    Mix.Task.run("app.start")

    case SuperStay.Accounts.create_admin_user(%{
           "email" => email,
           "password" => password,
           "role" => role
         }) do
      {:ok, user} ->
        Mix.shell().info("Created #{user.role} account for #{user.email}.")

      {:error, changeset} ->
        errors = Ecto.Changeset.traverse_errors(changeset, fn {message, _opts} -> message end)
        Mix.raise("Could not create admin account: #{inspect(errors)}")
    end
  end

  def run(_args) do
    Mix.raise("Usage: ADMIN_PASSWORD=... mix super_stay.create_admin EMAIL support|catalog_admin")
  end
end
