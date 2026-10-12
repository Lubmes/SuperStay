Configureer voor productie een echte Swoosh-adapter en zet `BOOKING_EMAIL_FROM` op het geverifieerde afzenderadres; Phoenix heeft zelf geen ingebouwde provider die e-mails naar gasten aflevert.
# SuperStay

## Adminaccounts

Publieke registratie is uitgeschakeld. Maak een account aan met een wachtwoord uit je secret manager:

```sh
ADMIN_PASSWORD="$ADMIN_PASSWORD" mix super_stay.create_admin admin@example.com support
ADMIN_PASSWORD="$ADMIN_PASSWORD" mix super_stay.create_admin catalog@example.com catalog_admin
```

Wachtwoorden moeten minimaal 12 tekens bevatten. De rol `catalog_admin` omvat boekingenbeheer en catalogusbeheer; `support` kan alleen boekingen beheren.

## E-mail

Boekingsmails worden via Swoosh verstuurd. In development zijn ze zichtbaar op `/dev/mailbox`; tests gebruiken de Swoosh testadapter. Configureer voor productie een echte Swoosh-adapter en `:booking_email_from`; Phoenix heeft zelf geen ingebouwde provider die e-mails naar gasten aflevert.

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://phoenix.hexdocs.pm/deployment.html).

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://phoenix.hexdocs.pm/overview.html
* Docs: https://phoenix.hexdocs.pm
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
