#!/usr/bin/env bash
#
# zenn-snapshot.sh — Zenn記事メトリクスのスナップショットを取得する
#
# 使い方:
#   ./scripts/zenn-snapshot.sh [YYYY-MM-DD]
#
#   引数省略時はローカル時刻の今日の日付を使う。
#   毎週月曜の実行を想定（週次の伸びを追うため）。
#
# 出力:
#   docs/metrics/zenn/YYYY-MM-DD.tsv  … 全記事のslug/liked/bookmarked/comments/published_at
#   docs/metrics/zenn/followers.tsv   … フォロワー数・累計いいね数の追記ログ（同日実行は上書き）
#
# 差分の見方:
#   diff docs/metrics/zenn/2026-06-30.tsv docs/metrics/zenn/2026-07-07.tsv
#
set -euo pipefail

USERNAME="sora_biz"
DATE="${1:-$(date +%Y-%m-%d)}"
OUT_DIR="docs/metrics/zenn"
ARTICLES_TSV="${OUT_DIR}/${DATE}.tsv"
FOLLOWERS_TSV="${OUT_DIR}/followers.tsv"

mkdir -p "$OUT_DIR"

ARTICLES_JSON="$(curl -s "https://zenn.dev/api/articles?username=${USERNAME}&order=latest&count=100")"

if [ -z "$ARTICLES_JSON" ]; then
  echo "zenn-snapshot: failed to fetch articles from Zenn API (empty response)" >&2
  exit 1
fi

ARTICLES_TSV_BODY="$(node -e '
let data = "";
process.stdin.on("data", d => data += d);
process.stdin.on("end", () => {
  try {
    const json = JSON.parse(data);
    const articles = json.articles || [];
    const lines = articles.map(a => {
      const publishedAt = (a.published_at || "").slice(0, 10);
      return [a.slug, a.liked_count, a.bookmarked_count, a.comments_count, publishedAt].join("\t");
    });
    process.stdout.write(lines.join("\n"));
    if (lines.length > 0) process.stdout.write("\n");
    process.stderr.write(String(articles.length));
  } catch (e) {
    process.stderr.write("PARSE_ERROR");
    process.exit(1);
  }
});
' <<<"$ARTICLES_JSON" 2>/tmp/zenn-snapshot-count.$$)"

ARTICLES_STATUS=$?
ARTICLE_COUNT="$(cat /tmp/zenn-snapshot-count.$$ 2>/dev/null || true)"
rm -f /tmp/zenn-snapshot-count.$$

if [ "$ARTICLES_STATUS" -ne 0 ] || [ "$ARTICLE_COUNT" = "PARSE_ERROR" ]; then
  echo "zenn-snapshot: failed to parse articles JSON from Zenn API" >&2
  exit 1
fi

{
  printf 'slug\tliked\tbookmarked\tcomments\tpublished_at\n'
  printf '%s' "$ARTICLES_TSV_BODY"
} > "$ARTICLES_TSV"

USER_JSON="$(curl -s "https://zenn.dev/api/users/${USERNAME}")"

if [ -z "$USER_JSON" ]; then
  echo "zenn-snapshot: failed to fetch user profile from Zenn API (empty response)" >&2
  exit 1
fi

USER_LINE="$(node -e '
let data = "";
process.stdin.on("data", d => data += d);
process.stdin.on("end", () => {
  try {
    const json = JSON.parse(data);
    const user = json.user;
    if (!user) throw new Error("no user field");
    process.stdout.write(String(user.follower_count) + "\t" + String(user.total_liked_count));
  } catch (e) {
    process.stderr.write("PARSE_ERROR");
    process.exit(1);
  }
});
' <<<"$USER_JSON")" || {
  echo "zenn-snapshot: failed to parse user JSON from Zenn API" >&2
  exit 1
}

if [ ! -f "$FOLLOWERS_TSV" ]; then
  printf 'date\tfollowers\ttotal_liked\n' > "$FOLLOWERS_TSV"
fi

TMP_FOLLOWERS="${FOLLOWERS_TSV}.tmp.$$"
awk -F'\t' -v d="$DATE" '$1 != d' "$FOLLOWERS_TSV" > "$TMP_FOLLOWERS"
printf '%s\t%s\n' "$DATE" "$USER_LINE" >> "$TMP_FOLLOWERS"
mv "$TMP_FOLLOWERS" "$FOLLOWERS_TSV"

echo "$ARTICLES_TSV: ${ARTICLE_COUNT} articles"
