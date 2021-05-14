#!/bin/bash

set -eux

workdir="/home/user/work/apkbuild-chromium"

cd $workdir

[ -n "${SCRIPT_FILE_BEFORE_BUILD:-}" ] && . ${SCRIPT_FILE_BEFORE_BUILD}

mkdir -p $HOME/.abuild
if [ "x${USE_EPHEMERAL_PACKAGER_PRIVKEY:-}" = "xy" ]; then
	PACKAGER=buildtime-ephemeral-key@local
	PACKAGER="$PACKAGER" abuild-keygen -n
	export PACKAGER_PRIVKEY=$(ls ${HOME}/.abuild/${PACKAGER}-*.rsa | head -n 1)
	echo "PACKAGER_PRIVKEY=${PACKAGER_PRIVKEY}" | tee "$HOME/.abuild/abuild.conf"
else
	[ -n "${PACKAGER_PRIVKEY:-}" ] && echo "PACKAGER_PRIVKEY=${PACKAGER_PRIVKEY}" | tee "$HOME/.abuild/abuild.conf"
fi

cd $workdir

abuild -d build check_fakeroot rootpkg

if [ -n "${OUTPUT_COPY_DIRECTORY:-}" ]; then
	cat <<EOF | tee /tmp/copy-output-files.sh
(cd $HOME/work/ && tar -cvf "${OUTPUT_COPY_DIRECTORY}/packages.tar" *)
(cd $HOME/work/apkbuild-chromium/src/chromium-*/out/Release && cp chrome.debug ${OUTPUT_COPY_DIRECTORY}/)
EOF
	chmod +x /tmp/copy-output-files.sh
	$(test -w ${OUTPUT_COPY_DIRECTORY}/ && echo "" || which sudo) /tmp/copy-output-files.sh
fi

[ "x${RUN_BASH_AFTER_BUILD:-}" = "xy" ] && /bin/bash

set -e

[ -n "${SCRIPT_FILE_AFTER_BUILD:-}" ] && . ${SCRIPT_FILE_AFTER_BUILD}


