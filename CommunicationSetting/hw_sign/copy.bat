@rem
@rem Copyright (c) 2022-2024 Huawei Device Co., Ltd.
@rem Licensed under the Apache License, Version 2.0 (the "License");
@rem you may not use this file except in compliance with the License.
@rem You may obtain a copy of the License at
@rem
@rem     http://www.apache.org/licenses/LICENSE-2.0
@rem
@rem Unless required by applicable law or agreed to in writing, software
@rem distributed under the License is distributed on an "AS IS" BASIS,
@rem WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
@rem See the License for the specific language governing permissions and
@rem limitations under the License.
@rem

@echo off

set SIGN_TOOL_PATH=.\hap-sign-tool.jar
set SIGN_PLUGIN_PATH=.\hapsign-online-plugin.jar
if not exist %SIGN_TOOL_PATH% (
    echo "copy sign tool from SDK 12..."
    copy "%HM_SDK_HOME%\xxx-DB1\base\toolchains\lib\hap-sign-tool.jar" "%SIGN_TOOL_PATH%"
) else (
    echo "sign tool is exist."
)
if not exist %SIGN_PLUGIN_PATH% (
    echo "sign plugin is not exist. Start downloading..."
    curl  -o "%SIGN_PLUGIN_PATH%"
) else (
    echo "sign plugin is exist."
)
