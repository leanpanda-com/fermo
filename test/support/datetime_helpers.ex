defmodule Fermo.Test.Support.DateTimeHelpers do
  def offset_datetime(erlang_datetime, offset) do
    seconds = :calendar.datetime_to_gregorian_seconds(erlang_datetime)
    :calendar.gregorian_seconds_to_datetime(seconds - offset)
  end
end
