#/usr/bin/env

helpstr="\
NAME
    generate_setup.sh/setup.sh - handle shell environment setup things

SYNOPSIS
    generate_setup.sh/setup.sh [OPTIONS] [DIRECTORY]

DESCRIPTION
    This script is used for setting up the environment, or for creating code 
    that will setup the environment, for software that's laid out in the 
    standard GNU way -- i.e. directories named \`bin' should be added to the 
    PATH, directories named \`lib' added to LD_LIBRARY_PATH, etc.  Copy this 
    script as-is for a general purpose setup.sh, or use it with options for 
    printing out a setup.sh file or code to be used in modules files (see 
    http://modules.sourceforge.net/).

    DIRECTORY can be used to specify the directory in which to look.  The 
    default is the parent directory of this script's location.  See EXAMPLES 
    below for details.

    This script is aggressive in setting variables, e.g. it adds any 
    directories named \`include' to both CPATH and FPATH.  It's suggested to 
    double check what it does.

    Note that although setup.sh is a more appropriate name for this script, it 
    is NOT named so -- bash's source built-in searches PATH before looking in 
    PWD for files, and this could really mess up people used to doing \`source 
    setup.sh' and not \`source ./setup.sh'.  Furthermore, if you run 
    \`generate_setup.sh DIRECTORY', it only sets up the environment, it does 
    not write out DIRECTORY/setup.sh, as the name may imply.

OPTIONS
    --directory DIRECTORY
        Directory in which to look.  Default is the parent directory of this 
        script's location.

    --max-depth NAME
    generate_setup.sh/setup.sh - handle shell environment setup things

SYNOPSIS
    generate_setup.sh/setup.sh [OPTIONS] [DIRECTORY]

DESCRIPTION
    This script is used for setting up the environment, or for creating code 
    that will setup the environment, for software that's laid out in the 
    standard GNU way -- i.e. directories named \`bin' should be added to the 
    PATH, directories named \`lib' added to LD_LIBRARY_PATH, etc.  Copy this 
    script as-is for a general purpose setup.sh, or use it with options for 
    printing out a setup.sh file or code to be used in modules files (see 
    http://modules.sourceforge.net/).

    DIRECTORY can be used to specify the directory in which to look.  The 
    default is the parent directory of this script's location.  See EXAMPLES 
    below for details.

    This script is aggressive in setting variables, e.g. it adds any 
    directories named \`include' to both CPATH and FPATH.  It's suggested to 
    double check what it does.

    Note that although setup.sh is a more appropriate name for this script, it 
    is NOT named so -- bash's source built-in searches PATH before looking in 
    PWD for files, and this could really mess up people used to doing \`source 
    setup.sh' and not \`source ./setup.sh'.  Furthermore, if you run 
    \`generate_setup.sh DIRECTORY', it only sets up the environment, it does 
    not write out DIRECTORY/setup.sh, as the name may imply.

OPTIONS
    --directory DIRECTORY
        Directory in which to look.  Default is the parent directory of this 
        script's location.

    --max-depth LLEVELS
        Maximum depth at which to look (find' -maxdepth option).  Default is 
        effectively infinite.

    --format FORMAT
        FORMAT values can be \`bash' or \`modules' (see 
        http://modules.sourceforge.net/).  Default is \`bash'.

    --action ACTION
        ACTION values can be \`echo', to just print the code to the screen, or 
        \`eval', to actually evaluate it.  \`eval' only works for \`--format 
        bash'.  Default is \`eval'.
    
    -m, --modules-format
        Legacy.  Shorthand for --format modules --action echo.

    -h, --help
        Print this help.

EXAMPLES
    As-is, this script functions as a normal setup.sh, and it's dynamic:
        install -m 644 \`which generate_setup.sh\` PATH/TO/SOFTWARE/setup.sh
    
    To generate a cleaner but static version, use the following:
        generate_setup.sh --action echo PATH/TO/SOFTWARE > PATH/TO/SOFTWARE/setup.sh
    
    To print code for a modules file, use:
        generate_setup.sh --format modules --action echo PATH/TO/SOFTWARE

REQUIREMENTS
    If no DIRECTORY is given, this requires the BASH_SOURCE variable, something 
    that was introduced around version 3 of bash.

AUTHOR
    John Brunelle
"

directory=''  #the default is set below (we don't want to use BASH_SOURCE unless we have to)
maxdepth=999999999
format='bash'
action='eval'

args=$(getopt -l directory:,max-depth:,format:,action:,modules-format,help -o mh -- "$@")
if [ $? -ne 0 ]; then
	#(getopt will have written the error message)
	return 65 &>/dev/null  #(this script will often be sourced)
	exit 65
fi
eval set -- "$args"
while [ ! -z "$1" ]; do
	case "$1" in
		--directory)
			directory="$2"
			shift
			;;
		--max-depth)
			maxdepth="$2"
			shift
			;;
		--format)
			format="$2"
			shift
			case "$format" in
				bash | modules)
					;;
				*)
					echo "*** ERROR *** [$format] is not a valid --format" >&2
					return 1 &>/dev/null  #(this script will often be sourced)
					exit 1
					;;
			esac
			;;
		--action)
			action="$2"
			shift
			case "$action" in
				echo | eval)
					;;
				*)
					echo "*** ERROR *** [$format] is not a valid --format" >&2
					return 1 &>/dev/null  #(this script will often be sourced)
					exit 1
					;;
			esac
			;;

		-m | --modules-format)
			format=modules
			action=echo
			;;

		-h | --help)
			echo -n "$helpstr"
			return 0 &>/dev/null  #(this script will often be sourced)
			exit 0
			;;
		--) 
			shift
			break
			;;
	esac
	shift
done

directory="$1"
if [ -z "$directory" ]; then
	if [ -z "$BASH_SOURCE" ]; then
		echo "*** ERROR *** your bash is too old -- there's no BASH_SOURCE in the environment" >&2
		return 1 &>/dev/null  #(this script will often be sourced)
		exit 1
	fi
	directory="$(dirname "$(readlink -e "$BASH_SOURCE")")"
else
	directory="$(readlink -e "$directory")"
fi

if [ "$format" = modules ] && [ "$action" = eval ]; then
	echo "*** ERROR *** --action eval only supported with --format bash" >&2
	return 1 &>/dev/null  #(this script will often be sourced)
	exit 1
fi


#---

for pair in \
	bin/PATH \
	sbin/PATH \
	lib/LD_LIBRARY_PATH \
	lib64/LD_LIBRARY_PATH \
	pkgconfig/PKG_CONFIG_PATH \
	include/CPATH \
	include/FPATH \
	info/INFOPATH \
	site-packages/PYTHONPATH \
	man/MANPATH \
; do
	read -r dir var <<< $(echo $pair | tr / ' ')
	for d in $(find "$directory" -maxdepth "$maxdepth" -type d -name "$dir"); do
		case "$format" in
			bash)
				s='export '$var'="'"$d"':$'$var'"'
				;;
			modules)
				s='prepend-path '$var' '"$d"
				;;
		esac
		$action "$s"
	done
done

##adds all directories with executables in them to the PATH
#for d in $(find -L "$(dirname "$(readlink -e "$BASH_SOURCE")")" -name .git -prune -o -name .svn -prune -o \( -type f -a -perm -u=x \) -print | xargs -n 1 dirname | sort | uniq); do
#	echo eval 'export PATH="'"$d"':$PATH"'
#done