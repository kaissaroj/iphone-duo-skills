#!/usr/bin/env bash
# duo_audit.sh — grep a Swift codebase for patterns that break on iPhone Duo.
#
# Usage: duo_audit.sh [path]   (default: current directory)
#
# Each finding is printed as:  [CATEGORY] path:line: matched text
# Categories map to sections of the checklist in ../references/checklist.md.
# This is a first pass — it finds *candidates*. Every hit needs a human/agent
# read to decide whether it's actually a problem in context.

set -u
ROOT="${1:-.}"

if ! command -v grep >/dev/null; then echo "grep not found" >&2; exit 1; fi

# Exclude build products, dependencies, tests of the audit itself.
EXCLUDES=(--exclude-dir=.build --exclude-dir=DerivedData --exclude-dir=Pods --exclude-dir=Carthage --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=.swiftpm)

total=0
SEEN_FILE="$(mktemp)"; trap 'rm -f "$SEEN_FILE"' EXIT
section () { printf '\n== %s ==\n' "$1"; }
scan () {
  # scan CATEGORY REGEX
  local cat="$1" re="$2" out
  out=$(cd "$ROOT" && grep -rnE "${EXCLUDES[@]}" --include='*.swift' -- "$re" . 2>/dev/null | sed "s|^\./||; s/^/[$cat] /")
  [ -n "$out" ] || return 0
  # Drop hits already reported (same file:line) by an earlier regex.
  out=$(printf '%s\n' "$out" | awk -v seen="$SEEN_FILE" '
    BEGIN { while ((getline l < seen) > 0) d[l]=1 }
    NF { split($2,a,":"); k=a[1]":"a[2]; if (!(k in d)) { d[k]=1; print; print k >> seen } }')
  [ -n "$out" ] || return 0
  printf '%s\n' "$out"
  total=$(( total + $(printf '%s\n' "$out" | wc -l | tr -d ' ') ))
}

section "A. Screen references (ambiguous on a two-display device; UIScreen.main to be deprecated)"
scan SCREEN 'UIScreen\.main'
scan SCREEN 'UIScreen\.screens'
scan SCREEN 'NativeBounds|nativeScale'

section "B. Orientation- or idiom-based layout (inner display ignores supported orientations; .phone idiom can be regular/regular)"
scan ORIENT 'interfaceOrientation|statusBarOrientation|UIDevice\.current\.orientation|orientationDidChangeNotification'
scan ORIENT 'isPortrait|isLandscape'
scan IDIOM  'userInterfaceIdiom\s*==|UIDevice\.current\.userInterfaceIdiom|\.userInterfaceIdiom\s*\{'
scan IDIOM  'UI_USER_INTERFACE_IDIOM'

section "C. Fixed widths / device-specific metrics (app must resize for poses, Split View, PiP)"
scan FIXED  'UIScreen\.main\.bounds\.(width|height)'
scan FIXED  '\.frame\(width:\s*[0-9]{3,}'
scan FIXED  'widthAnchor\.constraint\(equalToConstant:\s*[0-9]{3,}'
scan FIXED  'CGSize\(width:\s*[0-9]{3,},\s*height:\s*[0-9]{3,}'
scan FIXED  '(iPhone|iPad|SE|Pro ?Max|Plus|mini)[A-Za-z0-9_]*\s*(==|\?|:)|is(iPhone|iPad)[A-Z]'

section "D. Symmetric safe-area / margin assumptions (Duo insets are asymmetric; bar may be on left or right)"
scan SYMM   'safeAreaInsets\.(left|right|leading|trailing)\s*\*\s*2'
scan SYMM   'safeAreaInsets\.(left|right)\s*\+\s*[a-zA-Z.]*safeAreaInsets\.(left|right)'
scan SYMM   'layoutMargins\.(left|right)\s*\*\s*2'
scan SYMM   'safeAreaInsets\.left\b[^,]*safeAreaInsets\.left\b'

section "E. Custom bars (content in hand-built bars is not considered for the vertical bar)"
scan BAR    '\bUIToolbar\('
scan BAR    '\bUINavigationBar\('
scan BAR    '\bUITabBar\('
scan BAR    'UIBarButtonItem\(barButtonSystemItem:\s*\.flexibleSpace'
scan BAR    'fixedSpaceItemOfWidth|UIBarButtonItem\(barButtonSystemItem:\s*\.fixedSpace'

section "F. Toolbar item content (every symbol item needs a title; counts should be badges; custom overflow menus should merge into the system one)"
scan ITEM   'UIBarButtonItem\(image:[^)]*\)'
scan ITEM   'ToolbarItem[^{]*\{\s*Image\('
scan ITEM   '"ellipsis(\.circle)?"'
scan ITEM   'Menu\s*\{[^}]*\}\s*label:\s*\{\s*(Image|Label)\([^)]*ellipsis'

section "G. Navigation inside layout containers / arrangement misuse"
scan ARR    'ArrangementView\s*\{[^}]*Navigation(Stack|SplitView)'
scan ARR    '(List|ScrollView)\s*\{[^}]*ArrangementView'

section "H. Grid column counts (prefer even columns so the fold lands on a gutter)"
scan GRID   'columns\s*[:=]\s*\[[^]]*GridItem'
scan GRID   'GridItem\(\.fixed|repeating:\s*GridItem[^,]*,\s*count:\s*(1|3|5|7)\b'
scan GRID   'numberOfColumns\s*=\s*(1|3|5|7)\b|columns\s*=\s*(3|5|7)\b'

section "I. Full-screen / orientation locks (still resize on open/close; games must fill every pose)"
scan LOCK   'UIRequiresFullScreen|supportedInterfaceOrientations'
scan LOCK   'UISupportedInterfaceOrientations'

section "J. Centered hero layouts on the inner display (most common thing to straddle the fold — needs a read, not a grep)"
scan CENTER '\.position\(x:\s*[a-zA-Z.]*(width|midX)\s*/\s*2'
scan CENTER 'center\s*=\s*[a-zA-Z.]*view\.center|\.center\s*=\s*CGPoint\(x:\s*[a-zA-Z.]*midX'

section "K. Multi-scene requests (new windows only allowed on the inner display — handle errors)"
scan SCENE  'requestSceneSessionActivation|activateSceneSession'

# SDK / project level
section "L. Project settings"
for pb in $(find "$ROOT" -name 'project.pbxproj' -not -path '*/Pods/*' 2>/dev/null); do
  tgt=$(grep -oE 'IPHONEOS_DEPLOYMENT_TARGET = [0-9.]+' "$pb" | sort -u | tr '\n' ' ')
  echo "[PROJ] $pb: deployment targets: ${tgt:-?}   (iOS 27.1 SDK / Xcode 27.1 required for vertical bars + edge-to-edge)"
done
for plist in $(find "$ROOT" -name 'Info.plist' -not -path '*/Pods/*' -not -path '*/.build/*' 2>/dev/null); do
  if grep -q 'UIApplicationSupportsMultipleScenes' "$plist" 2>/dev/null; then
    echo "[PROJ] $plist: declares UIApplicationSupportsMultipleScenes — verify scene-request error handling (outer display can't create windows)"
  fi
done

printf '\n%d candidate finding(s). Review each against references/checklist.md.\n' "$total"
