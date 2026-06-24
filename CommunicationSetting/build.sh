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

set -ex

echo "old NODE_HOME is ${NODE_HOME}"
#打印配置文件传递参数
DT_TASK_FLAG=$1
echo "DT_TASK_FLAG is ${DT_TASK_FLAG}"
# NODE_HOME的环境变量多配置了一个bin目录, 在这里去除掉
[[ "${NODE_HOME}" =~ .*\bin$ ]] && NODE_HOME=${NODE_HOME%\bin*}
echo "new NODE_HOME is ${NODE_HOME}"
echo "HM_SDK_HOME is ${HM_SDK_HOME}"
echo "OHOS_SDK_HOME is ${OHOS_SDK_HOME}"
echo "OHOS_BASE_SDK_HOME is ${OHOS_BASE_SDK_HOME}"
node -v
npm -v

# 初始化相关路径
PROJECT_PATH="`pwd -P`"  # 工程目录
TOOLS_INSTALL_DIR="`pwd -P`"  # commandline-tools安装目录，流水线下载命令行工具的安装路径

if [ "${DT_TASK_FLAG}" == "gradlew_watch" ];then
        #切换CDE2.0格式
        cp ${PROJECT_PATH}/replace_hvigor/* ${PROJECT_PATH}/hvigor
        cp ${PROJECT_PATH}/product/replace_wearable/* ${PROJECT_PATH}/product/wearable
        rm oh-package.json5
        rm oh-package-lock.json5
        rm hvigorfile.ts
        mv replace_oh-package.json5 oh-package.json5
        mv replace_oh-package-lock.json5 oh-package-lock.json5
        mv replace_hvigorfile.ts  hvigorfile.ts
fi

function ohpm_install {
    cd  $1
    ohpm install
}

# 环境适配
function build {
    # 根据业务情况适配local.properties
    cd ${PROJECT_PATH}
    echo "sdk.dir=${HM_SDK_HOME}"  > ./local.properties
    echo "nodejs.dir=${NODE_HOME}" >> ./local.properties

    cp TempSDKs/@ohos.telephony.sim.d.ts $HM_SDK_HOME/*/openharmony/ets/api
	# 根据业务情况安装ohpm三方库依赖,
    ohpm_install "${PROJECT_PATH}"

    cd $PROJECT_PATH/hw_sign

    chmod +x build.sh
    ./build.sh

    # 根据业务情况，采用对应的构建命令，可以参考IDE构建日志中的命令
    cd ${PROJECT_PATH}
    chmod +x hvigorw
    #根据流水线传入参数不同，选择编译不同的模块，提高编译效率
    if [ "${DT_TASK_FLAG}" == "gradlew_watch" ];then
        #编译命令
        hvigorw assembleHap --mode module -p module=wearable_communicationsetting@default -p debuggable=false -p buildMode=release --no-daemon
        cp product/wearable/build/default/outputs/default/wearable_communicationsetting-default-signed.hap product/wearable/build/default/outputs/default/CommunicationSetting.hap
        echo "----------------- 示例：编译第一个模块的测试包--------------------"
        hvigorw --mode module -p module=wearable_communicationsetting@ohosTest -p debuggable=false -p ohos-test-coverage=true assembleHap packageTesting  --parallel --incremental --no-daemon --stacktrace
    else
        hvigorw clean --no-daemon --stacktrace
        hvigorw assembleHap --mode module -p product=default -p debuggable=false -p buildMode=release --no-daemon
        cp entry/build/default/outputs/default/entry-default-signed.hap entry/build/default/outputs/default/CommunicationSetting.hap
        hvigorw --mode module -p module=entry@ohosTest -p debuggable=false -p ohos-test-coverage=true assembleHap packageTesting --parallel --incremental --no-daemon --stacktrace
    fi
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
}

function main {
  local startTime=$(date '+%s')

  build

  local endTime=$(date '+%s')
  local elapsedTime=$(expr $endTime - $startTime)
  echo "build success in ${elapsedTime}s..."
}

main