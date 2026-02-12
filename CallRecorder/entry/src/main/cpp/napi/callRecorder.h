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

#ifndef CALL_RECORDER_CALLRECORDER_H
#define CALL_RECORDER_CALLRECORDER_H

#include <string>

class CallRecorder {
public:
    virtual ~CallRecorder();
    
    static CallRecorder &GetInstance()
    {
        static CallRecorder recorder;
        return recorder;
    }
    
    /**
     * 修改文件权限
     * @param filePath 文件路径
     * @return 修改结果
     */
    bool HandleFilePermission(const std::string &filePath);
};

#endif // CALL_RECORDER_CALLRECORDER_H
