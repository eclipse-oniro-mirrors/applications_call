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

// import { NavigationMenuContentOptions, NavigationTitleBarOptions } from '@kit.UIDesignKit';
import { LengthMetrics } from '@kit.ArkUI';

/**
 * 标题栏通用模版
 */
export class TitleParams {
  /**
   * mini title 返回键 + 标题模式
   */
  // public static MiniTitleParams(title: ResourceStr, backgroundColor: ResourceColor,  isCrossMarkExists: boolean,
  //   avoidLayoutSafeArea: boolean = false, duration?: number,
  //   menu?: NavigationMenuContentOptions): NavigationTitleBarOptions {
  //   return {
  //     padding: { // 叉号宽度40，叉号距离边框距离16，标题距离最右边距离总共56
  //       end: isCrossMarkExists ? LengthMetrics.vp(56) : undefined
  //     },
  //     style: {
  //       scrollEffectOpts: {
  //         enableScrollEffect: false
  //       },
  //       originalStyle: {
  //         backgroundStyle: {
  //           backgroundColor: backgroundColor
  //         }
  //       }
  //     },
  //     avoidLayoutSafeArea: avoidLayoutSafeArea,
  //     enableComponentSafeArea: true,
  //     content: {
  //       title: {
  //         mainTitle: title,
  //       },
  //       menu: menu
  //     },
  //     // animationDuration: duration
  //   };
  // }

  /**
   * 隐私声明标题默认参数配置
   */
  // public static PrivatePageTitleParams(avoidLayoutSafeArea = false): NavigationTitleBarOptions {
  //   return {
  //     style: {
  //       scrollEffectOpts: {
  //         enableScrollEffect: false
  //       }
  //     },
  //     enableComponentSafeArea: true,
  //     avoidLayoutSafeArea: avoidLayoutSafeArea
  //   }
  // }
}
export interface NavigationMenuContentOptions{
  value: Array<NavigationMenuItem>,
  maxCount?: number
}
export interface backIconOptions{
  label:ResourceStr,
  icon:ResourceStr,
  pathInfos: NavPathStack
}


@Builder
export function TitleBarLayout(
  title: ResourceStr,
  backgroundColor: ResourceColor,
  isCrossMarkExists: boolean,
  duration?: number,
  backIcon?:backIconOptions,
  menu?: NavigationMenuContentOptions) {
  Row() {
    if (backIcon) {
      Column() {
        // --- 修改开始：同时支持图片和 Symbol ---
        if (backIcon.icon && typeof backIcon.icon !== 'string') {
          SymbolGlyph(backIcon.icon)
            .fontSize(24)
            .onClick(() => {
              // 返回按钮点击事件
              backIcon.pathInfos.pop();
            })
        } else if (backIcon.label) {
          Text(backIcon.label)
            .fontSize(16)
            .onClick(() => {
              // 返回按钮点击事件
              backIcon.pathInfos.pop();
            })
        }
      }
    }
    Text(title)
      .fontSize(20)
      .fontWeight(FontWeight.Bold)
      .fontColor(Color.Black)
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
    //.layoutWeight(1) // 建议加上这个，防止标题过长把按钮挤没

    Blank()

    if (menu && menu.value && menu.value.length > 0) {
      Row({ space: 12 }) {
        ForEach(menu.value, (item: NavigationMenuItem) => {
          // --- 修改开始：同时支持图片和 Symbol ---
          if (item.icon && typeof item.icon === 'string') {
            Text(item.icon)
              .fontSize(24)
              .fontColor(Color.Black) // Symbol 需要设置颜色，否则可能不可见
              .onClick(() => {
                item.action && item.action();
              })
          } else if (item.value) {
            Text(item.value)
              .fontSize(16)
              .onClick(() => {
                item.action && item.action();
              })
          }
        })
      }
    }
  }
  .width('100%')
  .height(56) // 标准 Mini 标题栏高度
  .backgroundColor(backgroundColor) // 设置背景色
  // 适配原来的 padding 逻辑
  .padding({
    end: isCrossMarkExists ? LengthMetrics.vp(56) : undefined
  })
  .alignItems(VerticalAlign.Center)
  .animation({duration: duration ?? 0})
}