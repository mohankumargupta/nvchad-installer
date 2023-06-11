#!/usr/bin/env bash 
#set -x
temp_dir=$(mktemp -d)
gum=$temp_dir/gum

find_last_gum_release() { 
  last_gum_release=$(git -c 'versionsort.suffix=-' ls-remote --tags --sort='v:refname' https://github.com/charmbracelet/gum|tail -n1|cut -f2|cut -f1 -d^|cut -f2 -dv)
}

download_gum_binary() {
  curl -sSL https://bina.egoist.dev/charmbracelet/gum > "${temp_dir}/original_gum_script.sh"
  sed -i '1d;$d' "${temp_dir}/original_gum_script.sh" 
  sed -i  '1s/.*/#!\/usr\/bin\/env bash/' "${temp_dir}/original_gum_script.sh"
  sed -i  '$ s/.*//' "${temp_dir}/original_gum_script.sh"
  # shellcheck source=/dev/null
  source  "${temp_dir}/original_gum_script.sh"
  find_last_gum_release
  #wq
  #echo "$last_gum_release"
  uname_os_check
  uname_arch_check
  platform_check
  latest_download_file_name=$(echo "$download_file_name" | sed -r "s/_([^_]*)_/_${last_gum_release}_/")
  #echo "$latest_download_file_name"
  github_artifact_url="https://github.com/charmbracelet/gum/releases/download/v${last_gum_release}/${latest_download_file_name}"
  #echo "$github_artifact_url"
  cd "$temp_dir"
  curl -sSL "$github_artifact_url" > "$latest_download_file_name"
  untar "$latest_download_file_name"
}

is_neovim_installed() {
  command -v nvim >/dev/null
  if [ $? -eq 1 ];
  then
    echo "Neovim not installed. Please install it first."
    exit 1
  fi
}

installed_neovim_version() {
  major=$(nvim --clean --headless -c ':lua print(vim.version()["major"])' -cq 3>&1 1>&2 2>&3)
  minor=$(nvim --clean --headless -c ':lua print(vim.version()["minor"])' -cq 3>&1 1>&2 2>&3)
  patch=$(nvim --clean --headless -c ':lua print(vim.version()["patch"])' -cq 3>&1 1>&2 2>&3)
  echo -e "${major}.${minor}.${patch}"
}

#required_neovim_version() {
#  set -x
#  cd "$temp_dir"
#  curl -sSL https://raw.githubusercontent.com/raspberrypisig/semver-tool/master/src/semver > semver
#  source "$temp_dir/semver"
#  required_version=$(curl -sSL https://nvchad.com/docs/quickstart/install | grep /tag/v|sed -r 's/.*v([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
#  older=$(command_compare $1 $required_version)
#  if [ $older -eq -1 ];
#  then
#    echo "Neovim version too old. Install new version of Neovim."
#    exit 2
#  fi
#}

backup_config_files() {
  config_dir=$(nvim --clean --headless -c ':lua print(vim.fn.stdpath("config"))' -cq 3>&1 1>&2 2>&3)
  data_dir=$(nvim --clean --headless -c ':lua print(vim.fn.stdpath("data"))' -cq 3>&1 1>&2 2>&3)
  if [ -d "$config_dir" ];
  then
     echo -e "${config_dir} needs to be backed up and ${data_dir} will be removed. Continue?"
     delete_dirs=$($gum choose "yes" "no")
     if [ "$delete_dirs" == "yes" ];
     then
       echo Deleting...
       timestamp_now=$(date +%F_%T|sed ''s/://g)
       new_config_dir="${config_dir}-${timestamp_now}"
       set -x
       cp -r "$config_dir" "$new_config_dir"
       rm -rf "${config_dir}"
       rm -rf "${data_dir}"
       set +x
       echo Deleted.
     else
      echo "Wrong answer. Goodbye."
      exit 1
     fi
  else
    echo -e "Data directory ${data_dir} will be removed. Continue?"
    delete_data_dirs=$($gum choose "yes" "no")
    if [ "$delete_data_dirs" == "yes" ];
    then
      echo Deleting...
       set -x
       rm -rf "${data_dir}"
       set +x
       echo Deleted.
    else
      echo "Wrong answer. Goodbye."
    fi
  fi
}

nvchad_installer() {
  #installed_version=$(installed_neovim_version)
  #required_neovim_version "$installed_version"
  echo "Downloading gum binary to temp folder..."
  download_gum_binary
  clear
  $gum style --border normal --margin "1" --padding "1 2" --border-foreground 212 "NVChad Installer Version $($gum style --foreground 212 'v0.0.1')."
  $gum spin --spinner dot --title "Checking if neovim installed..." -- sleep 5
  is_neovim_installed
  backup_config_files
}

nvchad_installer






