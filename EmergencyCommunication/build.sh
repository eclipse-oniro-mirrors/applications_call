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
echo "OHOS_SDK_HOME is ${OHOS_SDK_HOME}"
echo "OHOS_BASE_SDK_HOME is ${OHOS_BASE_SDK_HOME}"
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
function ohpm_install() {
    cd  $1
    ohpm install
}

# 环境适配
function build() {
    echo 'Current HM_SDK_HOME = ' + $HM_SDK_HOME
    echo 'Current PROJECT_PATH = ' + $PROJECT_PATH
    # 流水线2.0不支持SDK定制，只能放到代码仓，编译时拷贝到SDK。
    # 从SDK拷贝签名jar包
    cp $HM_SDK_HOME/*/openharmony/toolchains/lib/hap-sign-tool.jar sign/hap-sign-tool.jar
    cp TempSDKs/@ohos.telephony.call.d.ts $HM_SDK_HOME/*/openharmony/ets/api
    cp TempSDKs/@ohos.systemTimer.d.ts $HM_SDK_HOME/*/openharmony/ets/api
    cp TempSDKs/@ohos.geoLocationManager.d.ts $HM_SDK_HOME/*/openharmony/ets/api
    cp TempSDKs/@ohos.telephony.radio.d.ts $OHOS_SDK_HOME/*/openharmony/ets/api
    cp TempSDKs/@ohos.telephony.sms.d.ts $OHOS_SDK_HOME/*/openharmony/ets/api
    # 根据业务情况适配local.properties
    cd $PROJECT_PATH
    echo "sdk.dir=${HM_SDK_HOME}"  > ./local.properties
    echo "nodejs.dir=${NODE_HOME}" >> ./local.properties

	# 根据业务情况安装ohpm三方库依赖,
    ohpm_install $PROJECT_PATH
    ohpm_install ${PROJECT_PATH}/entry

   # 如果构建过程报错 ERR_PNPM_OUTDATED_LOCKFILE，需要增加配置：lockfile=false
    cat ${HOME}/.npmrc | grep 'lockfile=false' || echo 'lockfile=false' >> ${HOME}/.npmrc


    cd $PROJECT_PATH/sign
    chmod +x build.sh
    ./build.sh

    # 根据业务情况，采用对应的构建命令，可以参考IDE构建日志中的命令
    cd $PROJECT_PATH

    hvigorw clean --no-daemon
    hvigorw assembleHap --mode module -p product=default -p debuggable=false -p ohos-test-coverage=true --no-daemon
    hvigorw --mode module -p module=entry@ohosTest -p debuggable=false -p ohos-test-coverage=true assembleHap packageTesting --no-daemon --stacktrace
    echo "-----------------handle DTPipeline.zip--------------------"
    has_package_dt_pipeline=0
    if [ -e "build/DTPipeline.zip" ];then
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
    if [ $has_package_dt_pipeline -eq 1 ];then
      pushd build/outputs
      if [ $? -ne 0 ];then
             echo "build/outputs is not exist"
             exit 1
      fi
      zip -r ../DTPipeline.zip ./*
      popd
    fi
    hvigorw assembleHap --mode module -p product=default -p debuggable=false -p buildMode=release
    cp entry/build/default/outputs/default/entry-default-signed.hap entry/build/default/outputs/default/EmergencyCommunication.hap
}

function main() {
  local start_time=$(date '+%s')

  build

  local end_time=$(date '+%s')
  local elapsed_time=$(expr $end_time - $start_time)
  echo "build success in ${elapsed_time}s..."
}

main