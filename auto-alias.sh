# asks to set an alias everytime you install something with dnf or flatpak
#
ALIAS_FILE="$HOME/.bashrc"

# lanuch GUI apps independently from the terminal
__aa_launch() {
	(("$#" > 0)) || return 0
	nohup "$@" </dev/null >/dev/null 2>&1 &
	disown "$!" 2>/dev/null
}

_ask_alias(){
	
	local name quoted_cmd part
	local -a command_parts=("$@")

	((${#command_parts[@]})) || return 0

	read -rp "Set alias for '${command_parts[*]}' (empty = pass): " name
	
	#if name = empty, return
	[[ -z $name ]] && return 0
	
	if alias "$name" &>/dev/null  || grep -q "^alias $name=" "$ALIAS_FILE"2>/dev/null; then echo "Alias '$name' already exists."
		return 0
	fi
	
	quoted_cmd=""
	for part in "${command_parts[@]}"; do
		printf -v part '%q' "$part"
		quoted_cmd+="${quoted_cmd:+ }$part"
	done
	printf "alias %s='__aa_launch $quoted_cmd"

	echo "Added: $name -> ${command_parts[*]}"
}

# for dnf
dnf(){
	if [[ "$1" != "install" ]]; then
		command dnf "$@"
		return $?
	fi

	command dnf "$@" || return $?
	shift

	local pkg cmd
	for pkg in "$@"; do
		# skip flags
		[[ "$pkg" == -* ]] && continue
		[[ "$pkg" == *=* ]] && continue

		cmd="$pkg"
		if ! command -v "$pkg" >/dev/null 2>&1; then
			read -rp "Command for '$pkg' (empty = skip): "
			[[ -z "$cmd" ]] && continue
		fi
		
		_ask_alias "$cmd"
	done
}

# for flatpak
flatpak(){

	command flatpak "$@" || return $?
	[[ "$1" == "install" ]] || return 0
	shift

	local arg
	for arg in "$@"; do
		# skip flags and repo-urls
		[[ "$arg" == -* || "$arg" == *://* ]] && continue
		
		if [[ "$arg" =~ ^[A-Za-z0-9_-]+(\.[A-Za-z0-9_-]+)+$ ]]; then
			_ask_alias "flatpak run $arg"
		fi
	done
}

# if sudo used
sudo() {
	if [[ "$1" == "dnf" ]]; then
		shift 
		dnf "$@"
	else
		command sudo "$@"
	fi
}

# shellcheck source=/home/eem/.bashrc
[[ -f $ALIAS_FILE ]] && source "$ALIAS_FILE"

