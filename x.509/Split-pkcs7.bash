#!/bin/bash -xv
zipfile="$1"
name="$(basename -s .zip $zipfile)"
destdir="$2"
tmpdir="$TMPDIR/$name"

if [ -z "$zipfile" ]; then
	printf "Need to specify a zip file.\n"
	exit 1
elif [ "$(file --mime $zipfile | awk -F: '{print $NF}' | awk '{print $1}')" != "application/zip;" ]; then
	printf "Looking for a zipfile.\n"
	exit 1
fi

if [ -z "$destdir" ]; then
	printf "Need to state where you want the files.\n"
	exit 1
fi

if [ ! -d "$tmpdir" ]; then
    mkdir -p $tmpdir
fi

unzip -f $zipfile -d $tmpdir
for pempkcs7 in $(grep -r -e "-----BEGIN PKCS7-----" $tmpdir | awk -F: '{print $1}'); do
	for bcnum in $(openssl pkcs7 -in $pempkcs7 -print_certs | grep -n -e "-----BEGIN CERTIFICATE-----" | awk -F: '{print $1}'); do
		printf "BCNUM:%s\n" "$bcnum"
		for ecnum in $(openssl pkcs7 -in $pempkcs7 -print_certs | egrep -n -e "-----END CERTIFICATE-----" | awk -F: '{print $1}'); do
			openssl pkcs7 -in $pempkcs7 -print_certs 2>&1 | sed '1,3p;3q'
		done
	done
done
