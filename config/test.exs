import Config

config :fermo,
  build: Fermo.BuildMock,
  compiler: Fermo.CompilerMock,
  i18n: Fermo.I18nMock,
  localizable: Fermo.LocalizableMock,
  pagination: Fermo.PaginationMock,
  simple: Fermo.SimpleMock,
  template: Fermo.TemplateMock,
  mix_compiler_manifest: Mix.Fermo.Compiler.ManifestMock,
  file_impl: FileMock,
  mix_utils: Mix.UtilsMock

config :logger, backends: []
