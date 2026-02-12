/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
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

import connection from '@ohos.bluetooth.connection';
// import nearlinkDevice from '@hms.nearlink.remoteDevice';
import LogUtils from './LogUtils';
import Utils from './utils';
import { constant as bluetoothConstant } from '@kit.ConnectivityKit';

const TAG = 'CallUI_SymbolIconUtil';

// The ID is converted to a hexadecimal number
const HEX_RADIX = 16;
const DEFAULT_XINGSHAN_SYMBOL_ICON = 'sys.symbol.nearlink';
const DEFAULT_EARPHONE_START = 'sys.symbol.earphone';
const DEFAULT_BLUETOOTH_SYMBOL_ICON = 'sys.symbol.bluetooth';
const DEFAULT_EARPHONE_SYMBOL_ICON = 'sys.symbol.earphone_bluetooth_fill';

export class SymbolIconUtil {
  private static instance?: SymbolIconUtil;

  public static getInstance(): SymbolIconUtil {
    if (!SymbolIconUtil.instance) {
      SymbolIconUtil.instance = new SymbolIconUtil();
    }
    return SymbolIconUtil.instance;
  }

  /**
   * Obtains the symbol resource string of the headset filling image.
   *
   * @param deviceMac
   * @returns symbol resource string
   */
  public getEarphoneFillIcon(deviceMac?: string): string {
    if (deviceMac === undefined || deviceMac === null || deviceMac === '') {
      return DEFAULT_BLUETOOTH_SYMBOL_ICON;
    }
    const iconString: string = this.getEarphoneIcon(deviceMac);
    if (iconString.includes('sys.symbol.earphone')) {
      // If the earphone field is contained, the obtained headset icon is returned.
      return iconString;
    }
    return this.getDeviceClassIcon(deviceMac);
  }

  // public getXingshanEarphoneFillIcon(deviceMac?: string): string {
  //   LogUtils.i(TAG, `getXingshanEarphoneFillIcon start!`);
  //   if (!deviceMac) {
  //     return DEFAULT_XINGSHAN_SYMBOL_ICON;
  //   }
  //   try {
  //     let device: nearlinkDevice.RemoteDevice | undefined = undefined
  //     let deviceModel: nearlinkDevice.DeviceModel | undefined = undefined
  //     let iconString: string = ''
  //     device = nearlinkDevice.createRemoteDevice(deviceMac)
  //     deviceModel = device.getDeviceModel();
  //     iconString = this.getNearLinkIconByIconId(deviceModel.iconId)
  //     if (iconString.includes(DEFAULT_EARPHONE_START)) {
  //       LogUtils.i(TAG, `If the earphone field is contained, the obtained headset icon is returned.`);
  //       return iconString;
  //     }
  //   } catch (e) {
  //     LogUtils.e(TAG, `getXingshanEarphoneFillIcon error: ${e.message} , ${e.code}`);
  //   }
  //   return DEFAULT_XINGSHAN_SYMBOL_ICON;
  // }

  public getNearLinkIconByIconId(iconId: string) {
    LogUtils.i(TAG, `getNearLinkIconByIconId iconId: ` + iconId);
    try {
      const decimalIconId: number = parseInt(iconId, HEX_RADIX);
      LogUtils.i(TAG, `getNearLinkIconByIconId decimalIconId : ` + decimalIconId);
      const symbolName: string = `earphone_${decimalIconId}_fill`;
      Utils.getInstance().getContext().resourceManager.getSymbolByName(symbolName);
      return `sys.symbol.${symbolName}`
    } catch (e) {
      LogUtils.e(TAG, `getNearLinkIconByIconId error: ${e.message} , ${e.code}`);
      return ''
    }
  }

  /**
   * Obtains the headset symbol icon.
   *
   * @param deviceMac
   * @returns symbol resource
   */
  private getEarphoneIcon(deviceMac: string): string {
    LogUtils.i(TAG, `getEarphoneIcon ${LogUtils.toSafeAddressString(deviceMac)}`);
    try {
      // If the ID does not exist, FFFFFF_FF_FFFF is returned. If an exception occurs, the catch branch is used.
      const productId: string = connection.getRemoteProductId(deviceMac);
      const result: string[] = productId.split('_');
      const iconId: number = parseInt(result[result.length - 1], HEX_RADIX);
      const symbolName = `earphone_${iconId}_fill`;
      // Check whether the icon identifier is in the Symbol. If not exist, the catch branch is used.
      Utils.getInstance().getContext().resourceManager.getSymbolByName(symbolName);
      return `sys.symbol.${symbolName}`;
    } catch (e) {
      // Exception, return to default headset icon
      LogUtils.i(TAG, `getEarphoneIcon error: ${e?.code}, ${e?.message}`);
      return '';
    }
  }

  /**
   * Obtains the icon corresponding to the device type.
   *
   * @param deviceMac
   * @returns icon string
   */
  private getDeviceClassIcon(deviceMac: string): string {
    try {
      const deviceClass: connection.DeviceClass = connection.getRemoteDeviceClass(deviceMac);
      if (!deviceClass || !deviceClass.majorClass) {
        LogUtils.i(TAG, 'getDeviceClassIcon deviceClass is empty');
        return DEFAULT_BLUETOOTH_SYMBOL_ICON;
      }
      if (deviceClass.majorClass === bluetoothConstant.MajorClass.MAJOR_AUDIO_VIDEO) {
        if (deviceClass.majorMinorClass === bluetoothConstant.MajorMinorClass.AUDIO_VIDEO_WEARABLE_HEADSET ||
          deviceClass.majorMinorClass === bluetoothConstant.MajorMinorClass.AUDIO_VIDEO_HEADPHONES) {
          return DEFAULT_EARPHONE_SYMBOL_ICON;
        }
      }
      return DEFAULT_BLUETOOTH_SYMBOL_ICON;
    } catch (e) {
      LogUtils.e(TAG, `getDeviceClassIcon error: ${e?.code}, ${e?.message}`);
      return DEFAULT_BLUETOOTH_SYMBOL_ICON;
    }
  }
}