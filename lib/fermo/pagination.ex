defmodule Fermo.Pagination do
  @enforce_keys [:items, :page, :total_items, :base, :suffix]
  defstruct items: nil,
    page: nil,
    per_page: 10,
    total_items: nil,
    base: nil,
    suffix: "?page=:page",
    first: nil

  @type t() :: %__MODULE__{
    items: Array.t(),
    page: integer(),
    per_page: integer(),
    total_items: integer(),
    base: String.t(),
    suffix: String.t(),
    first: String.t()
  }

  @callback paginate(map(), String.t(), map(), map(), function()) :: map()
  def paginate(config, template, options \\ %{}, context \\ %{}, fun \\ nil) do
    base = options.base
    items = options.items
    per_page = options[:per_page] || 20
    suffix = options[:suffix] || "pages/:page/index.html"
    first = options[:first]
    total_items = length(items)

    paginated = Stream.chunk_every(items, per_page, per_page, [])
    |> Stream.with_index
    |> Enum.map(fn ({chunk, i}) ->
      # index is 1 based
      index = i + 1
      pagination = %__MODULE__{
        items: chunk,
        total_items: total_items,
        page: index,
        per_page: per_page,
        base: base,
        suffix: suffix,
        first: first
      }

      with_pagination = Map.put(context, :pagination, pagination)
      prms = if fun do
        fun.(with_pagination, index)
      else
        with_pagination
      end

      Fermo.Config.page_from(template, page_path(pagination), prms)
    end)

    pages = Map.get(config, :pages, [])
    put_in(config, [:pages], pages ++ paginated)
  end

  def total_pages(%__MODULE__{} = pagination) do
    round((pagination.total_items - 1) / pagination.per_page + 1)
  end

  def paginatable?(%__MODULE__{} = pagination) do
    pagination.page > 1 || pagination.page < total_pages(pagination)
  end

  def prev_page(%__MODULE__{} = pagination) do
    to_page(pagination, pagination.page - 1)
  end

  def next_page(%__MODULE__{} = pagination) do
    to_page(pagination, pagination.page + 1)
  end

  def to_page(%__MODULE__{} = pagination, page) do
    page_path(%__MODULE__{pagination | page: page, items: []})
  end

  def page_path(%__MODULE__{} = pagination) do
    cond do
      pagination.page < 1 -> nil
      pagination.page == 1 && pagination.first ->
        pagination.base <> pagination.first
      pagination.page > total_pages(pagination) -> nil
      true ->
        path = Regex.replace(
          ~r/:([\w_]+)/,
          pagination.suffix,
          fn _, name ->
            num = Map.get(pagination, String.to_atom(name))
            Integer.to_charlist(num) |> List.to_string
          end
        )
        pagination.base <> path
    end
  end
end
