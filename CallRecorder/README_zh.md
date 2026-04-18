# CallRecorder<a name="ZH-CN_TOPIC_0000001103421572"></a>

-   [简介](#section11660541593)
-   [目录](#section161941989596)
-   [相关仓](#section1371113476307)

## 简介<a name="section11660541593"></a>

通话录音应用是OpenHarmony标准系统中预置的系统应用，为用户提供通话自动录音、指定号码录音、录音文件管理等功能。

## 目录<a name="section161941989596"></a>

```
callrecorder
├─ entry
│  └─ src
│     └─ main
│        ├─ cpp                          # C++源码目录
│        │  ├─ CMakeLists.txt      
│        │  ├─ napi                
│        │  └─ NapiInit.cpp        
│        ├─ ets                   
│           ├─ callrecorderuiextability # 通话录音UI扩展Ability
│           ├─ common                   # 公共组件或方法配置目录
│           ├─ database                 # 数据库模块
│           ├─ datashareextability      # 数据共享扩展Ability
│           ├─ filePermissionExt        # 文件权限扩展
│           ├─ IdlServiceExt            # IDL服务扩展
│           ├─ migrationServiceExt      # 迁移服务扩展
│           ├─ pages                    # 页面目录
│           ├─ serviceextability        # 服务扩展Ability
│           └─ workers                  # 工作线程目录
│        ├─ resources                   # 资源文件存放目录
├─ common                      # 通用逻辑存放目录
├─ features                    # 相关模块业务逻辑存放目录
├─ LICENSE                     # 许可文件
├─ signature                   # 证书文件目录
```

## 相关仓

[**应用程序_通话录音**](https://gitcode.com/openharmony/applications_call.git)

