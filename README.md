# applications_call



- [简介](#section11660541593)
  -   [架构图](#section78574815486)
  
- [目录](#section161941989596)

- [相关仓](#section1371113476307)

## 简介

基于系统平台能力，设计和开发通话应用，提供语音通话、视频通话、通话设置、移动网络设置、SIM卡管理设置、紧急拨号以及添加个人紧急信息的功能。从不同视角构建模型，设计通话应用的架构，确保在满足基本功能的同时，确保安全、韧性、可靠、隐私等。

### 架构图

![img](./figures/callui_en.png)

## 目录

```
/applications
├── callui                                      # 通话应用主Ability，提供拉起应用入口
│   └── src
│       └── main
│           ├── ets                              # ets代码目录
│               ├── default
│                   ├── assets                   # 图片目录
│                   ├── common                   # 公共组件或方法配置目录
│                       ├── components           # 公共组件
│                       ├── configs          	 # 应用配置对象目录
│                       ├── constant             # 应用常量对象目
│                       ├── utils                # 公共方法
│                   ├── model                    # Model层代码目录
│                   ├── pages                    # 通话页面目录
│               ├── ServiceAbilty                # ServiceAbilty启动
│                   ├── callManagerService.js    # ServiceAbilty方法
│                   ├── service.js               # ServiceAbilty方法
│                   ├── telephonyApi.js          # ServiceAbilty方法
│           ├── resources                        # 资源目录
│           ├── config.json                      # 项目配置信息
├── mobiledatasettings                           # 移动数据设置
│   └── src
│       └── main
│           ├── ets                              # ets代码目录
│               ├── default
│                   ├── pages                    # 移动数据页面目录
│           ├── resources                        # 资源目录
│           ├── config.json                      # 项目配置信息
├── figures                                      # 架构图目录
│   └── callui_en.png                            # 架构设计图片
├── signature                                    # 签名文件
│   └── com.ohos.callui.p7b                      # com.ohos.callui签名文件
```

## 相关仓

系统应用

**applications_standard_call**



