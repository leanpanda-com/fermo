run_integration = System.get_env("FERMO_RUN_INTEGRATION")
if run_integration do
  ExUnit.start()
else
  ExUnit.start(exclude: [:integration])
end
