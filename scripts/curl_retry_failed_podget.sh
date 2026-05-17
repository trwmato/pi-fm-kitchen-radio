#!/bin/bash

BASE="$HOME/radio"
ERROR_LOG="$BASE/.LOG/errors"
RETRY_LOG="$BASE/logs/curl_retry.log"
FAILED_LOG="$BASE/logs/curl_retry_failed.log"
SERVERLIST="$BASE/config/serverlist"

mkdir -p "$BASE/logs"

[ -f "$ERROR_LOG" ] || exit 0
[ -s "$ERROR_LOG" ] || exit 0

echo "[curl-retry] starting $(date)" >> "$RETRY_LOG"

find_feed_info() {
    media_url="$1"

    while read -r feed_url category feed_name rest; do
        case "$feed_url" in
            ""|\#*) continue ;;
        esac

        case "$category" in
            dailyshow|weeklyshow|news)
                ;;
            *)
                continue
                ;;
        esac

        [ -n "$feed_name" ] || continue

        if curl -Ls "$feed_url" | grep -Fq "$media_url"; then
            echo "$category|$feed_name"
            return 0
        fi
    done < "$SERVERLIST"

    echo "unknown|Curl_Retry_Unknown"
}

grep -Eo 'https?://[^ ]+' "$ERROR_LOG" | sort -u | while IFS= read -r url; do

    url="${url%\"}"
    url="${url%\'}"
    url="${url%,}"
    url="${url%;}"

    case "$url" in
        *.mp3|*.m4a|*.aac|*.ogg|*.opus|*mediaselector*.mp3*)
            ;;
        *)
            echo "[curl-retry] skipping non-media url: $url" >> "$RETRY_LOG"
            continue
            ;;
    esac

    feed_info=$(find_feed_info "$url")
    category="${feed_info%%|*}"
    feed_name="${feed_info#*|}"

    case "$category" in
        dailyshow)
            OUTDIR="$BASE/dailyshow/$feed_name"
            ;;
        weeklyshow)
            OUTDIR="$BASE/weeklyshow/$feed_name"
            ;;
        news)
            OUTDIR="$BASE/news/$feed_name"
            ;;
        *)
            OUTDIR="$BASE/dailyshow/Curl_Retry_Unknown"
            ;;
    esac

    mkdir -p "$OUTDIR"

    filename=$(basename "${url%%\?*}")

    case "$filename" in
        ""|*.rss|redir|*.xml|download)
            filename="curl_retry_$(date +%Y%m%d-%H%M%S)_$RANDOM.mp3"
            ;;
    esac

    out="$OUTDIR/$filename"

    if [ -s "$out" ]; then
        echo "[curl-retry] already exists, skipping: $out" >> "$RETRY_LOG"
        continue
    fi

    echo "[curl-retry] trying $url -> $out" >> "$RETRY_LOG"

    curl -L -A "Mozilla/5.0" \
        --fail \
        --connect-timeout 20 \
        --max-time 1800 \
        -o "$out.part" \
        "$url"

    if [ $? -eq 0 ]; then
        mv "$out.part" "$out"
        echo "[curl-retry] success: $out" >> "$RETRY_LOG"
    else
        rm -f "$out.part"
        echo "[curl-retry] failed: $url" >> "$RETRY_LOG"
        echo "$url" >> "$FAILED_LOG"
    fi

done

cp "$ERROR_LOG" "$BASE/logs/podget_errors_$(date +%Y%m%d-%H%M%S).log"
> "$ERROR_LOG"

echo "[curl-retry] cleared podget error log" >> "$RETRY_LOG"
echo "[curl-retry] finished $(date)" >> "$RETRY_LOG"
