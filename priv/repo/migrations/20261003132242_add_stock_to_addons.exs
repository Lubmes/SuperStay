defmodule SuperStay.Repo.Migrations.AddStockToAddons do
  use Ecto.Migration

  def change do
    alter table(:addons) do
      add :stock, :integer # null betekent oneindig, een getal betekent maximale voorraad
    end
  end
end
