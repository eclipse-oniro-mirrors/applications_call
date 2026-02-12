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
import { promptAction } from '@kit.ArkUI';
import { sim } from '@kit.TelephonyKit';
import { ContactListStruct } from '../utils/ClassStruct';
import LogUtils from '../utils/HiLog';
import commonData from '../data/CommonData';
import { ReportUtil } from '../utils/ReportUtil';
import EmergencyCallController from './EmergencyCallControl';
import { CanAddOrEditEmergencyInfo } from '../utils/EmergencyInfoUtil';
import { DataStorageUtil } from '../utils/DataStorageUtil';
import { DynamicLoader } from '../utils/DynamicLoader';
import { PreferencesListenerUtil } from '../emergencydatashareextability/PreferencesListenerUtil';

const TAG = 'EmergencyContactsInfoController';
const SHOW_TOAST_TIMEOUT = 2000;

export const EDIT_LOCAL_ICON = 'components/icon/nav_edit.svg';

export const EDIT_SYMBOL_ICON = 'sys.symbol.square_and_pencil';

export class EmergencyContactsInfoController {
  /**
   * 根据联系人的电话号码和SlotId拨打电话
   * @param phoneNumber 电话号码
   * @param value SlotId
   */
  private static emergencyCallDialByContactList(phoneNumber: string, value: number | undefined) {
    let slotId: number = commonData.int.SIM_SLOT_ID_EMPTY;
    if (value !== undefined) {
      slotId = value;
    } else {
      let simOperatorNameFirstStr = AppStorage.get<string>('simOperatorNameFirst') ?? '';
      let simOperatorNameSecondStr = AppStorage.get<string>('simOperatorNameSecond') ?? '';
      if (simOperatorNameFirstStr.length > 0) {
        slotId = commonData.int.SIM_SLOT_ID_FIRST;
      } else if (simOperatorNameSecondStr.length > 0) {
        slotId = commonData.int.SIM_SLOT_ID_SECOND;
      }
    }
    EmergencyCallController.getInstance().emergencyCallDial(phoneNumber, slotId, false);
    ReportUtil.getInstance().reportEmergencyContactListDial(phoneNumber.length);
  }

  /**
   * 紧急联系人页面联系人列表项点击事件
   * 拨打对应联系人的电话号码
   * @param item 联系人数据
   */
  public static callEmergencyContact(item: ContactListStruct) {
    if (item.value) {
      sim.getDefaultVoiceSlotId((error, value) => {
        if (error) {
          LogUtils.e(TAG, `getDefaultVoiceSlotId error: ${error?.code} ${error?.message}`);
        }
        LogUtils.i(TAG, `getDefaultVoiceSlotId data: ${value}`);
        EmergencyContactsInfoController.emergencyCallDialByContactList(item.value, value);
      });
    }
  }

  /**
   * 紧急联系人页面右上角编辑按钮的点击事件
   * @param pathInfos NavPathStack
   */
  public static onSquareAndPencilClick(pathInfos: NavPathStack) {
    if (!pathInfos) {
      LogUtils.e(TAG, 'onSquareAndPencilClick pathInfos empty');
      return;
    }
    CanAddOrEditEmergencyInfo((isUnlock) => {
      if (isUnlock) {
        DynamicLoader.getInstance().callFunction('EmergencyContactsEdit').then(() => {
          pathInfos.pushPathByName('EmergencyContactsEdit', '');
        });
      }
    });
  }

  /**
   * 展示文本提示
   * @param message
   */
  private static showToast(message: Resource) {
    try {
      promptAction.showToast({
        message: message,
        duration: SHOW_TOAST_TIMEOUT
      });
    } catch (e) {
      LogUtils.e(TAG, `showToast error code is ${e?.code} message is ${e?.message}`)
    }
  }

  // 发送紧急联系人信息广播
  private static onPublishBroadcast(): void {
    LogUtils.i(TAG, 'onPublishBroadcast start.');
    const preferencesListenerUtil = PreferencesListenerUtil.getInstance();
    preferencesListenerUtil.sendPublicEvent();
  }

  /**
   * 是否可以添加或编辑紧急信息
   */
  private static canAddOrEditEmergencyInfo = () => {
    return new Promise((resolve: (value: boolean) => void, reject: () => void) => {
      try {
        CanAddOrEditEmergencyInfo((isUnlock) => {
          resolve(isUnlock);
        });
      } catch (e) {
        LogUtils.e(TAG, `canAddOrEditEmergencyInfo error: ${e?.code} ${e?.message}`);
        resolve(false);
      }
    });
  }
  /**
   * 紧急联系人页面底部“添加联系人”按钮点击事件
   * @param isRunning onAddContactButtonClick函数是否正在运行
   * @param setIsRunning 设置isRunning的函数
   * @param emergencyContacts 当前的紧急联系人数组
   * @param setEmergencyContacts 设置当前的紧急联系人数组
   * @param showConfirmDialog 显示添加联系人确认弹窗
   */
  public static onAddContactButtonClick = async (isRunning: boolean, setIsRunning: (value: boolean) => void,
    emergencyContacts: ContactListStruct[], checkContactsIsShow: () => void,
    setEmergencyContacts: (emergencyContacts: ContactListStruct[]) => void,
    showConfirmDialog: (title: Resource, contentText: Resource, isWaring: boolean, confirmText: Resource,
      contactData: ContactListStruct) => void) => {
    // UE report click add_emergency_contact
    ReportUtil.getInstance().reportClickAddEmergencyContact();
    // Need judge lock screen status.
    let isUnlock = await this.canAddOrEditEmergencyInfo();
    // CanAddOrEditEmergencyInfo((isUnlock) => {
    if (!isUnlock) {
      setIsRunning(false);
      return;
    }
    // 拉起联系人选择器
    EmergencyCallController.getInstance().selectInContactsPicker((contactData) => {
      if (!contactData) {
        setIsRunning(false);
        return;
      }
      // 通过联系人id和电话号码来判断新增的紧急联系人是否重复
      let hasSame = false;
      for (let i = 0; i < emergencyContacts.length; i++) {
        if (contactData.nameRawContactId === emergencyContacts[i].nameRawContactId &&
          contactData.telephone === emergencyContacts[i].value) {
          hasSame = true;
          break;
        }
      }
      if (hasSame) {
        this.showToast($r('app.string.already_in_contacts', contactData.contactName));
        setIsRunning(false);
        return;
      }
      //保存新的紧急联系人列表数据
      // else {
      const data: ContactListStruct = {
        value: contactData.telephone,
        label: contactData.contactName || $r('app.string.emptyStr'),
        id: new Date().getTime().toString(),
        nameRawContactId: contactData.nameRawContactId,
        type: commonData.int.COMMON_CONTACT_TYPE
      }
      const tempList: ContactListStruct[] = emergencyContacts;
      tempList.push(data);
      if (isRunning) {
        this.onPublishBroadcast();
      }
      DataStorageUtil.getInstance().updateEmergencyContacts(tempList, (result: boolean) => {
        if (!result) {
          setIsRunning(false);
          return;
        }
        setEmergencyContacts(tempList);
        checkContactsIsShow();
        if (sim.getMaxSimCount() && sim.getMaxSimCount() > 0) {
          showConfirmDialog($r('app.string.notifyContact'), $r('app.string.sendMsgNotice'), false,
            $r('app.string.sendNow'), data);
        }
        setIsRunning(false);
      });
    });
  }
}