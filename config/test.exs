import Config

config :fermo,
  build: Fermo.BuildMock,
  config: Fermo.ConfigMock,
  compilers: Fermo.CompilersMock,
  compilers_slim: Fermo.Compilers.SlimMock,
  ffile: Fermo.FileMock,
  i18n: Fermo.I18nMock,
  localizable: Fermo.LocalizableMock,
  pagination: Fermo.PaginationMock,
  simple: Fermo.SimpleMock,
  sitemap: Fermo.SitemapMock,
  template: Fermo.TemplateMock,
  mix_compiler_manifest: Mix.Fermo.Compiler.ManifestMock,
  file_impl: FileMock,
  mix_utils: Mix.UtilsMock

config :logger, backends: []
