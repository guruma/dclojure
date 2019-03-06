#!/usr/bin/env bash

set -euo pipefail

# Start
do_usage() {
  echo "Installs the Clojure command line tools."
  echo -e
  echo "Usage:"
  echo "dclojure-linux-install.sh [-p|--prefix <dir>]"
  exit 1
}

default_prefix_dir="/usr/local"
prefix_dir=$default_prefix_dir

## use getopt if the number of params grows
# prefix_param=${1:-}
# prefix_value=${2:-}
# if [[ "$prefix_param" = "-p" || "$prefix_param" = "--prefix" ]]; then
#   if [[ -z "$prefix_value" ]]; then
#     do_usage
#   else
#     prefix_dir="$prefix_value"
#   fi
# fi

echo "Downloading and expanding tar"
curl -O https://github.com/guruma/dclojure/blob/master/dist/linux/dclojure-tools-1.10.0.414.1.tar.gz
tar xzf dclojure-tools-1.10.0.414.1.tar.gz

lib_dir="$prefix_dir/lib"
bin_dir="$prefix_dir/bin"
man_dir="$prefix_dir/share/man/man1"
clojure_lib_dir="$lib_dir/clojure"

echo "Installing libs into $clojure_lib_dir"
install -Dm644 dclojure-tools/deps.edn "$clojure_lib_dir/deps.edn"
install -Dm644 dclojure-tools/example-deps.edn "$clojure_lib_dir/example-deps.edn"
install -Dm644 dclojure-tools/clojure-tools-1.10.0.414.jar "$clojure_lib_dir/libexec/clojure-tools-1.10.0.414.jar"

echo "Installing clojure and clj into $bin_dir"
## sed -i -e 's@PREFIX@'"$clojure_lib_dir"'@g' clojure-tools/clojure
install -Dm755 dclojure-tools/clojure "$bin_dir/clojure"
install -Dm755 dclojure-tools/clj "$bin_dir/clj"

echo "Installing man pages into $man_dir"
install -Dm644 dclojure-tools/clojure.1 "$man_dir/clojure.1"
install -Dm644 dclojure-tools/clj.1 "$man_dir/clj.1"

echo "Removing download"
rm -rf dclojure-tools
rm -rf dclojure-tools-1.10.0.414.tar.gz

echo "Use clj -h for help."
