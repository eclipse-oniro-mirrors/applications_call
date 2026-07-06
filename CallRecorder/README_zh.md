# CallRecorder<a name="ZH-CN_TOPIC_0000001103421572"></a>

-   [简介](#section11660541593)
    -   [内容介绍](#section_intro_content_zh)
    -   [架构图](#section_arch_diagram_zh)
-   [目录](#section161941989596)
-   [相关仓](#section1371113476307)

## 简介<a name="section11660541593"></a>

### 内容介绍<a name="section_intro_content_zh"></a>

通话录音应用是 OpenHarmony 标准系统中预置的系统应用，为用户提供通话自动录音、指定号码录音等功能。

### 架构图<a name="section_arch_diagram_zh"></a>

![CallRecorder 应用架构](./figures/callrecorder.png)

**entry** 承载页面与数据库、Worker 等支撑代码；**feature** 汇总 UIExtension、DataShare、服务扩展与 **C++/NAPI** 录音能力；**Framework** 为 ArkUI、媒体、DataShare 等系统栈；**common** 为公共模型、工具与展示逻辑。

## 目录<a name="section161941989596"></a>

~~~
/CallRecorder/
├── AppScope                               # 应用级 app.json5 与全局资源
├── entry                                  # 主入口模块（UI、DataShare、服务扩展）
│   └── src
│       └── main
│           ├── cpp                        # C++ 原生与 NAPI 桥接
│           │   ├── CMakeLists.txt         # CMake 构建配置
│           │   ├── napi                   # NAPI 实现源码
│           │   ├── types                  # ArkTS 侧类型声明等
│           │   └── NapiInit.cpp           # NAPI 模块注册入口
│           ├── ets                        # ArkTS 业务与 Ability 源码
│           │   ├── callrecorderuiextability # 通话录音界面 UIExtension Ability
│           │   ├── common                   # 公共组件、常量与工具类
│           │   ├── datashareextability      # 对外 DataShare 数据访问
│           │   ├── filePermissionExt        # 录音文件权限相关 IDL 扩展
│           │   ├── IdlServiceExt            # 与系统通话子系统 IDL 交互
│           │   ├── pages                    # 设置与文件列表等页面
│           │   ├── serviceextability        # 后台服务扩展（备份、权限等）
│           │   └── workers                  # 耗时任务 Worker 线程
│           └── resources                  # 资源配置文件存放目录
├── signature                              # 签名
└── LICENSE                                # 许可证
~~~

## 相关仓<a name="section1371113476307"></a>

[**应用程序_通话录音**](https://gitcode.com/openharmony/applications_call.git)

