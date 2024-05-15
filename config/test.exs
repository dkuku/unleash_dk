import Config

config :unleash_fresha,
  unleash_req_options: [
    plug: {Req.Test, Unleash.Client}
  ]
