# preview-markdown.vim
# This plugin is no longer to develop. If you want to use, you can fork and improve it yourself
This is vim plugin that can preview markdown in Vim terminal.

![](https://i.imgur.com/ME5HBWP.png)

## Requirements
- [MichaelMure/mdr](https://github.com/MichaelMure/mdr) or specified markdown parser
- Vim 8.1.1401 ~

## Installation
e.g dein.vim

```toml
[[plugins]]
repo = 'skanehira/preview-markdown.vim'
```

## Usage
```vim
:PreviewMarkdown [left|top|right|bottom|tab]
```

## Options
| option                           | description                                               |
|----------------------------------|-----------------------------------------------------------|
| `g:preview_markdown_parser`      | Use specified command to parse markdown, default is `mdr` |
| `g:preview_markdown_auto_update` | Update preview window when write to buffer.               |

## Markdown parser
- [MichaelMure/mdr](https://github.com/MichaelMure/mdr)
- [glow](https://github.com/charmbracelet/glow)
- [mdcat](https://github.com/lunaryorn/mdcat)

## Author
skanehira
