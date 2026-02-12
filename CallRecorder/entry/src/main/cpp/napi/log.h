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

#ifndef CALL_RECORDER_LOG_H
#define CALL_RECORDER_LOG_H

#include <hilog/log.h>

#define CALL_RECORDER_LOG(func, fmt, args...)                                                   \
    do {                                                                                        \
        (void)func(LOG_APP, "{%{public}s():%{public}d} " fmt, __FUNCTION__, __LINE__, ##args);  \
    } while (0)

#define CALL_RECORDER_LOGF(fmt, ...) CALL_RECORDER_LOG(OH_LOG_FATAL, fmt, ##__VA_ARGS__)
#define CALL_RECORDER_LOGE(fmt, ...) CALL_RECORDER_LOG(OH_LOG_ERROR, fmt, ##__VA_ARGS__)
#define CALL_RECORDER_LOGW(fmt, ...) CALL_RECORDER_LOG(OH_LOG_WARN, fmt, ##__VA_ARGS__)
#define CALL_RECORDER_LOGI(fmt, ...) CALL_RECORDER_LOG(OH_LOG_INFO, fmt, ##__VA_ARGS__)
#define CALL_RECORDER_LOGD(fmt, ...) CALL_RECORDER_LOG(OH_LOG_DEBUG, fmt, ##__VA_ARGS__)

#endif // CALL_RECORDER_LOG_H