# Thesis

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Localhost HTTPS

If the server runs without HTTPS, the browser will block the iframe from loading ([see 3) here](https://canvas.instructure.com/courses/913512/pages/launch-url))

Therefore, we use [Caddy](https://caddyserver.com/) as an HTTPS proxy. The included `Caddyfile` is configured to listen on `https://localhost:3000` and proxy every request to `http://localhost:4000`. Start Caddy by running `caddy` in the project directory.

## Learn more

  * Official website: http://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix
