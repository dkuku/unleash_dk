:unleash_dk
|> Application.load()
|> case do
  :ok -> :unleash_dk
  {:error, {:already_loaded, :unleash_dk}} -> :unleash_dk
end
|> Application.spec(:applications)
|> Enum.each(fn app -> Application.ensure_all_started(app) end)

Logger.configure(level: :warning)
ExUnit.configure(exclude: [skip: true], formatters: [JUnitFormatter, ExUnit.CLIFormatter])
ExUnit.start()
