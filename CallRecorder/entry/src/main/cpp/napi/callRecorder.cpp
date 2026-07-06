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
#include <cstdlib>
#include <unistd.h>
#include <cstring>

#undef LOG_TAG
#define LOG_TAG "CallRecorder"

namespace {
const int32_t SUCCESS = 0;
const int32_t MAX_PERMS = 0777;
const int32_t TARGET_PERMS = 432;
const size_t PARENT_DIR_COMPONENT_LEN = 2;
}

// 允许的沙箱目录前缀列表
static const char* g_allowedDirPrefixes[] = {
    "/storage/Users/currentUser/Sounds/CallRecord/",
    "/storage/Users/currentUser/Music/SoundRecorder/"
};
static constexpr size_t ALLOWED_DIR_PREFIX_COUNT = 2;

/**
 * 获取指定索引的前缀长度
 */
static size_t GetPrefixLen(size_t index)
{
    if (index >= ALLOWED_DIR_PREFIX_COUNT) {
        return 0;
    }
    return strlen(g_allowedDirPrefixes[index]);
}

/**
 * 检查路径是否以指定前缀开头
 */
static bool StartsWithPrefix(const std::string& path, size_t prefixIndex)
{
    size_t prefixLen = GetPrefixLen(prefixIndex);
    if (path.length() < prefixLen) {
        return false;
    }
    return path.compare(0, prefixLen, g_allowedDirPrefixes[prefixIndex]) == 0;
}

/**
 * 检查路径中是否存在父目录遍历组件
 * 通过解析路径分量，仅拦截指向父目录的操作（如 "/../" 或开头的 "../"）
 * 合法文件名如 "image..jpg" 或 ".bash_profile" 不会被误判
 * @param filePath 待检查路径
 * @return true=存在遍历 false=安全
 */
static bool HasParentTraversal(const std::string& filePath)
{
    size_t len = filePath.length();
    size_t i = 0;
    
    // 跳过开头可能存在的路径分隔符
    if (len > 0 && filePath[0] == '/') {
        i = 1;
    }
    
    while (i < len) {
        // 找到下一个路径分隔符或字符串结尾
        size_t start = i;
        while (i < len && filePath[i] != '/') {
            i++;
        }
        
        // 提取当前路径分量
        size_t componentLen = i - start;
        if (componentLen == PARENT_DIR_COMPONENT_LEN && start + 1 < len &&
            filePath[start] == '.' && filePath[start + 1] == '.') {
            return true; // 发现 ".." 父目录遍历
        }
        
        // 跳过路径分隔符
        if (i < len && filePath[i] == '/') {
            i++;
        }
    }
    
    return false;
}

/**
 * 校验文件路径安全性
 * 1. 禁止父目录遍历（仅拦截路径分量中的".."）
 * 2. 限制在沙箱目录内（支持多目录前缀）
 * 3. 禁止符号链接指向允许目录外
 * @param filePath 待校验路径
 * @return true=安全  false=不安全
 */
static bool IsPathSecure(const std::string& filePath)
{
    if (filePath.empty()) {
        return false;
    }
    
    // 1. 禁止父目录遍历
    if (HasParentTraversal(filePath)) {
        CALL_RECORDER_LOGE("Path traversal detected");
        return false;
    }
    
    // 2. 路径必须在允许目录前缀列表中的某一个下
    bool prefixMatched = false;
    size_t matchedPrefixLen = 0;
    for (size_t i = 0; i < ALLOWED_DIR_PREFIX_COUNT; i++) {
        if (StartsWithPrefix(filePath, i)) {
            prefixMatched = true;
            matchedPrefixLen = GetPrefixLen(i);
            break;
        }
    }
    if (!prefixMatched) {
        CALL_RECORDER_LOGE("Path out of sandbox: %{public}s", filePath.c_str());
        return false;
    }
    
    // 3. 解析真实路径，检查符号链接是否指向允许目录外
    char resolvedPath[PATH_MAX] = {0};
    if (realpath(filePath.c_str(), resolvedPath) != nullptr) {
        size_t realPathLen = strlen(resolvedPath);
        bool realPathMatched = false;
        for (size_t i = 0; i < ALLOWED_DIR_PREFIX_COUNT; i++) {
            size_t prefixLen = GetPrefixLen(i);
            if (prefixLen == 0) { continue; }
            if (realPathLen >= prefixLen && strncmp(resolvedPath, g_allowedDirPrefixes[i], prefixLen) == 0) {
                realPathMatched = true;
                break;
            }
        }
        if (!realPathMatched) {
            CALL_RECORDER_LOGE("Real path out of sandbox: %{public}s", resolvedPath);
            return false;
        }
    } else {
        // realpath失败：文件不存在或路径无效，拒绝访问
        CALL_RECORDER_LOGE("realpath failed, path may not exist of invalid");
        return false;
    }
    
    return true;
}

CallRecorder::~CallRecorder()
{
}

bool CallRecorder::HandleFilePermission(const std::string &filePath) {
    // 检查文件路径是否为空及路径安全性
    if (filePath.empty()) {
        return false;
    }
    
    // 路径安全校验：防遍历、防越权
    if (!IsPathSecure(filePath)) {
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