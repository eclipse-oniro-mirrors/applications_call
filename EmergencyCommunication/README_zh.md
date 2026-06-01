# EmergencyCommunication<a name="ZH-CN_TOPIC_0000001103421572"></a>

-   [简介](#section11660541593)
    -   [内容介绍](#section_intro_content_zh)
    -   [架构图](#section_arch_diagram_zh)
-   [目录](#section161941989596)
-   [相关仓](#section1371113476307)

## 简介<a name="section11660541593"></a>

### 内容介绍<a name="section_intro_content_zh"></a>

紧急通信应用是 OpenHarmony 标准系统中预置的系统应用，其核心功能围绕紧急情况下的快速求助与安全通信进行了系统化设计。

### 核心功能：
   1. **紧急通话**：支持在锁屏或无SIM卡状态下拨打紧急号码，确保用户在危急时刻能够快速联系救援机构；同时可在通话界面显示设备当前的位置信息，便于救援方及时获取用户所在地。
   2. **紧急联系人**：允许用户添加或删除紧急联系人，并可设置触发条件后自动发送求助信息或自动拨打求助电话，帮助用户在无法手动操作时仍能主动向外求助，提升安全保障能力。
   3. **紧急拨号**：紧急拨号界面支持实时显示位置信息，便于用户或救援方确认方位；支持直接拨打预设的紧急号码；同时提供快速紧急拨号功能，通过连续按5次电源键即可触发紧急呼叫，显著缩短求助路径，降低操作门槛。

### 架构图<a name="section_arch_diagram_zh"></a>

![EmergencyCommunication 应用架构](./figures/emergencycommunication.png)

**entry** 承载紧急信息与 SOS 等业务页与控制/服务/数据分层；**feature** 汇总各类 **Ability / UIExtension / DataShare** 与定位、IDL 扩展；**Framework** 依赖 ArkUI、电话、位置与公共事件等系统能力；右侧 **common** 在架构示意中归组入口、工具与 IDL 等横切能力。

## 目录<a name="section161941989596"></a>

~~~
/EmergencyCommunication/
├── AppScope                               # 应用级 app.json5 与全局资源
├── entry                                  # 主入口模块
│   └── src
│       └── main
│           ├── ets                        
│           │   ├── backup                 # 个人紧急信息等备份扩展
│           │   ├── base                   # 基础类型、路由与公共基类
│           │   ├── components             # 业务通用 UI 组件
│           │   ├── control                # 控制层（流程与交互编排）
│           │   ├── data                   # 数据访问与仓库实现
│           │   ├── dialog                 # 各类业务弹窗页面
│           │   ├── emergencycallability   # 紧急呼叫主 Ability
│           │   ├── emergencydatashareextability # 紧急信息 DataShare 扩展
│           │   ├── entryability           # 主 UIAbility / Extension 入口
│           │   ├── idlServiceExt          # 与系统服务 IDL 扩展交互
│           │   ├── model                  # 业务实体与状态模型
│           │   ├── pages                  # 紧急信息、SOS 等页面
│           │   ├── PersonalSafetySosServiceAbility # 个人安全 SOS 后台服务
│           │   ├── service                # 系统 API 封装
│           │   ├── serviceextability      # 通用服务扩展 Ability
│           │   ├── sosemergencycallability # SOS 紧急呼叫 UIExtension
│           │   ├── soslocationservice     # SOS 联动定位服务
│           │   └── utils                  # 日志、权限、格式化等工具
│           └── resources                  # 资源配置文件存放目录
├── signature                              # 签名
└── LICENSE                                # 许可证
~~~

## 相关仓

[**应用程序_紧急通信**](https://gitcode.com/openharmony/applications_call.git)

