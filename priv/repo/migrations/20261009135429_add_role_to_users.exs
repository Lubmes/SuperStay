defmodule SuperStay.Repo.Migrations.AddRoleToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :role, :string, null: false, default: "support"
    end

    create constraint(:users, :users_role_check, check: "role IN ('support', 'catalog_admin')")
  end
end
