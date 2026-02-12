/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "callRecorder.h"
#include "napi/log.h"
#include "sys/stat.h"

#undef LOG_TAG
#define LOG_TAG "CallRecorder"

namespace {
const int32_t SUCCESS = 0;
const int32_t MAX_PERMS = 0777;
const int32_t TARGET_PERMS = 432;
}

CallRecorder::~CallRecorder()
{
}

bool CallRecorder::HandleFilePermission(const std::string &filePath) {
    // 检查文件路径是否为空
    if (filePath.empty()) {
        return false;
    }

    struct stat fileStat {};
    // 获取文件状态
    
    if (stat(filePath.c_str(), &fileStat) != 0) {
        CALL_RECORDER_LOGE("Unable to access file");
        return false;
    }

    // 获取当前文件权限
    mode_t currentPerms = fileStat.st_mode & MAX_PERMS;
    
    // 目标权限
    mode_t targetPerms = static_cast<mode_t>(TARGET_PERMS);
    
    // 检查并修改权限
    if (currentPerms < targetPerms) {
        if (chmod(filePath.c_str(), targetPerms) == SUCCESS) {
            CALL_RECORDER_LOGI("File permission changes %{public}d to %{public}d.", currentPerms, targetPerms);
            return true;
        }
        CALL_RECORDER_LOGE("Failed to modify file permission");
    } else {
        CALL_RECORDER_LOGI("File permission match");
    }
    return false;
}