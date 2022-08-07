# rust-release.action

[![.github/workflows/test.yml](https://github.com/ihaiker/rust-release.action/actions/workflows/test.yaml/badge.svg)](https://github.com/ihaiker/rust-release.action/actions/workflows/test.yaml)
[![.github/workflows/release.yml](https://github.com/ihaiker/rust-release.action/actions/workflows/release.yaml/badge.svg)](https://github.com/ihaiker/rust-release.action/actions/workflows/release.yaml)

[中文文档](./README_zh.md)

Automate publishing Rust build artifacts for GitHub releases through GitHub Actions.

This action can work under the conditions of creating release, pushing tag and specifying release.

## Inputs

### release
Github release name (default from release action or tag action)
Can not be specified, if you used  release/tag action.

### rust_target
**Required** rust target.
now only support

- x86_64_apple-darwin
- x86_64-pc-windows-gnu
- x86_64-unknown-linux-gnu

### src_dir
Path to directory containing Cargo.toml (defaults to project root)

### pre_build
Relative path of script to run before building

### post_build
Relative path of script to run after building

### name
the project name (default repository name)

### archive_name

The build artifact name (default `<name>`-`<archive_suffix>`)

### extra_files
List of extra files to include in build
Example: README.md LISENSE

### archive_suffix
This name is the suffix of the build artifact. (default to rust_target)

### archive_types
List of archive types to publish the binaries with, default "zip", supports zip and all tar formats

### build_options
`cargo build` options, more info see `cargo build --help`

## Example usage

### On **release** the project

```yaml
name: release

on:
  release:
    types: [created]

jobs:
  release:
    name: publish ${{ matrix.name }}
    strategy:
      fail-fast: true
      matrix:
        include:
          - target: x86_64-pc-windows-gnu
            suffix: windows-x86_64
            archive: zip
          - target: x86_64-unknown-linux-gnu
            suffix: linux-x86_64
            archive: tar.xz
          - target: x86_64-apple-darwin
            suffix: darwin-x86_64
            archive: tar.gz
    runs-on: ubuntu-latest
    steps:
      - name: Clone test repository
        uses: actions/checkout@v2
      - uses: xhaiker/rust-release.action@v1.0.0
        name: build ${{ matrix.name }}
        with:
          rust_target: ${{ matrix.target }}
          archive_suffix: ${{ matrix.suffix }}
          archive_types: ${{ matrix.archive }}
          extra_files: "README.md README_zh.md LICENSE"
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### On **tag** the project

```yaml
name: release
on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    name: Create Release
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@master
      - name: Create Release
        uses: actions/create-release@latest
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: ${{ github.ref }}
          release_name: ${{ github.ref }}
          draft: false
          prerelease: false

  publish:
    name: publish ${{ matrix.name }}
    needs:
      - release
    strategy:
      fail-fast: true
      matrix:
        include:
          - target: x86_64-pc-windows-gnu
            suffix: windows-x86_64
            archive: zip
          - target: x86_64-unknown-linux-gnu
            suffix: linux-x86_64
            archive: tar.xz
          - target: x86_64-apple-darwin
            suffix: darwin-x86_64
            archive: tar.gz
    runs-on: ubuntu-latest
    steps:
      - name: Clone test repository
        uses: actions/checkout@v2
      - uses: xhaiker/rust-release.action@v1.0.0
        name: build ${{ matrix.name }}
        with:
          release: ${{ github.ref_name }}
          rust_target: ${{ matrix.target }}
          archive_suffix: ${{ matrix.suffix }}
          archive_types: ${{ matrix.archive }}
          extra_files: "README.md README_zh.md LICENSE"
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

```
