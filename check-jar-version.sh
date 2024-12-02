#!/bin/bash
check_jar_version() {
    jar_file="$1"
    version_info=$(unzip -p "$jar_file" $(jar tvf "$jar_file" | grep '\.class$' | head -n 1 | awk '{print $NF}') | od -An -N8 -tx1 | awk '{print $7$8}')
    echo -n "$jar_file: "
    case "$version_info" in
        "0034") echo "Java 8 (52.0)" ;;
        "0035") echo "Java 9 (53.0)" ;;
        "0036") echo "Java 10 (54.0)" ;;
        "0037") echo "Java 11 (55.0)" ;;
        "0038") echo "Java 12 (56.0)" ;;
        "0039") echo "Java 13 (57.0)" ;;
        "003a") echo "Java 14 (58.0)" ;;
        "003b") echo "Java 15 (59.0)" ;;
        "003c") echo "Java 16 (60.0)" ;;
        "003d") echo "Java 17 (61.0)" ;;
        "003e") echo "Java 18 (62.0)" ;;
        "003f") echo "Java 19 (63.0)" ;;
        "0040") echo "Java 20 (64.0)" ;;
        "0041") echo "Java 21 (65.0)" ;;
        *) echo "Unknown Java version (class version: $version_info)" ;;
    esac
}
if [ $# -eq 0 ]; then
    for jar in *.jar; do
        [ -f "$jar" ] || continue
        check_jar_version "$jar"
    done
else
    if [ ! -f "$1" ]; then
        echo "Error: File '$1' not found"
        exit 1
    fi
    check_jar_version "$1"
fi