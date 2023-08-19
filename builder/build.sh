#!/bin/bash
main() {
	set_errexit "on"
	local repo source_path version github_key pkg_name
	repo=$(printenv REPO)
	github_key=$(printenv GITHUB_KEY)
	pkg_name=$(printenv PKG_NAME)
	source_path="/home/builder/source"
	prepare_source "https://aur.archlinux.org/$pkg_name.git" "$source_path"
	build "$source_path" ""
	version=$(generate_version "$source_path/PKGBUILD")
	github_login "$github_key"
	github_check_same_version "$version" "$repo"
}
prepare_source() {
	local repo=$1
	local source_path=$2
	git clone "$repo" "$source_path"
}
build() {
	local source_path=$1
	local enviroment_vars=$2
	cd "$source_path" || exit 1
	if [[ -z "$enviroment_vars" ]]; then
		makepkg -sc --noconfirm --noprogressbar
	else
		env "$enviroment_vars" makepkg -sc --noconfirm --noprogressbar
	fi
}
generate_version() {
	local PKGBUILD_path=$1
	local minor major pkgrel
	PKGBUILD_get_value() {
		local key=$1
		grep "$key" "$PKGBUILD_path" | head -1 | cut -d '=' -f2
	}
	minor=$(PKGBUILD_get_value "_minor" "$PKGBUILD_path")
	major=$(PKGBUILD_get_value "_major" "$PKGBUILD_path")
	pkgrel=$(PKGBUILD_get_value "pkgrel" "$PKGBUILD_path")
	echo "$major.$minor-$pkgrel"
}
github_login() {
	local github_key=$1
	echo "$github_key" | gh auth login --with-token
}
github_create_release() {
	local tag=$1
	local assests_path=$2
	local repo=$3
	gh release create "$tag" "$assests_path" --repo "$repo"
}
github_check_same_version() {
	local tag=$1
	local repo=$2
	local previous_errexit
	previous_errexit=$(set_errexit "off")
	gh release view "$tag" --repo "$repo"
	local tag_exists=$?
	set_errexit "$previous_errexit"
	if [[ $tag_exists = 0 ]]; then
		gh release delete "$tag" --cleanup-tag --repo "$repo"
	fi
}
set_errexit() {
	local state=$1
	local previous_state
	previous_state=$(set -o | grep errexit | sed -e 's/errexit//g' -e 's/ //g' -e 's/\t//g')
	if [[ "$state" = "on" ]]; then
		set -e
	elif [[ "$state" = "off" ]]; then
		set +e
	fi
	echo "$previous_state"
}
main
