# asks to set an alias everytime you install something with dnf or flatpak
#
ALIAS_FILE="$HOME/.bash_aliases"

# lanuch GUI apps independently from the terminal
__aa_launch() {
	(($#)) || return 0
	setsid -f -- "$@" </dev/null >/dev/null 2>&1
}

_ask_alias(){
	
	local name part alias_value
	local -a command_parts=("$@")

	((${#command_parts[@]})) || return 0

	read -rp "Set alias for '${command_parts[*]}' (empty = pass): " name
	
	#if name = empty, return
	[[ -z $name ]] && return 0
	
	if alias "$name" &>/dev/null ||
		grep -Fq "alias $name=" "$ALIAS_FILE" 2>/dev/null; then
      		echo "Alias '$name' already exists."
       		return 0
  	
	fi


    	alias_value="__aa_launch"
  	  for part in "${command_parts[@]}"; do
       		printf -v part '%q' "$part"
        	alias_value+=" $part"
    	done

    	touch "$ALIAS_FILE" || return 1
    	printf 'alias %s=%q\n' "$name" "$alias_value" >> "$ALIAS_FILE" || return 1

   	# Make the alias available immediately in this shell.
    	alias "$name"="$alias_value"

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


# shellcheck source=/home/eem/.bashrc
[[ -f $ALIAS_FILE ]] && source "$ALIAS_FILE"

