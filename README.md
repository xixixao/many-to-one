# many-to-one

Edit many files as one. Easily search, replace, move code across several files.

## Demo

![demo gif](http://i.giphy.com/l3q2GLBVqAbDTQxIA.gif)

## Install

```bash
npm install -g many-to-one
```

Use:
```bash
many-to-one src/ bundle.js
```

# Features

- Syncs all files into one, obeying the order you supply them in
- Unwatches files you remove from the bundle
- Creates files you add to the bundle that don't exist
- Starts watching files you add to the bundle
- Updates the bundle if you're syncing a folder and add or remove a file in it
- Can mangle the file names in the bundle if having them is annoying (for search/replace)
- Supports any language by using different comment syntax

# Docs

```bash
many-to-one --help
```

```
Usage: many-to-one [options] SOURCE ... TARGET

  SOURCE is a path to a file or directory, or a glob
  TARGET is a path to a file that will consist of the combined contents
    of all the files specified by SOURCEs

The command will keep watching both the SOURCEs and the TARGET and sync
them when either change.

Options:
  --comment, -c  The comment syntax used for file headers.
                                                        [string] [default: "//"]
  --ignore, -i   Don't consider these paths/globs for SOURCE files
  --mangle, -m   Mangle the actual source file names in TARGET's headers.
                                                                       [boolean]
  --token, -t    The end token distinguishing file headers from other comments.
                                             [string] [default: "-------------"]
  --verbose, -v  Log watching status.                                  [boolean]
  --help                                                               [boolean]
```

# Examples

Sync a, b and c to bundle, in order b, c, a.

```bash
many-to-one b.js c.js a.js bundle.js
```

Use different comment syntax for other languages.

```bash
many-to-one -c '#' src/ bundle.coffee
many-to-one -c '--' src/ bundle.hs
```

Use different token to end file headers.
```bash
many-to-one -t '!!!' src/ bundle.js
```

You can use block comments too
```bash
many-to-one -c '/*' -t '*/' src/ bundle.js
```

Exclude some files from syncing.
```bash
many-to-one -i src/vendor.js src/ bundle.js
```
