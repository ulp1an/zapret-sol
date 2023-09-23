#!/bin/sh

EXEDIR="$(dirname "$0")"
EXEDIR="$(cd "$EXEDIR"; pwd)"
BINS=binaries
BINDIR="$EXEDIR/$BINS"

ZAPRET_BASE="$EXEDIR"
. "$ZAPRET_BASE/common/base.sh"

check_dir()
{
	local dir="$BINDIR/$1"
	local exe="$dir/ip2net"
	local out
	if [ -f "$exe" ]; then
		if [ -x "$exe" ]; then
			# ash and dash try to execute invalid executables as a script. they interpret binary garbage with possible negative consequences
			# bash do not do this
			if exists bash; then
				out=$(echo 0.0.0.0 | bash -c "$exe" 2>/dev/null)
			else
				# find do not use its own shell exec
				# it uses execvp(). in musl libc it does not call shell, in glibc it DOES call /bin/sh
				# that's why prefer bash if present
				out=$(echo 0.0.0.0 | find "$dir" -maxdepth 1 -name ip2net -exec {} \; 2>/dev/null)
			fi
			[ -n "$out" ]
		else
			echo "$exe is not executable. set proper chmod."
			return 1
		fi
	else
		echo "$exe is absent"
		return 2
	fi
}

# link or copy executables. uncomment either ln or cp, comment other
ccp()
{
	local F=$(basename $1)
	[ -d "$EXEDIR/$2" ] || mkdir "$EXEDIR/$2"
	[ -f "$EXEDIR/$2/$F" ] && rm -f "$EXEDIR/$2/$F"
	ln -fs "../$BINS/$1" "$EXEDIR/$2" && echo linking : "../$BINS/$1" =\> "$EXEDIR/$2"
	#cp -f "$BINDIR/$1" "$EXEDIR/$2" && echo copying : "$BINDIR/$1" =\> "$EXEDIR/$2"
}

UNAME=$(uname)
if [ "$UNAME" = "Linux" ]; then
 ARCHLIST="my x86_64 x86 aarch64 arm mips64r2-msb mips32r1-lsb mips32r1-msb ppc"
elif [ "$UNAME" = "Darwin" ]; then
 ARCHLIST="my mac64"
elif [ "$UNAME" = "FreeBSD" ]; then
 ARCHLIST="my freebsd-x64"
else
 ARCHLIST="my"
fi

if [ "$1" = "getarch" ]; then
    for arch in $ARCHLIST
    do
        [ -d "$BINDIR/$arch" ] || continue
        if [ "$arch" = "aarch64" ] || [ "$arch" = "arm" ]; then
            echo "aarch64"
            exit 0
        fi
    done
else
    for arch in $ARCHLIST
    do
        [ -d "$BINDIR/$arch" ] || continue
        if [ "$arch" = "aarch64" ] || [ "$arch" = "arm" ]; then
            echo "aarch64 is OK"
            echo "installing binaries ..."
            ccp $arch/ip2net ip2net
            ccp $arch/mdig mdig
            if [ "$UNAME" = "Linux" ]; then
                ccp $arch/nfqws nfq
            else
                ccp $arch/dvtws nfq
            fi
            ccp $arch/tpws tpws
            exit 0
        else
            echo "$arch is NOT OK"
        fi
    done
    echo "no compatible binaries found"
fi

exit 1
