##########################################
#
# 目标/Purpose:
#   在 Xcode 中为 iPhone + iPad + iPhone Simulator 自动构建一个通用静态库
#   Automatically create a Universal static library for iPhone + iPad + iPhone Simulator from within Xcode
#
# 版本/Version 1.0.0
#
# 近期更新/Latest Change:
# - 2019/09/28 pcjbird 基于原始脚本修改适用于自己项目的脚本
#                      create propriate script for my project base on original script
#
# 作者/Author: 
#   pcjbird - https://pcjbird.github.io
#
# 基于/Based on: 
#   来自Eonil的原始脚本(主要更改:Eonil的脚本将无法在Xcode GUI中工作——它将使您的计算机崩溃)
#   original script from Eonil (main changes: Eonil's script WILL NOT WORK in Xcode GUI - it WILL CRASH YOUR COMPUTER)
#

#set -e表示一旦脚本中有命令的返回值为非0，则脚本立即退出，后续命令不再执行;
set -e
#set -o pipefail表示在管道连接的命令序列中，只要有任何一个命令返回非0值，则整个管道返回非0值，即使最后一个命令返回0.
set -o pipefail

#################[ 用于测试: 有助于在Xcode中解决一些基于构建环境的问题 ]########
#################[ Tests: helps workaround any future bugs in Xcode ]########
#
DEBUG_THIS_SCRIPT="true"

if [ $DEBUG_THIS_SCRIPT = "true" ]
then

#set -x表示显示所有执行命令信息;
set -x
echo "########### 用于测试/TESTS #############"
echo "调试此脚本时使用以下变量 (*注意:它们可能在递归时发生变化)"
echo "Use the following variables when debugging this script; note that they may change on recursions"
echo "BUILD_DIR = $BUILD_DIR"
echo "BUILD_ROOT = $BUILD_ROOT"
echo "CONFIGURATION_BUILD_DIR = $CONFIGURATION_BUILD_DIR"
echo "BUILT_PRODUCTS_DIR = $BUILT_PRODUCTS_DIR"
echo "CONFIGURATION_TEMP_DIR = $CONFIGURATION_TEMP_DIR"
echo "TARGET_BUILD_DIR = $TARGET_BUILD_DIR"
echo "SRCROOT = $SRCROOT"
echo "PROJECT_NAME = $PROJECT_NAME"
echo "TARGET_NAME = $TARGET_NAME"
echo "PRODUCT_NAME = $PRODUCT_NAME"
echo " "
fi

WORKSPACE_NAME="NONE"
while getopts ":w:" opt
do
    case $opt in
        w)
        echo "param:$opt=$OPTARG"
        WORKSPACE_NAME=$OPTARG
        ;;
        ?)
        echo "unexpected param:$opt=$OPTARG";;
    esac
done

#####################[ part 1 ]##################
# First, work out the BASESDK version number (NB: Apple ought to report this, but they hide it)
#    (incidental: searching for substrings in sh is a nightmare! Sob)

SDK_VERSION=$(echo ${SDK_NAME} | grep -o '\d\{1,2\}\.\d\{1,2\}$')

# Next, work out if we're in SIM or DEVICE

if [ ${PLATFORM_NAME} = "iphonesimulator" ]
then
OTHER_SDK_TO_BUILD=iphoneos${SDK_VERSION}
else
OTHER_SDK_TO_BUILD=iphonesimulator${SDK_VERSION}
fi

echo "Xcode has selected SDK: ${PLATFORM_NAME} with version: ${SDK_VERSION} (although back-targetting: ${IPHONEOS_DEPLOYMENT_TARGET})"
echo "...therefore, OTHER_SDK_TO_BUILD = ${OTHER_SDK_TO_BUILD}"
echo " "
#
#####################[ end of part 1 ]##################



#####################[ part 2 ]##################
#
# IF this is the original invocation, invoke WHATEVER other builds are required
#
# Xcode is already building ONE target...
#
# ...but this is a LIBRARY, so Apple is wrong to set it to build just one.
# ...we need to build ALL targets
# ...we MUST NOT re-build the target that is ALREADY being built: Xcode WILL CRASH YOUR COMPUTER if you try this (infinite recursion!)
#
#
# So: build ONLY the missing platforms/configurations.

