defmodule ElixirLS.LanguageServer.Gradient do
  alias Gradient.ElixirFmt

  def typecheck(files) do
    gradient_opts = [
      fancy: false,
      ex_colors: [use_colors: false, expression: :black, type: :black, underscored_line: :black],
      use_colors: false,
      expression: :black,
      type: :black,
      underscored_line: :black,
      type_color: :black,
      expr_color: :black,
      underscore_color: :black,
      color: :never,
      no_colors: true,
      fmt_location: :brief
    ]

    files
    |> Map.keys()
    |> Enum.map(fn f ->
      f
      |> String.trim_leading("file://")
      |> Path.relative_to_cwd()
      |> Gradient.type_check_file(gradient_opts)
    end)
    |> List.flatten()
    |> Enum.reduce([], fn
      {:error, errors, opts}, acc ->
        gradient_opts = Keyword.merge(gradient_opts, opts, fn _, _, f -> f end)

        formatted =
          errors
          |> Enum.map(fn {f, m} ->
            [line, message] =
              String.split("#{ElixirFmt.format_error(m, gradient_opts)}", ":", parts: 2)

            %Mix.Task.Compiler.Diagnostic{
              compiler_name: "ElixirLS Gradient",
              file: f,
              position: String.to_integer(line),
              message: String.trim_trailing(message),
              severity: :warning,
              details: ""
            }
          end)

        formatted ++ acc

      _, acc ->
        acc
    end)
  end
end
