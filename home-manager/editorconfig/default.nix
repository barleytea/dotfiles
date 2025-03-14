let

editorConfig = ''
  root = true

  [*]
  charaset = utf-8
  end_of_line = lf
  insert_final_newline = true
  indent_size = 4
  indent_style = space
  trim_trailing_whitespace = true

  [*.md]
  trim_trailing_whitespace = false

  [*.xml]
  indent_size = 2
  indent_style = space

  [*.rb]
  indent_size = 2
  indent_style = space

  [*.js]
  indent_size = 2
  indent_style = space

  [*.yml]
  indent_size = 2
  indent_style = space

  [*.yaml]
  indent_size = 2
  indent_style = space

  [Makefile]
  indent_size = 8
  indent_style = tab

  [*.dart]
  indent_size = 2
  indent_style = space

  [*.lua]
  indent_size = 2
  indent_style = space
'';

in {
  home.file.".editorconfig".text = editorConfig;
}
