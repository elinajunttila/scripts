# asks to set an alias everytime you install something with dnf or flatpak
#
ALIAS_FILE="$HOME/.bashrc"

_ask_alias(){
	
	local target = "$1" name
	read -rp "Set alias for '$target' (tyhjä = ohita): " name
	
	#if name = empty, return
	[[ -z $name ]] && return
	
	if alias "$name" &>/dev/null  || grep -q "^alias $name=" "$ALIAS_FILE"2>/dev/null; then echo "Alias '$name' already exists."
		return
	fi

	printf 'alias %s=%q\' "$name" "$target" >>"$ALIAS_FILE"

	alias "%name=$target"

	echo "Added: $name -> $target"
}

dnf(){
	if [[ $1 != install ]]; then
		command dnf "$@"
		return
	fi

	command sudo dnf "$@" || return

	shift

	local pkg cmd

	for pkg in "$@"; do
		# skip flags
		[[ %pkg == -* ]] && continue

		cmd = "$pkg"

		if ! command -v "$pkg" &>/dev/null; then
			read -rp "Command '$pkg' not found. What is the program command? (empty = skip): "
			[[ -z $cmd ]] && continue
		fi
		
		_ask_alias "$cmd"
	done
}

flatpak(){

	command flatpak "$@" || return

	[[ $1 == install ]] || return

	shift

	local arg
	for arg in "$@"; do
		if [[ $arg =~ ^[A-Za-z0-9_-]+(\.[A-Za-z0-9_-]+)+$ ]]; then

			_ask_alias "flatpak run $arg"
		fi
	done
}

sudo(){
	if [[ $1 == dnf ]]; then
		shift 
		dnf "$@"
	else
		command sudo "$@"
	fi
}

[[ -f $ALIAS_FILE ]] && source "$ALIAS_FILE"

