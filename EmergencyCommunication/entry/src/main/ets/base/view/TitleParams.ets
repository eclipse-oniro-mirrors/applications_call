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

//import { HdsNavigationMenuContentOptions, HdsNavigationTitleBarOptions } from '@kit.UIDesignKit';
import { LengthMetrics } from '@kit.ArkUI';
import LayoutUtils from '../../utils/LayoutUtils';
//
// /**
//  * 标题栏通用模版
//  */
// export class TitleParams {
//   /**
//    * mini title 返回键 + 标题模式
//    */
//   public static MiniTitleParams(title: ResourceStr, backgroundColor: ResourceColor,
//     menu?: HdsNavigationMenuContentOptions): HdsNavigationTitleBarOptions {
//     return {
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
//         start: LengthMetrics.resource(LayoutUtils.getAdaptableTabletPadding(''))
//       },
//       content: {
//         title: {
//           mainTitle: title,
//         },
//         menu: menu
//       }
//     };
//   }
// }
/**
 * 标题栏通用模版
 */
export class TitleParams {
  /**
   * mini title 返回键 + 标题模式
   */
  public static MiniTitleParams(title: ResourceStr, backgroundColor: ResourceColor,
    menu?: NavigationMenuContentOptions): CustomBuilder {
    if(menu){
      return TitleBarLayout(title, backgroundColor, menu);
    }else {
      return TitleBarLayout(title, backgroundColor, {value: []});
    }
  }


}

export interface NavigationMenuContentOptions{
  value: Array<NavigationMenuItem>
}


@Builder
export function TitleBarLayout(title: ResourceStr,backgroundColor: ResourceColor, menu: NavigationMenuContentOptions) {
  Row() {
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
    start: LengthMetrics.resource(LayoutUtils.getAdaptableTabletPadding('')), // 使用你的工具类
    end: LengthMetrics.vp(16) // 右侧通常保留一些边距
  })
  .alignItems(VerticalAlign.Center)
}

/*
@Builder
function  TitleBarLayout(title: ResourceStr, backgroundColor: ResourceColor, menu?: NavigationMenuContentOptions) {
  Row() {
    // 1. 标题部分
    Text(title)
      .fontSize(20) // Mini模式标准大小，可根据设计稿调整
      .fontWeight(FontWeight.Bold)
      .fontColor(Color.Black) // 根据背景色调整字体颜色
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })

    // 2. 占位符，将菜单推到最右侧
    Blank()

    if(menu){
      if (menu.value && menu.value.length > 0) {
        Row({ space: 12 }) {
          ForEach(menu.value, (item: NavigationMenuItem) => {
            if (item.icon) {
              Image(item.icon)
                .width(24)
                .height(24)
                .onClick(() => {
                  if (item.action) {
                    item.action();
                  }
                })
            } else if (item.value) {
              Text(item.value)
                .fontSize(16)
                .onClick(() => {
                  if (item.action) {
                    item.action();
                  }
                })
            }
          })
        }
      }
    }



  }
  .width('100%')
  .height(56) // 标准 Mini 标题栏高度
  .backgroundColor(backgroundColor) // 设置背景色
  // 适配原来的 padding 逻辑
  .padding({
    start: LengthMetrics.resource(LayoutUtils.getAdaptableTabletPadding('')), // 使用你的工具类
    end: LengthMetrics.vp(16) // 右侧通常保留一些边距
  })
  .alignItems(VerticalAlign.Center)
}*/
