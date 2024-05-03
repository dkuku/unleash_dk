:unleash_fresha
|> Application.load()
|> case do
  :ok -> :unleash_fresha
  {:error, {:already_loaded, :unleash_fresha}} -> :unleash_fresha
end
|> Application.spec(:applications)
|> Enum.each(fn app -> Application.ensure_all_started(app) end)

Logger.configure(level: :warning)
ExUnit.configure(exclude: [skip: true], formatters: [JUnitFormatter, ExUnit.CLIFormatter])
ExUnit.start()
