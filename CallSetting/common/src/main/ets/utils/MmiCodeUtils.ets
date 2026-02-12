/**
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

import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { LogUtils } from './LogUtils';
import { sendUssd } from './MmiCodeCall';

export enum AlertType {
  USSD_FINISH,
  USSD_PENDING,
  USSD_ERROR,
  USSD_NONE,
  MMI
};

const TAG = 'MmiCodeUtils';
const TRANSFER_REASON_TYPE_NO_REPLY: number = 2;
const USSD_TYPE: number = 10001;
const TIMEOUT: number = 15 * 1000;

enum MmiCodeServiceType {
  CLIP = 30, // 来电显示
  CLIR = 31, // 本机号码
  COLP = 76, // 连接的线路 ID
  COLR = 77, // 连接的线路 ID 限制
  // 呼叫转移
  CFU = 21, // 无条件前传
  CFB = 67, // 遇忙前传
  CFNR = 61, // 无应答前传
  CFNRC = 62, // 不可及前传
  // 呼叫等待
  WAIT = 43,
  // 呼叫限制
  BAOC = 33, // 所有呼出
  BAIC = 35, // 所有呼入
  BAOIC = 331, // 国际长途呼出
  BAOICXH = 332, // 漫游呼出
  BAICR = 351 // 漫游呼入
}

enum MmiCodeAction {
  QUERRY = 0,
  ACTIVE = 1,
  DEACTIVE = 2,
  RESTRICTED = 3,
  OPEN = 4,
}

enum MmiCodeStatus {
  DISABLED = 0,
  ENABLED = 1,
  DEFAULT = 2,
}

enum MmiCodeServiceClassType {
  NONE = 0,
  VOICE = 1,
  FAX = 4,
  SHORT_MESSAGE_SERVICE = 8,
  DATA_CIRCUIT_SYNC = 16,
  DATA_CIRCUIT_ASYNC = 32,
  DEDICATED_PACKET_ACCESS = 64,
  DEDICATED_PAD_ACCESS = 128,
}

export interface CustomMmiCodeResult {
   result: number;
   message: string;
   mmiCodeType?: number;
   classCw?: number;
   reason?: number;
   status?: number;
   action?: number;
   number?: string;
}

export class MmiCodeUtils {
  private readonly RESTRICTED_STATUS_MAP: Map<MmiCodeStatus, Resource> = new Map([
    [MmiCodeStatus.DISABLED, $r('app.string.CLIRDefaultOnNextCallOn')],
    [MmiCodeStatus.ENABLED, $r('app.string.CLIRDefaultOnNextCallOn')],
    [MmiCodeStatus.DEFAULT, $r('app.string.CLIRDefaultOnNextCallOff')]
  ]);
  private readonly OPEN_STATUS_MAP: Map<MmiCodeStatus, Resource> = new Map([
    [MmiCodeStatus.DISABLED, $r('app.string.CLIRDefaultOffNextCallOff')],
    [MmiCodeStatus.ENABLED, $r('app.string.CLIRDefaultOffNextCallOn')],
    [MmiCodeStatus.DEFAULT, $r('app.string.CLIRDefaultOffNextCallOff')]
  ]);
  public static context: common.Context
  public static mmiFeatureDebug: boolean = false;
  public static result: CustomMmiCodeResult;
  public timeId : number = -1
  private static instance: MmiCodeUtils

  public static getInstance() {
    if (!MmiCodeUtils.instance) {
      MmiCodeUtils.instance = new MmiCodeUtils()
    }
    return MmiCodeUtils.instance
  }

  public getTitle(data: CustomMmiCodeResult): ResourceStr {
    switch (data.mmiCodeType ?? 0) {
      case MmiCodeServiceType.CFU:
      case MmiCodeServiceType.CFNR:
      case MmiCodeServiceType.CFNRC:
      case MmiCodeServiceType.CFB:
        return $r('app.string.CfMmi')
      case MmiCodeServiceType.WAIT:
        return $r('app.string.CwMmi')
      case MmiCodeServiceType.BAOC:
      case MmiCodeServiceType.BAIC:
      case MmiCodeServiceType.BAOIC:
      case MmiCodeServiceType.BAOICXH:
      case MmiCodeServiceType.BAICR:
        return $r('app.string.BaMmi')
      case MmiCodeServiceType.CLIP:
        return $r('app.string.ClipMmi')
      case MmiCodeServiceType.CLIR:
        return $r('app.string.ClirMmi')
      case MmiCodeServiceType.COLP:
        return $r('app.string.ColpMmi')
      case MmiCodeServiceType.COLR:
        return $r('app.string.ColrMmi')
      default:
        return '';
    }
  }

  public getServiceClassName(type: number) {
      switch (type) {
        case MmiCodeServiceClassType.VOICE:
          return 'voice';
        case MmiCodeServiceClassType.FAX:
          return 'fax';
        case MmiCodeServiceClassType.SHORT_MESSAGE_SERVICE:
          return 'message';
        case MmiCodeServiceClassType.DATA_CIRCUIT_SYNC:
          return 'sync';
        case MmiCodeServiceClassType.DATA_CIRCUIT_ASYNC:
          return 'async';
        case MmiCodeServiceClassType.DEDICATED_PACKET_ACCESS:
          return 'package';
        case MmiCodeServiceClassType.DEDICATED_PAD_ACCESS:
          return 'pad';
        default:
          return '';
      }
  }

  public getString(res: ResourceStr, ...args: Array<string | number>) {
    let content : string = '';
    LogUtils.i(TAG, `getString type is ${typeof res}, ${JSON.stringify(res)}`);
    try {
      if (typeof res === 'string') {
        content = MmiCodeUtils.context.resourceManager.getStringByNameSync(res)
      } else if (typeof res === 'object') {
        content = MmiCodeUtils.context.resourceManager.getStringSync(res, args[0], args[1])
      } else {
        LogUtils.e(TAG, `getString type is invalid`);
      }
    } catch (error) {
      let code = (error as BusinessError).code;
      let message = (error as BusinessError).message;
      LogUtils.e(TAG, `getString failed, error code: ${code}, message: ${message}.`);
    }
    LogUtils.i(TAG, `getString type is ${content}`);
    return content
  }

  public createServiceClassMessage(classex: number) {
    let content : string = '';
    for (let classMask = 1; classMask <= MmiCodeServiceClassType.DEDICATED_PAD_ACCESS; classMask <<= 1) {
      if (classex > 0 && ((classex & classMask) != 0)) {
        let name: string = this.getServiceClassName(classex & classMask)
        let value = this.getString(name)
        content += value
        content += '\n'
        LogUtils.i(TAG, `name = ${name} value = ${value}`);
      }
    }
    return content.slice(0, -1);
  }

  public createGetCallTransferResultMessage(data: CustomMmiCodeResult) {
    let content : string = '';
    let classcw = data.classCw ?? 0
    for (let classMask = 1; classMask <= MmiCodeServiceClassType.DEDICATED_PAD_ACCESS; classMask <<= 1) {
      if (classcw > 0 && ((classcw & classMask) != 0)) {
        let value: string = this.makeCallTransferMessageEx(data, classcw & classMask)
        content += value
        content += '\n'
      }
    }
    return content.slice(0, -1);
  }

  public makeCallTransferMessageEx(data: CustomMmiCodeResult, type: number): string {
    let needTime = data.reason == TRANSFER_REASON_TYPE_NO_REPLY;
    let serviceClassName = this.getServiceClassName(type);
    if (data.status == MmiCodeStatus.ENABLED) {
      if (needTime) {
        return this.getString($r('app.string.mmi_code_prompt_msg'), this.getString(serviceClassName), data.number ?? '')
      } else {
        return this.getString($r('app.string.mmi_code_prompt_msg'), this.getString(serviceClassName), data.number ?? '')
      }
    } else {
      return this.getString($r('app.string.mmi_code_prompt_msg'), this.getString(serviceClassName),
        this.getString('mmi_code_not_forwarded'))
    }
  }

  public getCfuContent(data: CustomMmiCodeResult): ResourceStr {
    if (data.action == MmiCodeAction.QUERRY) {
      return this.createGetCallTransferResultMessage(data);
    } else if (data.action == MmiCodeAction.ACTIVE) {
      return $r('app.string.serviceRegistered')
    } else if (data.action == MmiCodeAction.DEACTIVE) {
      return $r('app.string.serviceDisabled')
    }
    return ''
  }

  public getCwContent(data: CustomMmiCodeResult): ResourceStr {
    let content : string = ''
    if (data.action == MmiCodeAction.QUERRY) {
      if (data.status == MmiCodeStatus.DISABLED) {
        return $r('app.string.serviceDisabled')
      } else if (data.status == MmiCodeStatus.ENABLED) {
        content += this.getString('serviceEnabledFor')
        content += '\n'
        content += this.createServiceClassMessage(data.classCw ?? 0)
        return content
      }
    } else if (data.action == MmiCodeAction.ACTIVE) {
      return $r('app.string.serviceEnabled')
    } else if (data.action == MmiCodeAction.DEACTIVE) {
      return $r('app.string.serviceDisabled')
    }
    return ''
  }

  public getBaocContent(data: CustomMmiCodeResult): ResourceStr {
    if (data.action == MmiCodeAction.QUERRY) {
      return $r('app.string.serviceNotProvisioned');
    } else if (data.action == MmiCodeAction.ACTIVE) {
      return $r('app.string.CLIRPermanent');
    } else if (data.action == MmiCodeAction.DEACTIVE) {
      return $r('app.string.serviceDisabled');
    } else if (data.action == MmiCodeAction.RESTRICTED && data.status != undefined) {
      return this.RESTRICTED_STATUS_MAP.get(data.status) ?? '';
    } else if (data.action == MmiCodeAction.OPEN && data.status != undefined) {
      return this.OPEN_STATUS_MAP.get(data.status) ?? '';
    }
    return '';
  }

  public getInvalidContent(): ResourceStr {
    return $r('app.string.mmiError');
  }

  public getContent(data: CustomMmiCodeResult): ResourceStr {
    let content : string = ''
    if (!data) {
      LogUtils.e(TAG, 'data is null');
      return content;
    }
    if (data.result != 0) {
      return $r('app.string.mmiError');
    }

    switch (data.mmiCodeType) {
      case MmiCodeServiceType.CFU:
      case MmiCodeServiceType.CFNR:
      case MmiCodeServiceType.CFNRC:
      case MmiCodeServiceType.CFB:
        return this.getCfuContent(data)
      case MmiCodeServiceType.WAIT:
        return this.getCwContent(data)
      case MmiCodeServiceType.BAOC:
      case MmiCodeServiceType.BAIC:
      case MmiCodeServiceType.BAOIC:
      case MmiCodeServiceType.BAOICXH:
      case MmiCodeServiceType.BAICR:
        return this.getBaocContent(data)
      case MmiCodeServiceType.CLIP:
      case MmiCodeServiceType.CLIR:
      case MmiCodeServiceType.COLP:
      case MmiCodeServiceType.COLR:
        return this.getBaocContent(data)
      default:
        break;
    }
    return content;
  }

  public isUssdCase(data: CustomMmiCodeResult) {
    return data.mmiCodeType === USSD_TYPE;
  }

  public isMmiCase(data: CustomMmiCodeResult) {
    return data.mmiCodeType !== USSD_TYPE;
  }

  public setTimeout(callback: Function) {
    if (this.timeId != -1) {
      clearTimeout(this.timeId)
      this.timeId = -1;
    }
    this.timeId = setTimeout(()=>{
      callback()
    }, TIMEOUT)
  }

  public clearTimeout() {
    if (this.timeId != -1) {
      clearTimeout(this.timeId)
      this.timeId = -1;
    }
  }

  public sendUssd(slotId: number, content: string) {
    try {
      sendUssd(slotId, content)
    } catch (err) {
      LogUtils.e(TAG, err);
    }
  }
}

