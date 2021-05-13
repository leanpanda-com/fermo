import Config

config :fermo,
  build: Fermo.BuildMock,
  i18n: Fermo.I18nMock,
  localizable: Fermo.LocalizableMock,
  pagination: Fermo.PaginationMock,
  simple: Fermo.SimpleMock,
  template: Fermo.TemplateMock,
  file_impl: FileMock
