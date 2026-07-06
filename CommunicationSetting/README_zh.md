# CommunicationSetting<a name="ZH-CN_TOPIC_0000001103421572"></a>

-   [简介](#section11660541593)
    -   [内容介绍](#section_intro_content_zh)
    -   [架构图](#section_arch_diagram_zh)
-   [目录](#section161941989596)
-   [相关仓](#section1371113476307)

## 简介<a name="section11660541593"></a>

### 内容介绍<a name="section_intro_content_zh"></a>

通信设置应用是 OpenHarmony 标准系统中预置的系统应用，为用户提供流量统计、应用联网权限控制等功能。**流量管理**（如套餐限额、策略控制等相关能力）的代码位于**设置**系统应用中，请参阅下方「相关仓」中的设置应用仓链接。

### 架构图<a name="section_arch_diagram_zh"></a>

![CommunicationSetting 应用架构](./figures/communicationsetting.png)

1. 分层模块化：**entry** 承载流量统计与应用联网业务页面，以及 MVP / MVVM 相关分层。
2. **feature** 提供图表类子模块、页面级组件的精简入口。
3. **Framework** 对接 **ArkUI**、网络管理、用量统计与 **DataShare** 等系统能力。
4. **common** 汇总常量、视图工具、**Worker** 任务与数据访问助手等横切代码。

## 目录<a name="section161941989596"></a>

~~~
/CommunicationSetting/
├── AppScope                               # 应用级 app.json5 与全局资源
├── entry                                  # 默认形态主模块
│   └── src
│       └── main
│           ├── ets                        
│           │   ├── application            # Application 与全局初始化
│           │   ├── constants              # 业务与 UI 常量
│           │   ├── Controller             # MVC 控制器
│           │   ├── data                   # 流量统计等数据层
│           │   ├── entryability           # UIAbility / ExtensionAbility 入口
│           │   ├── feature                # 图表、流量曲线等功能子模块
│           │   ├── model                  # 业务模型与数据结构
│           │   ├── pages                  # 流量、联网管理等业务页面
│           │   ├── pagesComponents        # 页面级可复用组件
│           │   ├── presenter              # MVP 展示器
│           │   ├── service                # 后台服务与系统接口封装
│           │   ├── util                   # 工具与格式化函数
│           │   ├── view                   # 自定义视图与绘制
│           │   ├── viewmodel              # MVVM 视图模型
│           │   └── workers                # 统计聚合等 Worker 任务
│           └── resources                  # 字符串、媒体与主题资源
├── signature                              # 签名
└── LICENSE                                # 许可证
~~~

## 相关仓<a name="section1371113476307"></a>

[**应用程序_通信设置**](https://gitcode.com/openharmony/applications_call.git)

[**应用程序_设置**](https://gitcode.com/openharmony/applications_settings.git)（设置系统应用；**流量管理**相关源码位于该仓）

