/**
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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
import { accessibility } from '@kit.AccessibilityKit';
import { LogUtil } from './LogUtil';
import StringUtil from './StringUtil';
import { common } from '@kit.AbilityKit';

const TAG = 'AccessibilityUtils'
export const ISOPENACCESSIBILITY = 'isOpenAccessibility';

export class AccessibilityUtils {
  /**
   * 添加屏幕朗读开启状态监听
   */
  public static addAccessibilityStateChangeListener() {
    try {
      accessibility.on('screenReaderStateChange', (data: boolean) => {
        LogUtil.info(TAG, `isOpenAccessibility: ${data}`);
        AppStorage.setOrCreate(ISOPENACCESSIBILITY, data);
      });
    } catch (e) {
      LogUtil.info(TAG, `getAccessibilitySwitchState error: ${e?.message}, code: ${e?.code}`)
    }
  }

  /**
   * 获取屏幕朗读开启状态
   */
  public static getAccessibilitySwitchState() {
    let isOpenTouchGuideSync = accessibility.isOpenTouchGuideSync();
    LogUtil.info(TAG, `isOpenAccessibility: ${isOpenTouchGuideSync}`);
    AppStorage.setOrCreate(ISOPENACCESSIBILITY, isOpenTouchGuideSync);
  }

  /**
   * 释放屏幕朗读状态监听
   */
  public static releaseAccessibility() {
    LogUtil.info(TAG, 'releaseAccessibility...')
    try {
      accessibility.off('screenReaderStateChange');
    } catch (e) {
      LogUtil.info(TAG, `releaseAccessibility error: ${e?.message}, code: ${e?.code}`)
    }
  }


  /**
   * 判断是否需要屏幕朗读。
   * 应用需要主动播报的场景，应该判断屏幕朗读有无开启；
   * 判断屏幕朗读是否开启的API：accessibility.isOpenAccessibilitySync()；
   *
   * @returns true:需要屏幕朗读；false：不需要屏幕朗读。
   */
  public static isNeedScreenRead(): boolean {
    return accessibility.isOpenAccessibilitySync();
  }

  /**
   * 主动进行朗读。
   *
   * @param info - 要朗读的内容。
   * @returns 发送朗读事件的结果。
   */
  public static readInfo(info: string): Promise<void> {
    let eventInfo: accessibility.EventInfo = ({
      type: 'announceForAccessibility',
      bundleName: 'com.ohos.communicationsetting',
      triggerAction: 'common',
      textAnnouncedForAccessibility: info
    });
    return accessibility.sendAccessibilityEvent(eventInfo);
  }

  /**
   * 主动进行聚焦
   *
   * @param customId - 要聚焦的组件id。
   * @returns 发送聚焦事件的结果。
   */
  public static sendAccessibilityEvent(customId: string): Promise<void> {
    let eventInfo: accessibility.EventInfo = ({
      type: 'requestFocusForAccessibility',
      bundleName: 'com.ohos.communicationsetting',
      triggerAction: 'common',
      customId: customId
    });

    return accessibility.sendAccessibilityEvent(eventInfo);
  }

  /**
   * TextSelectItem组件特有工具方法，关闭子组件的屏幕朗读焦点后需要获取整体组件的屏幕朗读内容。
   *
   * @param context - 上下文
   * @param text - TextSelectItem组件中显示的内容
   * @param isSelected - TextSelectItem组件是否被选中
   * @returns - 最终朗读的内容
   */
  public static getTextSelectItemReadContent(context: common.UIAbilityContext, text: string | Resource,
    isSelected: boolean) {
    let accessibilityTitle = '';
    if (typeof text === 'string') {
      accessibilityTitle = text;
    } else {
      accessibilityTitle = StringUtil.convertResourceToString(text, context);
    }
    let selectedStateStr =
      isSelected ? StringUtil.convertResourceToString($r('app.string.accessibility_selected'), context) :
      StringUtil.convertResourceToString($r('app.string.accessibility_unselected'), context);
    return accessibilityTitle + ' ' + selectedStateStr;
  }
}