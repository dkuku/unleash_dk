import Config

config :unleash_dk,
  unleash_req_options: [
    plug: {Req.Test, Unleash.Client}
  ]