if [ "true" == ${ALREADYINVOKED:-false} ]
then
echo "warning: I am NOT the root invocation, so I'm NOT going to recurse"
#echo "error: ◉ ${TARGET_NAME}构建失败......"
#exit -1
else
# CRITICAL:
# Prevent infinite recursion (Xcode sucks)
export ALREADYINVOKED="true"

echo "RECURSION: I am the root ... recursing all missing build targets NOW..."


if [ "NONE" == ${WORKSPACE_NAME} ]
then

echo "RECURSION: ...about to invoke: xcodebuild -configuration \"${CONFIGURATION}\" -project \"${PROJECT_NAME}.xcodeproj\" -target \"${TARGET_NAME}\" -sdk \"${OTHER_SDK_TO_BUILD}\" ${ACTION} RUN_CLANG_STATIC_ANALYZER=NO" BUILD_DIR=\"${BUILD_DIR}\" BUILD_ROOT=\"${BUILD_ROOT}\" SYMROOT=\"${SYMROOT}\" OBJROOT="${OBJROOT}/DependentBuilds"

xcodebuild -configuration "${CONFIGURATION}" -project "${PROJECT_NAME}.xcodeproj" -target "${TARGET_NAME}" -sdk "${OTHER_SDK_TO_BUILD}" ${ACTION} RUN_CLANG_STATIC_ANALYZER=NO BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_ROOT}" SYMROOT="${SYMROOT}" OBJROOT="${OBJROOT}/DependentBuilds"

else

echo "RECURSION: ...about to invoke: xcodebuild -configuration \"${CONFIGURATION}\" -workspace \"${WORKSPACE_NAME}.xcworkspace\" -scheme \"${TARGET_NAME}\" -sdk \"${OTHER_SDK_TO_BUILD}\" ${ACTION} RUN_CLANG_STATIC_ANALYZER=NO" BUILD_DIR=\"${BUILD_DIR}\" BUILD_ROOT=\"${BUILD_ROOT}\" SYMROOT=\"${SYMROOT}\" OBJROOT="${OBJROOT}/DependentBuilds"

xcodebuild -configuration "${CONFIGURATION}" -workspace "${WORKSPACE_NAME}.xcworkspace" -scheme "${TARGET_NAME}" -sdk "${OTHER_SDK_TO_BUILD}" ${ACTION} RUN_CLANG_STATIC_ANALYZER=NO BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_ROOT}" SYMROOT="${SYMROOT}" OBJROOT="${OBJROOT}/DependentBuilds"

fi


if [ $? -ne 0 ]; then
    echo "error: ◉ ${TARGET_NAME}构建失败......"
    exit -1
else
    echo "◉ ${TARGET_NAME}构建成功......"
fi

ACTION="build"

#Merge all platform binaries as a fat binary for each configurations.

# Calculate where the (multiple) built files are coming from:
CURRENTCONFIG_DEVICE_DIR=${SYMROOT}/${CONFIGURATION}-iphoneos
CURRENTCONFIG_SIMULATOR_DIR=${SYMROOT}/${CONFIGURATION}-iphonesimulator

echo "Taking device build from: ${CURRENTCONFIG_DEVICE_DIR}"
echo "Taking simulator build from: ${CURRENTCONFIG_SIMULATOR_DIR}"

CREATING_UNIVERSAL_DIR=${SYMROOT}/${CONFIGURATION}-universal
echo "...I will output a universal build to: ${CREATING_UNIVERSAL_DIR}"
if [ ! -d "${CREATING_UNIVERSAL_DIR}" ]
then
    mkdir -p "${CREATING_UNIVERSAL_DIR}"
fi
# ... remove the products of previous runs of this script
#      NB: this directory is ONLY created by this script - it should be safe to delete!

rm -rf "${CREATING_UNIVERSAL_DIR}/${EXECUTABLE_FOLDER_PATH}"
mkdir "${CREATING_UNIVERSAL_DIR}/${EXECUTABLE_FOLDER_PATH}"

