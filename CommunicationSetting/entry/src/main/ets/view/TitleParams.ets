/*
 * Copyright (c) 2025 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// import { HdsNavigationTitleBarOptions } from '@kit.UIDesignKit';
import { isTablet } from '../util/DeviceUtil';
import { LengthMetrics } from '@kit.ArkUI';

/**
 * 标题栏通用模版
 */
// export class TitleParams {
//
//   /**
//    * mini title 返回键 + 标题模式
//    *
//    * @param { ResourceStr } title : 标题名
//    * @param { ResourceColor } backgroundColor : 背景颜色
//    */
//   public static MiniTitleParams(title: ResourceStr, backgroundColor: ResourceColor): HdsNavigationTitleBarOptions {
//     return {
//       enableComponentSafeArea : true,
//       style: {
//         scrollEffectOpts: {
//           enableScrollEffect: false
//         },
//         originalStyle: {
//           backgroundStyle: {
//             backgroundColor: backgroundColor
//           }
//         }
//       },
//       avoidLayoutSafeArea: true,
//       padding: {
//         start: isTablet() ? LengthMetrics.vp(24) : LengthMetrics.vp(16)
//       },
//       content: {
//         title: {
//           mainTitle: title
//         }
//       }
//     };
//   }
//
//   /**
//    * mini title 标题为返回键 + 搜索组件模式
//    *
//    * @param { ResourceColor } backgroundColor : 背景颜色
//    * @param { CustomBuilder } stackBuilder : 搜索组件
//    * @param { Callback<void, void> } backIconAction : 返回键 action
//    */
//   public static searchTitleParam(backgroundColor: ResourceColor, backComponentId?: string, stackBuilder?: CustomBuilder,
//     backIconAction?: Callback<void, void>): HdsNavigationTitleBarOptions {
//     return {
//       enableComponentSafeArea: true,
//       style: {
//         scrollEffectOpts: {
//           enableScrollEffect: false
//         },
//         originalStyle: {
//           backgroundStyle: {
//             backgroundColor: backgroundColor
//           }
//         }
//       },
//       avoidLayoutSafeArea: true,
//       padding:
//       {
//         start: isTablet() ? LengthMetrics.vp(24) : LengthMetrics.vp(16),
//         end: isTablet() ? LengthMetrics.vp(24) : LengthMetrics.vp(16)
//       },
//       content:
//       {
//         title: undefined,
//         stackBuilder: stackBuilder,
//         menu: undefined,
//         backIcon: {
//           label: $r('app.string.accessibility_back'),
//           icon: $r('sys.symbol.chevron_backward'),
//           isEnabled: true,
//           action: backIconAction,
//           componentId: backComponentId
//         }
//       },
//     };
//   }
// }

// 定义接口
export interface SearchTitleOptions {
  backgroundColor: ResourceColor;
  backComponentId?: string;
  stackBuilder?: CustomBuilder;
  backIconAction?: () => void;
}

// ---------------------------------------------------------
// 1. 引入一个中转组件 (核心修复)
// ---------------------------------------------------------
/**
 * 这个组件的作用是专门用来渲染传入的 CustomBuilder
 * 解决了 "Only UI component syntax" 报错
 */
@Component
struct BuilderBridge {
  @BuilderParam builder: CustomBuilder;

  build() {
    // 只有当 builder 存在时才渲染
    if (this.builder) {
      this.builder()
    }
  }
}

// ---------------------------------------------------------
// 2. 全局 Builder
// ---------------------------------------------------------

@Builder
function DrawMiniTitle(title: ResourceStr, backgroundColor: ResourceColor) {
  Row() {
    Text(title)
      .fontWeight(FontWeight.Bold)
      .fontSize(20)
      .fontColor($r('sys.color.ohos_id_color_text_primary'))
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
  }
  .width('100%')
  .height(56)
  .padding({
    left: isTablet() ? 24 : 16,
    right: isTablet() ? 24 : 16
  })
  .backgroundColor(backgroundColor)
  .alignItems(VerticalAlign.Center)
}

@Builder
function DrawSearchTitle(backgroundColor: ResourceColor, backComponentId?: string, stackBuilder?: CustomBuilder, backIconAction?: () => void) {
  Row() {
    // 返回按钮
    SymbolGlyph($r('sys.symbol.chevron_backward'))
      .fontSize(24)
      // 【修复1】SymbolGlyph 的颜色必须是数组
      .fontColor([$r('sys.color.ohos_id_color_primary')])
      .onClick(() => {
        if (backIconAction) {
          backIconAction();
        }
      })
      .id(backComponentId)
      .margin({ right: 16 })

    // 搜索组件区域
    if (stackBuilder) {
      Row() {
        // 【修复2】不能直接调用 stackBuilder()，改用中转组件
        BuilderBridge({ builder: stackBuilder })
      }
      .layoutWeight(1)
    }
  }
  .width('100%')
  .height(56)
  .padding({
    left: isTablet() ? 24 : 16,
    right: isTablet() ? 24 : 16
  })
  .backgroundColor(backgroundColor)
  .alignItems(VerticalAlign.Center)
}

// ---------------------------------------------------------
// 3. 工具类 (保持对外接口不变)
// ---------------------------------------------------------

export class TitleParams {

  public static MiniTitleParams(title: ResourceStr, backgroundColor: ResourceColor): CustomBuilder {
    return () => {
      DrawMiniTitle(title, backgroundColor);
    };
  }

  public static searchTitleParam(
    backgroundColor: ResourceColor,
    backComponentId?: string,
    stackBuilder?: CustomBuilder,
    backIconAction?: Callback<void, void>
  ): CustomBuilder {
    return () => {
      DrawSearchTitle(backgroundColor, backComponentId, stackBuilder, backIconAction);
    };
  }
}