#!/bin/bash

#et -e

# Cross-compilation list
ARM_ARCH=arm
ARM_CROSS=arm-linux-gnueabi-
ARM64_ARCH=arm64
ARM64_CROSS=aarch64-linux-gnu-
PPC_ARCH=powerpc
PPC_CROSS=powerpc-linux-gnu-

# Record the number of CPU processor to speed-up build
BUILD_CPU_COUNT=`cat /proc/cpuinfo | grep "core id" | wc -l`
BUILD_CPU_COUNT=$(($BUILD_CPU_COUNT-1))
GIT_BRANCH=`git branch | grep "*" | cut -d' ' -f2 | sed -e "s#/#_#g"`
LOG_DIR="00-LTSI-BUILD/$GIT_BRANCH"

create_build_dir()
{
	if [ -d $LOG_DIR ]
	then
		rm -rf $LOG_DIR
	else
		mkdir -p $LOG_DIR
	fi
}

check_crosstool()
{
	printf "Checking cross-toolchain for %s ... \n" $1
	toolchain=`ls -1 /usr/bin/${1}*`
	status=0
	toolname=(ar as gcc cpp gcov ld nm objcopy objdump)

	for tool in `echo ${toolname[*]}`
	do
		isAvail=`echo $toolchain | grep ${1}$tool | wc -l`
		if [ $isAvail -ne 1 ]
		then
			printf "%s%s is not found! Exit ! \n" ${1} $tool
			status=$(($status+1))
		fi
	done
	if [ $status -gt 0 ]
	then
		printf "Tool-chain for %s has PROBLEM!!!\n" ${1}
		exit 1
	fi
}

crosscompile_linux () {
	echo "=============================================="
	echo "Cross-compiling check for ARCH=$1 CROSS_COMPILE=$2"
	echo "=============================================="
	echo "make defconfig building..."
	ARCH=$1 CROSS_COMPILE=$2 make distclean
	ARCH=$1 CROSS_COMPILE=$2 make defconfig
	ARCH=$1 CROSS_COMPILE=$2 make -j ${BUILD_CPU_COUNT} 2> $LOG_DIR/${2}defconfig-build.err
	echo "make allyesconfig building..."
	ARCH=$1 CROSS_COMPILE=$2 make distclean
	ARCH=$1 CROSS_COMPILE=$2 make allyesconfig
	ARCH=$1 CROSS_COMPILE=$2 make -j ${BUILD_CPU_COUNT} 2> $LOG_DIR/${2}allyesconfig-build.err
	echo "make allmodconfig building..."
	ARCH=$1 CROSS_COMPILE=$2 make distclean
	ARCH=$1 CROSS_COMPILE=$2 make allmodconfig
	ARCH=$1 CROSS_COMPILE=$2 make -j ${BUILD_CPU_COUNT} 2> $LOG_DIR/${2}allmodconfig-build.err
}

create_build_dir

check_crosstool ${ARM_CROSS}
crosscompile_linux ${ARM_ARCH} ${ARM_CROSS}

check_crosstool ${ARM64_CROSS}
crosscompile_linux ${ARM64_ARCH} ${ARM64_CROSS}

check_crosstool ${PPC_CROSS}
crosscompile_linux ${PPC_ARCH} ${PPC_CROSS}


