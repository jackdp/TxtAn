TxtAn 1.0 [Win 64-bit] (2021.09.20)
The program counts the lines of text in the given text files.
Jacek Pazera, https://www.pazera-software.com/products/text-analyzer/

Usage: TxtAn64.exe FILES [-ifsl] [-idsl] [-r=[X]] [-s] [-h] [-V] [--github]

Mandatory arguments to long options are mandatory for short options too.
Options are case-sensitive. Options in square brackets are optional.
All parameters that do not start with the "-" or "/" sign are treated as file names/masks.
Options and input files can be placed in any order, but -- (double dash)
indicates the end of parsing options and all subsequent parameters are treated as file names/masks.

FILES - any combination of file names/masks.

Input/output:
  -ifsl, --ignore-file-symlinks  Ignore symbolic links to files.
  -idsl, --ignore-dir-symlinks  Ignore symbolic links to directories.
  -r,    --recurse-depth=[X]    Recurse subdirectories. X - recursion depth (def. X = 50)
  -s,    --silent               Only display a summary (no details).

Info:
  -h, --help     Show this help.
  -V, --version  Show application version.
      --github   Opens source code repository on the GitHub.
