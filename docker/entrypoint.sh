#!/usr/bin/env bash
set -ex

info() {
  echo "::info $*" >&2
}

error() {
  echo "::error $*" >&2
}

crash() {
  error "$*"
  exit 1
}

export SRC_DIR="${SRC_DIR:-""}"

pushd /targets
if [ -f "$RUSTTARGET.sh" ]; then
    info "run $RUSTTARGET.sh"
    source "./${RUSTTARGET}.sh"
fi
popd

pushd /build
  PRE_BUILD="${PRE_BUILD:-""}"
  if [ -f "$PRE_BUILD" ]; then
    info "run post build $PRE_BUILD"
    source "./$PRE_BUILD"
  else
    info "not found PRE_BUILD"
  fi
popd

pushd /build/$SRC_DIR
  if [ "$RUSTTARGET" == "x86_64-unknown-linux-gun" ]; then
    cargo build --bins --release $@
  else
    rustup target add "$RUSTTARGET" >&2
    cargo build --bins --release --target $RUSTTARGET $@
  fi
popd

pushd /build
  POST_BUILD="${POST_BUILD:-""}"
  if [ -f "$POST_BUILD" ]; then
    info "run post build $POST_BUILD"
    "./$POST_BUILD"
  else
    info "not found POST_BUILD"
  fi
popd
