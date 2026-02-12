# Applications Call<a name="ZH-CN_TOPIC_0000001103421572"></a>

-   [简介](#section11660541593)
-   [目录](#section161941989596)
-   [相关仓](#section1371113476307)

## 简介<a name="section11660541593"></a>

Applications Call 是 OpenHarmony 电话子系统中通话相关系统应用及组件的集合，为系统提供语音通话、视频通话、通话录音、通话设置、移动网络设置、SIM 卡管理、紧急通信、号码识别（来电识别）服务及通信设置等功能。

## 目录<a name="section161941989596"></a>

```
applicationscall
├─ callui                    # 通话应用（语音/视频通话）
│  ├─ entry
│  │  └─ src
│  │     └─ main
│  │        ├─ ets
│  │        │  ├─ Application       # 应用能力阶段
│  │        │  ├─ MainAbility       # 主 Ability
│  │        │  ├─ pages             # 页面
│  │        │  ├─ common            # 公共组件
│  │        │  ├─ controller        # 控制器层
│  │        │  ├─ model             # 模型层
│  │        │  ├─ presenter         # 展示器层
│  │        │  ├─ viewmodel         # 视图模型层
│  │        │  └─ ServiceAbility    # 服务 Ability
│  │        └─ resources
│  ├─ common
│  ├─ features
│  ├─ LICENSE
│  └─ signature
├─ CallRecorder             # 通话录音应用
│  ├─ entry
│  │  └─ src
│  │     └─ main
│  │        ├─ cpp
│  │        │  ├─ CMakeLists.txt
│  │        │  ├─ napi
│  │        │  └─ NapiInit.cpp
│  │        ├─ ets
│  │        │  ├─ callrecorderuiextability   # 通话录音 UI 扩展 Ability
│  │        │  ├─ common                    # 公共组件
│  │        │  ├─ database                  # 数据库模块
│  │        │  ├─ datashareextability       # 数据共享扩展 Ability
│  │        │  ├─ filePermissionExt         # 文件权限扩展
│  │        │  ├─ IdlServiceExt             # IDL 服务扩展
│  │        │  ├─ migrationServiceExt       # 迁移服务扩展
│  │        │  ├─ pages                     # 页面
│  │        │  ├─ serviceextability         # 服务扩展 Ability
│  │        │  └─ workers                   # 工作线程
│  │        └─ resources
│  ├─ common
│  ├─ features
│  ├─ LICENSE
│  └─ signature
├─ CallSetting              # 通话与移动网络设置
│  ├─ product
│  │  ├─ default
│  │  │  └─ src
│  │  │     └─ main
│  │  │        ├─ ets
│  │  │        │  ├─ abilities      # 能力模块
│  │  │        │  ├─ application    # 应用入口
│  │  │        │  ├─ base          # 基础组件
│  │  │        │  ├─ common        # 通用逻辑
│  │  │        │  ├─ databases     # 数据库
│  │  │        │  ├─ pages        # 页面
│  │  │        │  └─ taskpool     # 任务池
│  │  │        └─ resources
│  │  └─ wearable
│  │     └─ src
│  │        └─ main
│  │           ├─ ets
│  │           └─ module.json5
│  ├─ common
│  ├─ feature
│  └─ signature
├─ CommunicationSetting     # 通信设置
│  ├─ entry
│  │  └─ src
│  │     └─ main
│  │        ├─ ets
│  │        │  ├─ application
│  │        │  ├─ constants
│  │        │  ├─ Controller
│  │        │  ├─ data
│  │        │  ├─ entryability
│  │        │  ├─ feature
│  │        │  ├─ model
│  │        │  ├─ pages
│  │        │  ├─ pagesComponents
│  │        │  ├─ presenter
│  │        │  ├─ service
│  │        │  ├─ util
│  │        │  ├─ view
│  │        │  ├─ viewmodel
│  │        │  └─ workers
│  │        └─ resources
│  ├─ product
│  │  └─ wearable
│  │     └─ src
│  │        └─ main
│  │           ├─ ets
│  │           └─ resources
│  └─ signature
├─ EmergencyCommunication   # 紧急通话与 SOS 服务
│  ├─ entry
│  │  └─ src
│  │     └─ main
│  │        ├─ ets
│  │        │  ├─ backup
│  │        │  ├─ base
│  │        │  ├─ components
│  │        │  ├─ control
│  │        │  ├─ data
│  │        │  ├─ dialog
│  │        │  ├─ emergencycallability        # 紧急通话 Ability
│  │        │  ├─ emergencydatashareextability
│  │        │  ├─ EmergencyEarthquackLocationService
│  │        │  ├─ EmergencyEarthquakeAlarm
│  │        │  ├─ entryability
│  │        │  ├─ idlServiceExt
│  │        │  ├─ model
│  │        │  ├─ pages
│  │        │  ├─ PersonalSafetySosServiceAbility
│  │        │  ├─ service
│  │        │  ├─ serviceextability
│  │        │  ├─ sosemergencycallability
│  │        │  ├─ soslocationservice
│  │        │  └─ utils
│  │        └─ resources
│  └─ signature
```

## 相关仓<a name="section1371113476307"></a>

[**applications_call**](https://gitcode.com/openharmony/applications_call.git)
