#!/usr/bin/env bash
export CC="/opt/osxcross/target/bin/o64-clang"
export CXX="/opt/osxcross/target/bin/o64-clang++"
export LIBZ_SYS_STATIC=1

cat > $HOME/.cargo/config << EOF
[target.x86_64-apple-darwin]
linker = "/opt/osxcross/target/bin/x86_64-apple-darwin14-clang"
ar = "/opt/osxcross/target/bin/x86_64-apple-darwin14-ar"
EOF
