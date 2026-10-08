defmodule SuperStay.Repo.Migrations.AddStockToAddons do
  use Ecto.Migration

  def change do
    alter table(:addons) do
      # null betekent oneindig, een getal betekent maximale voorraad
      add :stock, :integer
    end
  end
end
