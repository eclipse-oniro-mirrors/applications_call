# Applications Call<a name="EN-US_TOPIC_0000001103554544"></a>

-   [Introduction](#section11660541593)
-   [Directory](#section161941989596)
-   [Repositories Involved](#section1371113476307)

## Introduction<a name="section11660541593"></a>

Applications Call is a collection of call-related system applications and components prebuilt in OpenHarmony. It provides voice calls, video calls, call recording, call settings, mobile network settings, SIM card management, emergency communication, number identity (caller ID) services, and communication settings.

## Directory<a name="section161941989596"></a>

```
applicationscall
├─ callui                    # Call application (voice/video calls)
│  ├─ entry
│  │  └─ src
│  │     └─ main
│  │        ├─ ets
│  │        │  ├─ Application       # Application ability stage
│  │        │  ├─ MainAbility       # Main Ability
│  │        │  ├─ pages             # UI pages
│  │        │  ├─ common            # Common utilities
│  │        │  ├─ controller        # Controller layer
│  │        │  ├─ model             # Model layer
│  │        │  ├─ presenter         # Presenter layer
│  │        │  ├─ viewmodel         # ViewModel layer
│  │        │  └─ ServiceAbility    # Service Ability
│  │        └─ resources
│  ├─ common
│  ├─ features
│  ├─ LICENSE
│  └─ signature
├─ CallRecorder             # Call recording application
│  ├─ entry
│  │  └─ src
│  │     └─ main
│  │        ├─ cpp
│  │        │  ├─ CMakeLists.txt
│  │        │  ├─ napi
│  │        │  └─ NapiInit.cpp
│  │        ├─ ets
│  │        │  ├─ callrecorderuiextability
│  │        │  ├─ common
│  │        │  ├─ database
│  │        │  ├─ datashareextability
│  │        │  ├─ filePermissionExt
│  │        │  ├─ IdlServiceExt
│  │        │  ├─ migrationServiceExt
│  │        │  ├─ pages
│  │        │  ├─ serviceextability
│  │        │  └─ workers
│  │        └─ resources
│  ├─ common
│  ├─ features
│  ├─ LICENSE
│  └─ signature
├─ CallSetting              # Call and mobile network settings
│  ├─ product
│  │  ├─ default
│  │  │  └─ src
│  │  │     └─ main
│  │  │        ├─ ets
│  │  │        │  ├─ abilities
│  │  │        │  ├─ application
│  │  │        │  ├─ base
│  │  │        │  ├─ common
│  │  │        │  ├─ databases
│  │  │        │  ├─ pages
│  │  │        │  └─ taskpool
│  │  │        └─ resources
│  │  └─ wearable
│  │     └─ src
│  │        └─ main
│  │           ├─ ets
│  │           └─ module.json5
│  ├─ common
│  ├─ feature
│  └─ signature
├─ CommunicationSetting     # Communication settings
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
├─ EmergencyCommunication   # Emergency call and SOS services
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
│  │        │  ├─ emergencycallability
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

## Repositories Involved<a name="section1371113476307"></a>

[**applications_call**](https://gitcode.com/openharmony/applications_call.git)