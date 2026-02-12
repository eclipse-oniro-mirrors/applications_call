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

#ifndef CALL_RECORDER_UTILS_H
#define CALL_RECORDER_UTILS_H

#include <js_native_api.h>
#include <string>

const int FILE_PATH = 64 * 1024;

class Utils {
public:
    static std::string GetStringValue(napi_env env, napi_value object)
    {
        char *buf = (char *)malloc(FILE_PATH);
        if (buf == nullptr) {
            return "";
        }
        size_t len;
        napi_get_value_string_utf8(env, object, buf, FILE_PATH, &len);
        std::string res = std::string(buf);
        free(buf);
        return res;
    }
};

#endif // CALL_RECORDER_UTILS_H