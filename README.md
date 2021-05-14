# Features

**chromium**

- ungoogled
- use ozone

**build**

- debug symbols stripped
- use ccache
- use icecc

# Usage

```
export SCHEDULER_HOST=_YOUR_ICECC_SCHEDULER_HOST_

mkdir -p $PWD/work/ccache $PWD/work/output
echo "work" | tee -a .dockerignore

# Build builder docker image
docker build \
        --tag=chromium-builder \
	.

# Start icecc daemon
docker run \
	--rm -d \
	-e ICECC_MODE=daemon \
	-e USE_SCHEDULER=$SCHEDULER_HOST \
	ghcr.io/jc-lab/icecc:tag-1.3.1-r2

docker run \
        --rm \
        --cap-add CAP_SYS_TTY_CONFIG \
        --net=host \ # for icecc
	-e USE_SCHEDULER=$SCHEDULER_HOST \
        -v $PWD/work/ccache:/home/user/.ccache \
        -v $PWD/work/output:/mnt/output \
        -e RUN_BASH_AFTER_BUILD=n \
        -e OUTPUT_COPY_DIRECTORY=/mnt/output \
        -e PACKAGER_PRIVKEY="/mnt/alpine-packager-keys/_YOUR_ALPINE_PACKAGE_KEY_" \
        -v _YOUR_ALPINE_PACKAGER_KEYS_DIRECTORY_:/mnt/alpine-packager-keys \
	chromium-builder \
	/home/user/build.sh

```


