# CommunicationSetting<a name="EN-US_TOPIC_0000001103554544"></a>

-   [Introduction](#section11660541593)
    -   [Content](#section_intro_content_en)
    -   [Architecture diagram](#section_arch_diagram_en)
-   [File Tree](#section161941989596)
-   [Repositories Involved](#section1371113476307)

## Introduction<a name="section11660541593"></a>

### Content<a name="section_intro_content_en"></a>

The CommunicationSetting is a system application prebuilt in OpenHarmony. It provides traffic statistics, application network access permission control, and related capabilities. **Traffic management** (for example data limit and related policies) is implemented in the **Settings** system application; see the Settings application repository linked below.

### Architecture diagram<a name="section_arch_diagram_en"></a>

![CommunicationSetting architecture](./figures/communicationsetting_en.png)

1. Layered modules: **entry** hosts traffic and per-app networking flows plus MVP-style layering.
2. **feature** houses chart modules and shared page components.
3. **Framework** integrates **ArkUI**, connectivity managers, usage statistics, and **DataShare** providers.
4. **common** consolidates constants, helpers, **worker** pools, and lightweight data utilities.

## File Tree<a name="section161941989596"></a>

~~~
/CommunicationSetting/
├── AppScope
├── entry                 
│   └── src
│       └── main
│           ├── ets                        
│           │   ├── application
│           │   ├── constants
│           │   ├── Controller
│           │   ├── data
│           │   ├── entryability
│           │   ├── feature
│           │   ├── model
│           │   ├── pages
│           │   ├── pagesComponents
│           │   ├── presenter
│           │   ├── service
│           │   ├── util
│           │   ├── view
│           │   ├── viewmodel
│           │   └── workers
│           └── resources
├── signature
└── LICENSE
~~~

## Repositories Involved<a name="section1371113476307"></a>

[**applications_communicationsetting**](https://gitcode.com/openharmony/applications_call.git)

[**applications_settings**](https://gitcode.com/openharmony/applications_settings.git) (Settings system application; hosts **traffic management** source code)
