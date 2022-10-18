#!/usr/bin/env bash
set -ex

export BASE_PATH="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"
export BUILD_IMAGE="xhaiker/rust-release.action:v1.0.2"

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

if [ "$RELEASE" == "" ]; then
  info "release name not found"
  if [ "$GITHUB_EVENT_NAME" == "release" ]; then
    RELEASE="$(cat "$GITHUB_EVENT_PATH" | jq -r .release.tag_name)"
  elif [ "$GITHUB_EVENT_NAME" == "push" ] && [ "$GITHUB_REF_TYPE" == "tag" ]; then
    RELEASE="$GITHUB_REF_NAME"
  else
    crash "not found release"
  fi
fi

UPLOAD_URL=$(curl -s "${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}/releases/tags/$RELEASE" | jq -r ".upload_url")
if [ "$UPLOAD_URL" == "" ]; then
  crash "not found release: $UPLOAD_URL"
else
  UPLOAD_URL=${UPLOAD_URL/\{?name,label\}/}
  info "found upload url: $UPLOAD_URL"
fi

if [ "$IS_CI_TEST" == "true" ]; then
  info "ci test build the docker images"
  pushd $BASE_PATH/docker
    docker build -t $BUILD_IMAGE .
  popd
fi

export PROJECT_DIR="${PROJECT_DIR:-"$GITHUB_WORKSPACE"}"
cd $PROJECT_DIR

info "build rust binary"
docker run -v $PROJECT_DIR:/build -e SRC_DIR -e RUSTTARGET -e PRE_BUILD -e POST_BUILD $BUILD_IMAGE

NAME="${NAME:-"$(basename $GITHUB_REPOSITORY)"}"
ARCHIVE_SUFFIX="${ARCHIVE_SUFFIX:-$RUSTTARGET}"
ARCHIVE_TYPES="${ARCHIVE_TYPES:-"zip"}"
EXTRA_FILES="${EXTRA_FILES:-""}"
ARCHIVE_NAME="${ARCHIVE_NAME:-"$NAME-$ARCHIVE_SUFFIX"}"
MINIFY=${MINIFY:-"false"}
OUTPUT_DIR="$GITHUB_WORKSPACE/output"
FILE_LIST=""
EXT=""
if [[ "$RUSTTARGET" =~ "windows" ]]; then
  EXT=".exe"
fi

docker_run() {
  docker run -v $PROJECT_DIR:$PROJECT_DIR -v $OUTPUT_DIR:$OUTPUT_DIR --workdir $PWD --entrypoint bash $BUILD_IMAGE -c "$@"
}

mkdir -p "$OUTPUT_DIR"
if [ -z "${EXTRA_FILES+x}" ]; then
  info "EXTRA_FILES not set"
else
  for file in $(echo -n "${EXTRA_FILES}" | tr " " "\n"); do
    info "copy from $PROJECT_DIR/$file to $OUTPUT_DIR/$file"
    mkdir -p "$(dirname $OUTPUT_DIR/$file)"
    cp -f "$PROJECT_DIR/$file" "$OUTPUT_DIR/$file"
    FILE_LIST="$FILE_LIST $file"
  done
fi

BINARIES="$(docker_run 'cargo read-manifest | jq -r ".targets[] | select(.kind[] | contains(\"bin\")) | .name"')"
TARGET_BIN_PATH="target/$RUSTTARGET/release"
if [ "$RUSTTARGET" == "x86_64-unknown-linux-gnu" ]; then
  TARGET_BIN_PATH="target/release"
fi

for BINARY in $BINARIES; do
  BINARY="${BINARY}${EXT}"
  if [ "$MINIFY" == "true" ]; then
    info "Minifying $TARGET_BIN_PATH/$BINARY"
    docker_run "strip $TARGET_BIN_PATH/$BINARY" >&2 || info "Strip failed."
    info "File stripped successfully."
    info "Compressing using UPX..."
    docker_run "upx $TARGET_BIN_PATH/$BINARY" >&2 || info "Compression failed."
    info "File compressed successfully."
  fi
  cp -f "$PROJECT_DIR/$TARGET_BIN_PATH/$BINARY" "$OUTPUT_DIR/$BINARY"
  FILE_LIST="$FILE_LIST $BINARY"
done

pushd $OUTPUT_DIR
  for ARCHIVE_TYPE in $ARCHIVE_TYPES; do

    ARCHIVE_FILE="${ARCHIVE_NAME}.${ARCHIVE_TYPE}"
    info "Packing files: $ARCHIVE_FILE $FILE_LIST"
    case $ARCHIVE_TYPE in
      "zip")
        docker_run "zip -9r $ARCHIVE_FILE ${FILE_LIST}"
      ;;
      "tar"|"tar.gz"|"tar.bz2"|"tar.xz")
        docker_run "tar caf $ARCHIVE_FILE ${FILE_LIST}"
      ;;
      *)
        crash "The given archive type '${ARCHIVE_TYPE}' is not supported"
    esac

    CHECKSUM=$(docker_run "sha256sum \"${ARCHIVE_FILE}\" | cut -d ' ' -f 1")

    curl -X POST \
      --data-binary @"${ARCHIVE_FILE}" \
      -H 'Content-Type: application/octet-stream' \
      -H "Authorization: Bearer ${GITHUB_TOKEN}" \
      "${UPLOAD_URL}?name=${ARCHIVE_FILE}"

    curl -X POST \
      --data "$CHECKSUM ${ARCHIVE_FILE}" \
      -H 'Content-Type: text/plain' \
      -H "Authorization: Bearer ${GITHUB_TOKEN}" \
      "${UPLOAD_URL}?name=${ARCHIVE_FILE}.sha256sum"
  done
popd
