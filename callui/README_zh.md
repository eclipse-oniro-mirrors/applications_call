# Call<a name="ZH-CN_TOPIC_0000001103421572"></a>

-   [简介](#section11660541593)
    -   [架构图](#section48896451454)
-   [目录](#section161941989596)
-   [相关仓](#section1371113476307)

## 简介<a name="section11660541593"></a>

通话应用是OpenHarmony标准系统中预置的系统应用，为用户提供语音通话、视频通话、通话设置、移动网络设置、SIM卡管理设置、紧急拨号以及添加个人紧急信息的功能。

### 架构图<a name="section48896451454"></a>

![](figures/callui_en.png)

## 目录<a name="section161941989596"></a>

```
call
├─ entry
│  └─ src
│     └─ main
│        ├─ ets
│           ├─ Application  # 应用入口
│           ├─ MainAbility  # 主Ability
│           ├─ pages        # 页面组件存放目录
│           ├─ common       # 公共组件或方法配置目录
│           ├─ controller   # 控制器层代码目录
│           ├─ model        # Model层代码目录
│           ├─ presenter    # 展示器层代码目录
│           ├─ viewmodel    # 视图模型层
│           ├─ ServiceAbility # 服务Ability
│        ├─ resources       # 资源文件存放目录
├─ common                      # 通用逻辑存放目录
├─ features                    # 相关模块业务逻辑存放目录
├─ LICENSE                     # 许可文件
├─ signature                   # 证书文件目录
```

## 相关仓

[**通话应用**](https://gitcode.com/openharmony/applications_call.git)

