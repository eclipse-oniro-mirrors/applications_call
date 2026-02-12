#!/bin/bash
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
# Perform hot backups of Oracle databases.
# Copyright © Huawei Technologies Co., Ltd. 2023-2024. All rights reserved.
set -ex
echo "HM_SDK_HOME is ${HM_SDK_HOME}"
node -v
npm -v
# 初始化相关路径
PROJECT_PATH="$(pwd -P)"  # 工程目录
TOOLS_INSTALL_DIR="$(pwd -P)"  # commandline-tools安装目录，流水线下载命令行工具的安装路径

# 安装ohpm, 若镜像中已存在ohpm，则无需重新安装
function init_ohpm() {
  # 下载
  cd $TOOLS_INSTALL_DIR
  commandline_version=2.0.1.0
  wget --no-check-certificate -q "" -O ohcommandline-tools-linux.zip
  unzip -oq ohcommandline-tools-linux.zip

  # 初始化
  OHPM_HOME=$TOOLS_INSTALL_DIR/oh-command-line-tools/ohpm
  ${OHPM_HOME}/bin/init
  export PATH=${OHPM_HOME}/bin:${PATH}
  ohpm -v

  # 配置仓库地址
  ohpm config set registry
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
  # 流水线2.0不支持SDK定制，只能放到代码仓，编译时拷贝到SDK。
  cp TempSDKs/@ohos.multimedia.systemSoundManager.d.ts $HM_SDK_HOME/*/openharmony/ets/api
  cp TempSDKs/@ohos.multimedia.media.d.ts $HM_SDK_HOME/*/openharmony/ets/api
  cp TempSDKs/@hms.nearlink.remoteDevice.d.ts $HM_SDK_HOME/*/openharmony/ets/api
  cp TempSDKs/@kit.UIDesignKit.d.ts $HM_SDK_HOME/*/openharmony/ets/api
  cp TempSDKs/@hms.hds.hdsBaseComponent.d.ets $HM_SDK_HOME/*/openharmony/ets/api
  # 从SDK拷贝签名jar包
  cp $HM_SDK_HOME/*/openharmony/toolchains/lib/hap-sign-tool.jar signature/hap-sign-tool.jar

  # 根据业务情况适配local.properties
  cd $PROJECT_PATH
  echo "sdk.dir=${HM_SDK_HOME}" >./local.properties
  echo "nodejs.dir=${NODE_HOME}" >>./local.properties

  # 根据业务情况安装ohpm三方库依赖,
  ohpm_install $PROJECT_PATH

  # 根据业务情况，采用对应的构建命令，可以参考IDE构建日志中的命令
  cd $PROJECT_PATH
  hvigorw -v
  hvigorw clean --no-daemon

  hvigorw --mode module -p module=callui@default -p debuggable=false -p buildMode=release -p ohos-test-coverage=true assembleHap --parallel --incremental --no-daemon --stacktrace
  hvigorw --mode module -p module=callui@ohosTest -p debuggable=false -p ohos-test-coverage=true packageTesting --parallel --incremental --no-daemon --stacktrace

  has_package_dt_pipeline=0
  if [ -e "build/DTPipeline.zip" ]; then
    file_size=$(stat -c%s "build/DTPipeline.zip")
    if [ $file_size -gt 0 ]; then
      echo "DTPipeline.zip is normal"
    else
      has_package_dt_pipeline=1
      rm -rf build/DTPipeline.zip
      echo "DTPipeline.zip size is 0"
    fi
  else
    has_package_dt_pipeline=1
    echo "build/DTPipeline.zip is not exist"
  fi
  if [ $has_package_dt_pipeline -eq 1 ]; then
    pushd build/outputs
    if [ $? -ne 0 ]; then
      echo "build/outputs is not exist"
      exit 1
    fi
    zip -r ../DTPipeline.zip ./*
    popd
  fi
  hvigorw assembleHap --mode module -p product=default -p debuggable=false -p buildMode=release --no-daemon
  cp entry/build/default/outputs/default/callui-default-signed.hap entry/build/default/outputs/default/CallUI.hap
}

function main() {
  local start_time=$(date '+%s')

  # init_ohpm
  build

  local end_time=$(date '+%s')
  local elapsed_time=$(expr $end_time - $start_time)
  echo "build success in ${elapsed_time}s..."
}

main