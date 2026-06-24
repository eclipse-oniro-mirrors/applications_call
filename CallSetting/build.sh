#!/bin/bash
# Perform hot backups of Oracle databases.
#
# Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
set -ex

echo "old NODE_HOME is ${NODE_HOME}"

# NODE_HOME的环境变量多配置了一个bin目录, 在这里去除掉
[[ "${NODE_HOME}" =~ .*\bin$ ]] && NODE_HOME=${NODE_HOME%\bin*}
echo "new NODE_HOME is ${NODE_HOME}"
echo "HM_SDK_HOME is ${HM_SDK_HOME}"
node -v
npm -v

# 初始化相关路径
PROJECT_PATH="$(pwd -P)"  # 工程目录
TOOLS_INSTALL_DIR="$(pwd -P)"  # commandline-tools安装目录，流水线下载命令行工具的安装路径

# Setup npm
npm config set registry
npm config set @ohos:registry
npm config set strict-ssl false
#npm config set sslVerify false

# 安装ohpm, 若镜像中已存在ohpm，则无需重新安装
function init_ohpm() {
  # 下载
  # cd $TOOLS_INSTALL_DIR
  pwd
  # commandline_version=2.0.1.0
  ohpm_version=5.0.0
  OHPM_HOME=$TOOLS_INSTALL_DIR/ohpm-${ohpm_version}
  mkdir -p ${OHPM_HOME}
  # wget --no-check-certificate -q "" -O ohcommandline-tools-linux.zip
  # unzip -oq ohcommandline-tools-linux.zip

  # 安装ohpm
  cd ${OHPM_HOME}
  pwd
  wget --no-check-certificate -q ""
  unzip -oq ohpm.zip
  export PATH=${OHPM_HOME}/bin:${PATH}
  ohpm -v

  # 配置仓库地址
  ohpm config set registry
  ohpm config set ///:_read_auth "Basic b2hwbV9kb3dubG9hZDppRk5aI3lEZjdOek15TUNzaUZvR3VkWkExQkNFR1g="
  ohpm config set strict_ssl false
}

function ohpm_install() {
  cd $1
  ohpm install
}

# 环境适配
function build() {
  echo 'Current HM_SDK_HOME = ' + $HM_SDK_HOME
  echo 'Current PROJECT_PATH = ' + $PROJECT_PATH
  pwd
  cd $PROJECT_PATH
  pwd
  # 流水线2.0不支持SDK定制，只能放到代码仓，编译时拷贝到SDK。

  cp TempSDKs/@ohos.multimedia.systemSoundManager.d.ts $HM_SDK_HOME/*/openharmony/ets/api
  cp TempSDKs/@ohos.file.photoAccessHelper.d.ts $HM_SDK_HOME/*/openharmony/ets/api
  cp TempSDKs/@ohos.telephony.sim.d.ts $HM_SDK_HOME/*/openharmony/ets/api
  # 从SDK拷贝签名jar包
  ls -al $HM_SDK_HOME/*/openharmony/toolchains/lib/
  cp $HM_SDK_HOME/*/openharmony/toolchains/lib/hap-sign-tool.jar signature/hap-sign-tool.jar
  # 根据业务情况适配local.properties
  cd $PROJECT_PATH
  echo "sdk.dir=${HM_SDK_HOME}" >./local.properties
  echo "nodejs.dir=${NODE_HOME}" >>./local.properties

  # 根据业务情况安装ohpm三方库依赖,
  ohpm_install $PROJECT_PATH
  ohpm_install $PROJECT_PATH/product/default
  ohpm_install $PROJECT_PATH/product/wearable
  ohpm_install $PROJECT_PATH/feature/cust
  ohpm_install $PROJECT_PATH/common

  # 如果构建过程报错 ERR_PNPM_OUTDATED_LOCKFILE，需要增加配置：lockfile=false
  cat ${HOME}/.npmrc | grep 'lockfile=false' || echo 'lockfile=false' >>${HOME}/.npmrc

  cd $PROJECT_PATH/signature
  chmod +x build.sh
  ./build.sh

  # 根据业务情况，采用对应的构建命令，可以参考IDE构建日志中的命令
  cd $PROJECT_PATH

  hvigorw clean --no-daemon
  hvigorw --mode module -p module=default -p debuggable=false -p ohos-test-coverage=true assembleHap --parallel --incremental --no-daemon --stacktrace
  hvigorw --mode module -p module=wearable -p debuggable=false -p ohos-test-coverage=true assembleHap --parallel --incremental --no-daemon --stacktrace
  hvigorw --mode module -p module=common -p debuggable=false -p ohos-test-coverage=true assembleHsp --parallel --incremental --no-daemon --stacktrace
  hvigorw --mode module -p module=default@ohosTest -p debuggable=false -p ohos-test-coverage=true packageTesting --parallel --incremental --no-daemon --stacktrace

  cp -R common/.test/default build/outputs/CallSetting/.test/default_common
  cp common/build/default/outputs/default/common-default-signed.hsp build/outputs/CallSetting/common.hsp

  echo "-----------------handle DTPipeline.zip--------------------"
  has_package_dt_pipeline=0
  if [ -e "build/DTPipeline.zip" ];then
    has_package_dt_pipeline=1
    rm -rf build/DTPipeline.zip
  else
    has_package_dt_pipeline=1
    echo "build/DTPipeline.zip is not exist"
  fi
  if [ $has_package_dt_pipeline -eq 1 ];then
    pushd build/outputs
    if [ $? -ne 0 ];then
      echo "build/outputs is not exist"
      exit 1
    fi
    zip -r ../DTPipeline.zip ./*
    popd
  fi

  hvigorw assembleHsp --mode module -p module=common@default -p product=default -p debuggable=false --no-daemon
  hvigorw assembleHap --mode module -p product=default -p debuggable=false -p buildMode=release --no-daemon
  cp product/default/build/default/outputs/default/default-default-signed.hap product/default/build/default/outputs/default/CallSetting.hap
  cp product/wearable/build/default/outputs/default/wearable-default-signed.hap product/wearable/build/default/outputs/default/CallSettingWearable.hap
  cp product/default/build/default/outputs/default/pack.info product/default/build/default/outputs/default/Pack.info
  mkdir outputs
  cp product/default/build/default/outputs/default/default-default-signed.hap outputs/CallSetting.hap
  cp product/default/build/default/outputs/default/Pack.info outputs/pack.info
  cp product/wearable/build/default/outputs/default/wearable-default-signed.hap outputs/CallSettingWearable.hap
  cp common/build/default/outputs/default/common-default-signed.hsp outputs/common-default-signed.hsp
}

function main() {
  local start_time=$(date '+%s')

  init_ohpm
  build

  local end_time=$(date '+%s')
  local elapsed_time=$(expr $end_time - $start_time)
  echo "build success in ${elapsed_time}s..."
}

main
