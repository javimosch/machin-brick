#!/usr/bin/env bash
# machin-brick — build a robot out of bricks, and the walk falls out of it.
#
#   ./build.sh          build bin/brick
#   ./build.sh test     headless assertions, no window
#
# Only two files come from machin-lowpoly: the C boundary and the vector maths.
# The gait in that repo knows what a humanoid is; this one has to work out what
# it is looking at, so none of it is reused — the RULES carry over, the code
# does not. LOWPOLY=/path overrides where it lives.
set -euo pipefail
cd "$(dirname "$0")"
MACHIN="${MACHIN:-machin}"
LOWPOLY="${LOWPOLY:-$HOME/ai/machin-lowpoly}"

if [ ! -f "$LOWPOLY/lp/10_math.src" ]; then
    echo "no machin-lowpoly at $LOWPOLY (set LOWPOLY=/path)" >&2
    exit 1
fi

SHARED=("$LOWPOLY/lp/05_ffi.src" "$LOWPOLY/lp/10_math.src")
BK=(bk/05_win.src bk/10_part.src bk/20_build.src bk/30_derive.src
    bk/40_gait.src bk/50_fight.src bk/60_draw.src bk/70_hud.src)

RL_VER=5.0
RL_TAR="raylib-${RL_VER}_linux_amd64"
RL_DIR="vendor/${RL_TAR}"
for c in "$LOWPOLY/vendor/${RL_TAR}" "$HOME/ai/machin-ressort/vendor/${RL_TAR}" "/tmp/rl/${RL_TAR}"; do
    [ -f "$c/lib/libraylib.a" ] && RL_DIR="$c" && break
done

encode() {
    local out="$1"; shift
    if [ -f "${RL_DIR}/lib/libraylib.a" ]; then
        local INC LIB
        INC="$(cd "${RL_DIR}" && pwd)/include"
        LIB="$(cd "${RL_DIR}" && pwd)/lib"
        "$MACHIN" encode "$@" \
            | sed "s#header \"raylib.h\"#cflags \"-I${INC} -L${LIB}\" header \"raylib.h\"#; \
                   s#link \"raylib\"#link \":libraylib.a\"#" > "$out"
    else
        "$MACHIN" encode "$@" > "$out"
    fi
}

mkdir -p bin
if [ "${1:-}" = "test" ]; then
    encode /tmp/brick_test.mfl "${SHARED[@]}" "${BK[@]}" tests/bk_test.src
    "$MACHIN" build /tmp/brick_test.mfl -o bin/brick-test
    ./bin/brick-test
    exit $?
fi

encode /tmp/brick.mfl "${SHARED[@]}" "${BK[@]}" bk/80_main.src
"$MACHIN" build /tmp/brick.mfl -o bin/brick
echo "built ./bin/brick"
