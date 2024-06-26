#!/bin/bash
#
# This script is used to verify links in markdown docs.
#
# - External links are ignored in CI because these links may go down out of our control.
# - Anchors are ignored
# - Internal links conventions
#   - Must be absolute and start from repo root
#   - Only files in current directory and /media are allowed
# - When a file was moved, all other references are required to be updated for now, even if alias are given
#   - This is recommended because of less redirects and better anchors support.

ROOT=$(unset CDPATH && cd $(dirname "${BASH_SOURCE[0]}")/.. && pwd)
cd $ROOT

yarn add markdown-link-check@3.8.1

VERBOSE=${VERBOSE:-}
CONFIG_TMP=$(mktemp)
ERROR_REPORT=$(mktemp)

trap 'rm -f $CONFIG_TMP $ERROR_REPORT' EXIT

# Check all directories starting with 'v\d.*' and dev.
echo "info: checking links under $ROOT directory..."
sed \
    -e "s#<ROOT>#$ROOT#g" \
    scripts/markdown-link-check.tpl > $CONFIG_TMP
if [ -n "$VERBOSE" ]; then
    cat $CONFIG_TMP
fi
# TODO simplify this if markdown-link-check can process multiple files together
while read -r tasks; do
    for task in $tasks; do
        (
            output=$(yarn markdown-link-check --config "$CONFIG_TMP" "$task" -q)
            if [ $? -ne 0 ]; then
                printf "$output" >> $ERROR_REPORT
            fi
            if [ -n "$VERBOSE" ]; then
                echo "$output"
            fi
        ) &
    done
    wait
done <<<"$(find "." -type f -not -path './node_modules/*' -name '*.md' | xargs -n 10)"

error_files=$(cat $ERROR_REPORT | grep 'FILE: ' | wc -l)
error_output=$(cat $ERROR_REPORT)
echo ""
if [ "$error_files" -gt 0 ]; then
    echo "Link error: $error_files files have invalid links. The faulty files are listed below, please fix the wrong links!"
    echo ""
    echo "=== Hint on how to fix links === "
    echo "Links in TiDB documentation follow a style like '/tidb-binlog/deploy-tidb-binlog.md#服务器要求'. That is, you need to make sure that:"
    echo "1) Links start with a slash; 2) Anchor links are written in a '/dir/xxx.md#anchor-point' style; 3) Links don't start with a version, e.g. '/v3.0/...' is wrong and '/v3.0' should be removed."
    echo ""
    echo "=== ERROR REPORT == ":
    echo "$error_output"
    exit 1
else
    echo "Link check report: All files are ok. No deadlink found!"
fi
