# EmergencyCommunication<a name="ZH-CN_TOPIC_0000001103421572"></a>

-   [简介](#section11660541593)
-   [目录](#section161941989596)
-   [相关仓](#section1371113476307)

## 简介<a name="section11660541593"></a>

紧急通信应用是OpenHarmony标准系统中预置的系统应用，为用户提供紧急通话功能、个人紧急信息管理、紧急预警服务等功能。

## 目录<a name="section161941989596"></a>

```
emergencycommunication
├─ entry
│  └─ src
│     └─ main
│        ├─ ets
│           ├─ backup             # 备份相关功能
│           ├─ base               # 基础功能模块
│           ├─ components         # 组件目录
│           ├─ control            # 控制层代码目录
│           ├─ data               # 数据层代码目录
│           ├─ dialog             # 对话框组件
│           ├─ emergencycallability # 紧急通话Ability
│           ├─ emergencydatashareextability # 紧急数据共享扩展Ability
│           ├─ EmergencyEarthquackLocationService # 地震定位服务
│           ├─ EmergencyEarthquakeAlarm # 地震预警
│           ├─ entryability       # Ability与ExtentionAbility存放目录
│           ├─ idlServiceExt      # IDL服务扩展
│           ├─ model              # 模型层代码目录
│           ├─ pages              # 页面目录
│           ├─ PersonalSafetySosServiceAbility # 个人安全SOS服务Ability
│           ├─ service            # 服务层代码目录
│           ├─ serviceextability # 服务扩展Ability
│           ├─ sosemergencycallability # SOS紧急通话Ability
│           ├─ soslocationservice # SOS定位服务
│           └─ utils              # 工具类目录
│        ├─ resources             # 资源文件存放目录
├─ LICENSE                        # 许可文件
├─ signature                      # 证书文件目录
```

## 相关仓

[**应用程序_紧急通信**](https://gitcode.com/openharmony/applications_call.git)

