#!/bin/bash
main() {
	set -e
	local repo source_path version github_key pkg_name
	repo=$(printenv REPO)
	github_key=$(printenv GITHUB_KEY)
	pkg_name=$(printenv PKG_NAME)
	source_path="$HOME/source"
	prepare_source "https://aur.archlinux.org/$pkg_name.git" "$source_path"
	build "$source_path"
	version=$(generate_version "$source_path/PKGBUILD")
	github_login "$github_key"
	github_check_same_version "$version" "$repo"
	github_create_release "$version" "$source_path" "$repo"
}
prepare_source() {
	local repo=$1
	local source_path=$2
	git clone --depth 1 "$repo" "$source_path"
}
build() {
	local source_path=$1
	local enviroment_vars=$2
	cd "$source_path" || exit 1
	if [[ -z "$enviroment_vars" ]]; then
		makepkg -sc --noconfirm --noprogressbar --skippgpcheck
	else
		env "$enviroment_vars" makepkg -sc --noconfirm --noprogressbar --skippgpcheck
	fi
}
generate_version() {
	local PKGBUILD_path=$1
	local pkgver pkgrel
	PKGBUILD_get_value() {
		local key=$1
		local value
		value=$(grep "$key" "$PKGBUILD_path" | head -1 | cut -d '=' -f2)
		echo "$value"
	}
	pkgver=$(PKGBUILD_get_value "pkgver" | xargs)
	pkgrel=$(PKGBUILD_get_value "pkgrel")
	echo "$pkgver-$pkgrel"
}
github_login() {
	local github_key=$1
	echo "$github_key" | gh auth login --with-token
}
github_create_release() {
	local tag=$1
	local assests_directory=$2
	local repo=$3
	local assests_paths
	cd "$assests_directory" || exit 1
	assests_paths=$(find . -maxdepth 1 -type f -name "*.pkg.tar.zst" | tr '\n' ' ' | xargs)
	gh release create --repo "$repo" "$tag" "$assests_paths"
}
github_check_same_version() {
	local tag=$1
	local repo=$2
	set +e
	gh release view "$tag" --repo "$repo"
	local tag_exists=$?
	set -e
	if [[ $tag_exists = 0 ]]; then
		gh release delete "$tag" --cleanup-tag --repo "$repo"
	fi
}
main