#
echo "lipo: for current configuration (${CONFIGURATION}) creating output file: ${CREATING_UNIVERSAL_DIR}/${EXECUTABLE_PATH}"
xcrun -sdk iphoneos lipo -create -output "${CREATING_UNIVERSAL_DIR}/${EXECUTABLE_PATH}" "${CURRENTCONFIG_DEVICE_DIR}/${EXECUTABLE_PATH}" "${CURRENTCONFIG_SIMULATOR_DIR}/${EXECUTABLE_PATH}"

#########
#
# Added: StackOverflow suggestion to also copy "include" files
#    (untested, but should work OK)
#
echo "Fetching headers from ${PUBLIC_HEADERS_FOLDER_PATH}"
echo "  (if you embed your library project in another project, you will need to add"
echo "   a "User Search Headers" build setting of: (NB INCLUDE THE DOUBLE QUOTES BELOW!)"
echo '        "$(TARGET_BUILD_DIR)/usr/local/include/"'
if [ -d "${CURRENTCONFIG_DEVICE_DIR}/${PUBLIC_HEADERS_FOLDER_PATH}" ]
then
mkdir -p "${CREATING_UNIVERSAL_DIR}/${PUBLIC_HEADERS_FOLDER_PATH}"
# * needs to be outside the double quotes?
cp -r "${CURRENTCONFIG_DEVICE_DIR}/${PUBLIC_HEADERS_FOLDER_PATH}"* "${CREATING_UNIVERSAL_DIR}/${EXECUTABLE_FOLDER_PATH}"
fi

if [ -d "${CURRENTCONFIG_DEVICE_DIR}/${MODULES_FOLDER_PATH}" ]
then
mkdir -p "${CREATING_UNIVERSAL_DIR}/${MODULES_FOLDER_PATH}"
# * needs to be outside the double quotes?
cp -r "${CURRENTCONFIG_DEVICE_DIR}/${MODULES_FOLDER_PATH}"* "${CREATING_UNIVERSAL_DIR}/${EXECUTABLE_FOLDER_PATH}"
fi

if [ -f "${CURRENTCONFIG_DEVICE_DIR}/${INFOPLIST_PATH}" ]
then
cp "${CURRENTCONFIG_DEVICE_DIR}/${INFOPLIST_PATH}" "${CREATING_UNIVERSAL_DIR}/${INFOPLIST_PATH}"
fi


#########
# 
#  拷贝Bundle 
#
echo " "
echo "RunScript2:"
echo "Autocopying any bundles into the 'universal' output folder created by RunScript1"
#CREATING_UNIVERSAL_DIR=${SYMROOT}/${CONFIGURATION}-universal
#cp -r "${BUILT_PRODUCTS_DIR}/"*.bundle "${CREATING_UNIVERSAL_DIR}/"

source_bundle_dirs=""
source_bundle_dirs=$((ls -l ${BUILT_PRODUCTS_DIR} | grep '.bundle$' |awk '/^d/ {print $NF}') || $source_bundle_dirs)
if [ ! -n "$source_bundle_dirs" ] ;then
    echo "◉ bundle文件不存在，跳过......"
    exit 0
fi
for i in $source_bundle_dirs
do
    if [ -d "${CREATING_UNIVERSAL_DIR}/${i}" ]
    then
        rm -rf "${CREATING_UNIVERSAL_DIR}/${i}"
    fi
    ditto "${BUILT_PRODUCTS_DIR}/${i}" "${CREATING_UNIVERSAL_DIR}/${i}"
done
#########
# 
#  删除Bundle中的可执行文件 
#
bundle_dirs=$(ls -l ${CREATING_UNIVERSAL_DIR} | grep '.bundle$' |awk '/^d/ {print $NF}')
for i in $bundle_dirs
do
    bundle_executable=${i%.*}
    if [ -f "${CREATING_UNIVERSAL_DIR}/${i}/${bundle_executable}" ]
    then
    echo "remove bundle executable file: ${CREATING_UNIVERSAL_DIR}/${i}/${bundle_executable}"
    rm -rf "${CREATING_UNIVERSAL_DIR}/${i}/${bundle_executable}"
    fi
done
fi
#
#####################[ end of part 2 ]##################