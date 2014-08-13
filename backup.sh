#!/bin/bash
# backup script with archive rotation and symmetric encryption
# inspired by http://www.abrandao.com/2014/01/23/linux-backup-and-rotate-script/
# 
SELF=`basename $0`
DATESTAMP=`date +"%Y%m%d-%H%M%S"`
TMPDIR="/tmp"
ROTATE_PERIOD=10
PASSPHRASE=

usage() {
	cat << EOF
Usage: ${SELF} [options] source destination

tars and optionally encrypts souce directory and performs
rotation on destination directory.

Options:
    -r              Specify rotation period in days,
                    default is ${ROTATE_PERIOD}.
    -e <passphrase> encrypts tarball with given passphrase.

Examples:
  ${SELF} -r 5 /var/log /backup

EOF
}



while getopts "r:e:" opt; do
	case "$opt" in
		r)
			ROTATE_PERIOD=${OPTARG}
			;;
		e)
			PASSPHRASE=${OPTARG}
			;;
		?)
			usage
			exit 1
			;;
	esac
done

shift $((OPTIND-1))

if [ -z $1 ] || [ -z $2 ]; then
	usage
	exit 1
fi

SRC=$1
SRC_BASENAME=`basename "$SRC"`
SRC_TGZ="${SRC_BASENAME}-${DATESTAMP}.tar.gz"
SRC_TGZ_ENC="${SRC_TGZ}.gpg"
DST=$2

if [ ! -d "$SRC" ]; then
	echo "Error: cannot access source directory: \"${SRC}\""
	exit 1
fi

if [ ! -d "$DST" ]; then
	echo "Error: cannot access destination directory: \"${DST}\""
	exit 1
fi

echo "Starting backup on $DATESTAMP"
echo "  source:      ${SRC}"
echo "  destination: ${DST}"
echo "  backup-file: ${SRC_TGZ}"


# backup and archive
tar cvfz "${TMPDIR}/${SRC_TGZ}" "${SRC}"

# encrypt
if [ ! -z ${PASSPHRASE} ]; then
	gpg -q -c --passphrase "${PASSPHRASE}" -o "${DST}/${SRC_TGZ_ENC}" "${TMPDIR}/${SRC_TGZ}"
	rm "${TMPDIR}/${SRC_TGZ}"
else
	mv "${TMPDIR}/${SRC_TGZ}" "${DST}"
fi

# rotate backups
find $DST -mtime +${ROTATE_PERIOD} -type f -exec rm {} \;

