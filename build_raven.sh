#!/bin/bash

# Custom Kernel build script

# Constants
green='\033[01;32m'
red='\033[01;31m'
blink_red='\033[05;31m'
cyan='\033[0;36m'
yellow='\033[0;33m'
blue='\033[0;34m'
default='\033[0m'

# Resources
ANDROID_DIR=~/android
KERNEL_DIR=$PWD
IMAGE=$KERNEL_DIR/arch/arm64/boot/Image
#IMAGE=$KERNEL_DIR/arch/arm/boot/zImage for 32 bit architecture
DTBTOOL=$KERNEL_DIR/scripts/dtbTool
TOOLCHAIN=$ANDROID_DIR/toolchains/aarch64-linux-android-4.9/bin
STRIP=$TOOLCHAIN/aarch64-linux-android-strip

#Paths
OUT_DIR=$KERNEL_DIR/out
OUT_ZIP=$KERNEL_DIR/Raven-Releases
MODULE_DIR=$OUT_DIR/system/lib/modules
NEW_OUT=$OUT_DIR/tools

# Kernel Version Info
BASE="-Raven™"
CUR_VER="-2.0"
RAVEN_VER="$BASE$CUR_VER"
 

# Variables

DEFCONFIG="raven_defconfig"
export LOCALVERSION=~`echo $RAVEN_VER`
export CROSS_COMPILE=$TOOLCHAIN/aarch64-linux-android-
export ARCH=arm64
export KBUILD_BUILD_USER="bravonova"
export KBUILD_BUILD_HOST="CM13"

function make_raven {
		echo -e "$green*******************************************************"
		echo "                  Compiling $RAVEN_VER	              "
		echo -e "*****************************************************"
		echo
		make $DEFCONFIG
		make menuconfig
		make -j3
		rm -rf $NEWOUT/Image
		cp -vr $IMAGE $NEW_OUT
		make_dtb
		strip_modules
		make_zip
		housekeeping
		echo -e "$green*******************************************************"
		echo "              Compilation Completed!!              "
		echo -e "*****************************************************$default"
		}
		
function make_clean {
		echo -e "$green***********************************************"
		echo "          Cleaning up object files and other stuff	              "
		echo -e "***********************************************$default"
		make mrproper
		make_raven
	}
		
function make_recompile {
			echo -e "$cyan*******************************************************"
			echo "             Recompiling $RAVEN_VER	              "
			echo -e "*****************************************************"
			make -j2
			rm -rf $NEWOUT/Image
			cp -vr $IMAGE $NEW_OUT
			make_dtb
			strip_modules
			make_zip
			housekeeping
		}
		
function make_dtb {
			echo -e "$blue*******************************************************"
			echo "             		Creating dt.img....	              "
			echo -e "*****************************************************"
			rm -rf $NEWOUT/dt.img
			$DTBTOOL -v -s 2048 -o $NEW_OUT/dt.img -p scripts/dtc/ arch/arm/boot/dts/
		}

function strip_modules {
		rm -rf $MODULE_DIR/*
		mkdir $MODULE_DIR/raven
		find . -path ./build -prune -o -name '*.ko' -print | xargs cp -t $MODULE_DIR/
		cd $MODULE_DIR
		echo -e "$cyan*******************************************************"
		echo "             Stripping modules for size....	              "
		echo -e "*****************************************************"
		$STRIP --strip-unneeded *.ko
		mv $MODULE_DIR/wlan.ko $MODULE_DIR/raven/raven_wlan.ko
		ln -s /system/lib/modules/raven/raven_wlan.ko $MODULE_DIR/wlan.ko
		cd $KERNEL_DIR
		}

function make_zip {
		echo -e "$yellow*******************************************************"
		echo "             		Zipping up....	              "
		echo -e "*****************************************************"
		cd $OUT_DIR
		rm -f '*.zip'
		zip -yr RavenKernel-cm13`echo $CUR_VER`.zip *
		mv RavenKernel-cm13`echo $CUR_VER`.zip $OUT_ZIP
		echo "       Find your zip in Raven-Releases directory"
		echo -e "$default"
		cd $KERNEL_DIR 
		}

function housekeeping {
		echo -e "$green*******************************************************"
		echo "            Cleaning up the mess created...	              "
		echo -e "*****************************************************$default"
		rm -rf $NEW_OUT/Image
		rm -rf $NEW_OUT/dt.img
	}
		

BUILD_START=$(date +"%s")
while read -p " 'Y' to Compile all , 'R' to clean and recompile , 'C' to to do a clean compilation 'N' to exit " choice
do
case "$choice" in
	y|Y)
		make_raven
		break
		;;
	r|R )
		make_recompile
		break
		;;
	c|C )
		make_clean
		break;
		;;
	n|N )
		break
		;;
	* )
		echo
		echo "Are you drunk???"
		echo
		;;
esac
done
BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "$green Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$default"
