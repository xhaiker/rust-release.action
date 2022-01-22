# rust-release.action

[![.github/workflows/test.yml](https://github.com/ihaiker/rust-release.action/actions/workflows/test.yaml/badge.svg)](https://github.com/ihaiker/rust-release.action/actions/workflows/test.yaml)
[![.github/workflows/release.yml](https://github.com/ihaiker/rust-release.action/actions/workflows/release.yaml/badge.svg)](https://github.com/ihaiker/rust-release.action/actions/workflows/release.yaml)

[English Documents](./README.md)

自动发布Rust构建知道到Github release。此action可以直接release、tag和指定release三种模式。

## Inputs 输入参数

### release
指定制品上传release，默认情况下可以从release模式的获取，或者从tag模式获取相应的release name.

### rust_target
**Required** rust target
现在仅仅支持：

- x86_64_apple-darwin
- x86_64-pc-windows-gnu
- x86_64-unknown-linux-gnu

### src_dir
源文件路径，该路径下必须包含Cargo.toml文件。（默认情况为当前项目根目录）

### pre_build
构建前需要执行的脚本

### post_build
构建后需要执行的脚本

### name
项目名称，默认为github repository name.

### archive_name
release 制品名称，默认为：`<name>`-`<archive_suffix>`

### extra_files
制品打包需要额外打入的文件列表
Example: README.md LISENSE

### archive_suffix
制品文件名后半截，例如可以使用 `derawin-x86_64` 替换 `x86_64_apple-darwin`),默认为 `rust_target`

### archive_types
制品文件压缩类型，默认: `zip`, 支持tar的所有压缩类型

### build_options
`cargo build` 额外构建参数

## 简单示例

### **release** 模式示例

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
          - target: x86_64-unknown-linux-gun
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

### **tag** 模式

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
          - target: x86_64-unknown-linux-gun
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
          release: ${{ github.ref }}
          rust_target: ${{ matrix.target }}
          archive_suffix: ${{ matrix.suffix }}
          archive_types: ${{ matrix.archive }}
          extra_files: "README.md README_zh.md LICENSE"
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

```
