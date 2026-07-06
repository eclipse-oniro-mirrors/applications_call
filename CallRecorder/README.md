# CallRecorder<a name="EN-US_TOPIC_0000001103554544"></a>

-   [Introduction](#section11660541593)
    -   [Content](#section_intro_content_en)
    -   [Architecture diagram](#section_arch_diagram_en)
-   [File Tree](#section161941989596)
-   [Repositories Involved](#section1371113476307)

## Introduction<a name="section11660541593"></a>

### Content<a name="section_intro_content_en"></a>

The CallRecorder is a system application prebuilt in OpenHarmony. It provides automatic call recording, designated number recording and etc.

### Architecture diagram<a name="section_arch_diagram_en"></a>

![CallRecorder architecture](./figures/callrecorder_en.png)

**entry** hosts UI pages plus database and workers; **feature** groups UIExtension, DataShare, service extensions, and native **NAPI** recording; **Framework** covers ArkUI, media, and system services; **common** shares models, utilities, and presenters.

## File Tree<a name="section161941989596"></a>

~~~
/CallRecorder/
├── AppScope
├── entry                 
│   └── src
│       └── main
│           ├── cpp
│           │   ├── CMakeLists.txt
│           │   ├── napi
│           │   ├── types
│           │   └── NapiInit.cpp
│           ├── ets                        
│           │   ├── callrecorderuiextability
│           │   ├── common
│           │   ├── datashareextability
│           │   ├── filePermissionExt
│           │   ├── IdlServiceExt
│           │   ├── pages
│           │   ├── serviceextability
│           │   └── workers
│           └── resources
├── signature
└── LICENSE
~~~

## Repositories Involved<a name="section1371113476307"></a>

[**applications_callrecorder**](https://gitcode.com/openharmony/applications_call.git)
