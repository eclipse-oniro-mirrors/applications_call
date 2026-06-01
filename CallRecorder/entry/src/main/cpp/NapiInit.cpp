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

#include "napi/callRecorder.h"
#include "napi/utils.h"
#include "napi/log.h"
#include "napi/native_api.h"


static napi_value HandleFilePermsNapi(napi_env env, napi_callback_info info) {

    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    // 校验参数数量
    if (argc < 1) {
        CALL_RECORDER_LOGE("HandleFilePermsNapi requires at least 1 argument");
        napi_value result = nullptr;
        napi_status status = napi_create_int32(env, 0, &result);
        if (status != napi_ok) {
            napi_throw_error(env, nullptr, "Failed to create int32 result");
            return nullptr;
        }
        return result;
    }
    
    // 校验参数类型
    napi_valuetype filePathType = napi_undefined;
    napi_status typeofStatus = napi_typeof(env, args[0], &filePathType);
    if (typeofStatus != napi_ok || filePathType != napi_string) {
        CALL_RECORDER_LOGE("HandleFilePermsNapi arg[0] must be string");
        napi_value result = nullptr;
        napi_status status = napi_create_int32(env, 0, &result);
        if (status != napi_ok) {
            napi_throw_error(env, nullptr, "Failed to create int32 result");
            return nullptr;
        }
        return result;
    }
    
    std::string filePath = Utils::GetStringValue(env, args[0]);

    CallRecorder &recorder = CallRecorder::GetInstance();
    bool ret = recorder.HandleFilePermission(filePath);
    
    napi_value handleFilePermissionResult = nullptr;
    napi_status createStatus = napi_create_int32(env, ret, &handleFilePermissionResult);
    if (createStatus != napi_ok) {
        napi_throw_error(env, nullptr, "Failed to create int32 result");
        return nullptr;
    }
    return handleFilePermissionResult;
}

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "handleFilePermsNapi", nullptr, HandleFilePermsNapi, nullptr, nullptr, nullptr, napi_default, nullptr }
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
EXTERN_C_END

static napi_module g_callRecorderModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "callrecorder",
    .nm_priv = ((void*)0),
    .reserved = { 0 },
};

extern "C" __attribute__((constructor)) void Register(void)
{
    napi_module_register(&g_callRecorderModule);
}
