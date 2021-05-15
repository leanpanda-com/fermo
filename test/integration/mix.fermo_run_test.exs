defmodule Mix.FermoRunTest do
  use ExUnit.Case, async: true

  @moduletag :integration

  setup_all do
    root = File.cwd!()
    test_path = Path.join([root, "test", "integration", "test_project"])

    File.cd!(test_path, fn ->
      env = [
        {"BASE_URL", "http://localhost:8080"},
        {"BUILD_ENV", "development"},
        {"MIX_ENV", "dev"}
      ]

      {_clean_output, 0} = System.cmd("git", ["clean", "-ffdx"])
      {_deps_output, 0} = System.cmd("mix", ["deps.get"], env: env, stderr_to_stdout: true)
      {_compile_output, 0} = System.cmd("mix", ["compile"], env: env, stderr_to_stdout: true)
      {_yarn_output, 0} = System.cmd("yarn", [], stderr_to_stdout: true)
      {_build_output, 0} = System.cmd("mix", ["fermo.build"], env: env, stderr_to_stdout: true)
    end)

    build_path = Path.join(test_path, "build")

    on_exit(fn ->
      File.cd!(test_path, fn ->
        {_clean_output, 0} = System.cmd("git", ["clean", "-ffdx"])
      end)
    end)

    %{build_path: build_path}
  end

  test "it builds dynamic pages", context do
    assert File.regular?(Path.join(context.build_path, "index.html"))
  end

  test "it builds simple pages", context do
    assert File.regular?(Path.join(context.build_path, "simple/index.html"))
  end

  test "it builds localized pages", context do
    assert File.regular?(Path.join(context.build_path, "local/index.html"))
    assert File.regular?(Path.join(context.build_path, "it/local/index.html"))
  end

  test "it builds pagination", context do
    assert File.regular?(Path.join(context.build_path, "foos/index.html"))
    assert File.regular?(Path.join(context.build_path, "foos/pages/2.html"))
  end

  test "it builds assets", context do
    assert File.regular?(Path.join(context.build_path, "manifest.json"))
  end

  test "it builds the sitemap", context do
    assert File.regular?(Path.join(context.build_path, "sitemap.xml"))
  end
end
