#!/bin/bash

shopt -s globstar

base_dir="$(dirname "$(realpath -s "$0")")"
firefox_base_dir="/usr/lib64/firefox"
firefox_omni_file="$firefox_base_dir/browser/omni.ja"
firefox_omni_file_backup="${firefox_omni_file}_backup"
firefox_omni_file_zip=$(echo $firefox_omni_file | sed "s|.ja|.zip|g")
firefox_omni_extracted_dir="${firefox_omni_file}_extracted"

function die() {
    message=$@
    say "\033[1;31mError: $message\033[0m"
    exit 255
}

function say() {
    message=$@
    echo -e "$@"
}

function cleanup() {
  rm -rf $firefox_omni_extracted_dir
}

function update_files() {
  sub_dir="$1"
  target_dir="$2"
  item="$3"

  for file in "$base_dir/$sub_dir"/**; do
    if [[ -f $file ]]; then
      file_relative=$(echo $file | sed "s|$base_dir\/$sub_dir\/||g")
      
      if [[ -f $target_dir/$file_relative ]]; then
        say "Updating $item: $file_relative"
        cp -f $file $target_dir/$file_relative
      fi
      
    fi
  done
}

function setup_config() {
  touch "$firefox_base_dir/browser/defaults/preferences/firefox.js"

  update_files "config" "$firefox_base_dir" "config"
}

function setup_omni() {
  unzip -q $firefox_omni_file -d $firefox_omni_extracted_dir

  update_files "omni" "$firefox_omni_extracted_dir" "OMNI"

  cd $firefox_omni_extracted_dir
  zip -q -r $firefox_omni_file_zip *
  mv $firefox_omni_file_zip $firefox_omni_file

  if [[ $SODALITE_FIREFOX_KEEP_OMNI_EXTRACTED == "true" ]]; then
    firefox_omni_extracted_dir_backup="${firefox_omni_extracted_dir}_backup"
    rm -rf $firefox_omni_extracted_dir_backup
    cp -r $firefox_omni_extracted_dir $firefox_omni_extracted_dir_backup
  fi
}

if [[ ! $(id -u) = 0 ]]; then
    die "Unauthorized (are you root?)"
fi

[[ ! -f /usr/lib/fedora-release ]] && die "Not a Fedora install"

touch /usr/lib/test-file &> /dev/null
[[ ! $? -eq 0 ]] && die "No write permissions to OS (is usroverlay enabled?)"
[[ ! -d $firefox_base_dir ]] && die "Unable to find Firefox installation"

if [[ ! -f $firefox_omni_file_backup ]]; then
  say "Creating a backup of OMNI..."
  cp $firefox_omni_file $firefox_omni_file_backup
fi

cleanup
setup_config
setup_omni
cleanup
