#!/bin/sh
# Build a curses-enabled aalib 1.4rc5 with bb fixes:
#   - curses getsize via getmaxyx() (no 80-col / private-field access)
#   - bold / dim / reverse attributes via termattrs
#   - per-frame "synchronized output" (DEC 2026) so frames present atomically
#     and don't tear / flicker.
# Usage: ./build-aalib.sh [srcdir]   (srcdir = extracted aalib-1.4.0 tree,
#        default: ./aalib-1.4.0 next to this script's parent, i.e. the repo root)
set -e
# absolute path to this script's directory (so the fix patch below resolves
# even after the "(cd "$AA")" — a relative path would break there)
SCRIPTDIR=$(cd "$(dirname "$0")" && pwd)
AA="${1:-$(cd "$SCRIPTDIR/.." && pwd)/aalib-1.4.0}"
NC=$(brew --prefix ncurses)

# 1. upstream/Homebrew modernization patch (opaque ncurses, etc.)
#    https://raw.githubusercontent.com/Homebrew/formula-patches/4cd6785/aalib/1.4rc5.patch
[ -f "$AA/.hb-patched" ] || {
    curl -sL -o /tmp/aalib-hb.patch \
      https://raw.githubusercontent.com/Homebrew/formula-patches/4cd6785/aalib/1.4rc5.patch
    (cd "$AA" && patch -p1 < /tmp/aalib-hb.patch && touch .hb-patched)
}

# 2. this repo's fix: getmaxyx size detection + 2026 frame sync
(cd "$AA" && patch -p1 < "$SCRIPTDIR/aalib-curses-fix.patch")

# 3. configure with the ncurses curses driver (no X)
(cd "$AA" && CFLAGS="-std=gnu89 -O2" ./configure \
    --with-ncurses="$NC" --with-curses-driver=yes --without-x)

# 4. build
(cd "$AA" && make)

echo "done: $AA/src/.libs/libaa.a  (headers: $AA/src)"
echo "link bb with:  -L$AA/src/.libs -laa -L$NC/lib -lncurses"
