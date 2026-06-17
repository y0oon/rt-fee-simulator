#!/usr/bin/env bash
# =============================================================================
# 放射線治療 算定点数シミュレータ ビルドスクリプト
#
# 大本のソース sim-rt-fee-calc.html（シミュレータ本体）から派生版を生成し、
# 版ズレを防ぐ。本体を1つ編集して bash build.sh を実行すれば全部そろう。
#   - sim-rt-fee-calc-offline.html … ダウンロード/オフライン配布版
#                                    （JPシステムフォントfallback＋オフライン注記）
#   - index.html                   … 公開URLのトップページ（本体と同一内容）
#   - rt-fee-simulator.zip         … 配布ZIP（offline版HTML + README.txt）
#
# 使い方:  bash build.sh
# 依存:    perl / zip / unzip（macOS標準）/ bash
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")"

SRC="sim-rt-fee-calc.html"
OFFLINE="sim-rt-fee-calc-offline.html"
INDEX="index.html"
README="README.txt"
ZIP="rt-fee-simulator.zip"

if [[ ! -f "$SRC" ]]; then
  echo "ERROR: source not found: $SRC" >&2
  exit 1
fi

# --- 1) トップページ = 本体の同期コピー --------------------------------------
cp "$SRC" "$INDEX"
echo "[sync]  $INDEX  <-  $SRC"

# --- 2) オフライン版 ----------------------------------------------------------
# (a) タイトルに「（オフライン版）」を付与
# (b) body の font-family に JP システムフォント fallback を追加
#     （Webフォント未接続でも Mac/Win/Linux で美しく表示される）
# 注: sendHeight() は window.parent===window のとき自分宛 postMessage になるだけで
#     無害なため、iframe高さ通知コードは除去せずそのまま残す。
JP_STACK="'Noto Sans JP', 'Hiragino Sans', 'Hiragino Kaku Gothic ProN', Meiryo, 'Yu Gothic', 'Yu Gothic UI', 'Noto Sans CJK JP', sans-serif"

perl -0777 -pe "
  s{<title>放射線治療 算定点数シミュレータ \| RadiTech</title>}
   {<title>放射線治療 算定点数シミュレータ（オフライン版） | RadiTech</title>};
  s{(\n  body \{\n    font-family: )'Noto Sans JP', sans-serif;}
   {\${1}${JP_STACK};};
" "$SRC" > "$OFFLINE"
echo "[build] $OFFLINE  (offline edition)"

# --- 3) 配布用 zip = offline版HTML + README.txt ------------------------------
if [[ ! -f "$README" ]]; then
  echo "ERROR: README not found: $README" >&2
  exit 1
fi
rm -f "$ZIP"
# -j: ディレクトリ階層を含めずファイルのみ格納 / -X: 余計なメタ情報を除去
zip -j -X -q "$ZIP" "$OFFLINE" "$README"
echo "[zip]   $ZIP  <-  $OFFLINE + $README"

# --- 4) 検証: 主要マーカーが各版に存在するか ---------------------------------
echo "--- verify markers ---"
for f in "$SRC" "$INDEX" "$OFFLINE"; do
  a=$(grep -c "applyA400Lock" "$f" || true)
  r=$(grep -c "rowExtras.hidden = true" "$f" || true)
  printf "  %-30s applyA400Lock=%s  rowExtras.hidden=%s\n" "$f" "$a" "$r"
done

# offline 版のタイトル＆フォント fallback が入ったか
grep -q "オフライン版" "$OFFLINE" && echo "  [ok] offline title present"
grep -q "Hiragino Sans" "$OFFLINE" && echo "  [ok] JP system-font fallback present"

# zip の中身が想定どおり2ファイルか
echo "--- verify zip ---"
unzip -l "$ZIP" | sed 's/^/  /'
unzip -l "$ZIP" | grep -q "$OFFLINE" && echo "  [ok] offline html in zip"
unzip -l "$ZIP" | grep -q "$README"  && echo "  [ok] README in zip"

echo "--- build done ---"
