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

import { ApnInfo } from '../common/constant/apnInfo';
import router from '@ohos.router';
import { ApnDataStorage } from '../model/apnDataStorage';
import common from '@ohos.app.ability.common';
import sim from '@ohos.telephony.sim';
import promptAction from '@ohos.promptAction';
import { ApnItemInfo } from '../common/constant/apnItemInfo';
import { ApnDetailDataConst } from '../common/constant/apnData';


export class ApnProxy {
  proxy: string = ''
  port: string = ''
}

@CustomDialog
@Component
struct EditDialog {
  @Link textValue: Resource
  @Link inputValue: string
  @State value: string = ''
  controller?: CustomDialogController
  cancel: () => void = () => {
  }
  confirm: () => void = () => {
  }

  build() {
    Column() {
      Text(this.textValue).fontSize(20).margin({ top: 10, bottom: 10 })
      TextInput({ placeholder: this.inputValue, text: this.inputValue })
        .height(60)
        .width('90%')
        .showUnderline(false)
        .borderRadius(0)
        .onChange((value: string) => {
          this.value = value
        })
      Flex({ justifyContent: FlexAlign.SpaceAround }) {
        Button($r('app.string.apn_cancel')).onClick(() => {
          if (this.controller != undefined) {
            this.controller.close()
            this.cancel()
          }
        }).backgroundColor(0xffffff).fontColor(Color.Black)
        Button($r('app.string.ok'))
          .onClick(() => {
            if (this.controller != undefined) {
              this.inputValue = this.value
              this.controller.close()
              this.confirm()
            }
          }).backgroundColor(0xffffff).fontColor(Color.Black)
      }.margin({ bottom: 10 })
    }.backgroundColor(Color.White)
    .width('100%')
    .borderRadius(10)
  }
}


@CustomDialog
@Component
struct SingleSelectDialog {
  @Link textValue: Resource
  @Link inputValue: string
  @Link selectList: string[]
  tmpValue: string = this.inputValue
  controller?: CustomDialogController
  cancel: () => void = () => {
  }
  confirm: () => void = () => {
  }

  build() {
    Column() {
      Text(this.textValue).fontSize(20).margin({ top: 10, bottom: 10 })
      List() {
        ForEach(this.selectList, (item: string) => {
          ListItem() {
            Row() {
              Text(item)
              Radio({ value: item, group: 'radioGroup' })
                .checked(this.inputValue == item)
                .onChange((isChecked: boolean) => {
                  if (isChecked) {
                    this.tmpValue = item
                  } else {
                    this.tmpValue = this.inputValue
                  }
                })
            }.width('95%')
            .margin({ left: 20, right: 20 })
            .justifyContent(FlexAlign.SpaceBetween)
          }
        })

      }

      Flex({ justifyContent: FlexAlign.SpaceAround }) {
        Button($r('app.string.apn_cancel'))
          .onClick(() => {
            if (this.controller != undefined) {
              this.controller.close()
              this.cancel()
            }
          }).backgroundColor(0xffffff).fontColor(Color.Black)
        Button($r('app.string.ok'))
          .onClick(() => {
            if (this.controller != undefined) {
              this.inputValue = this.tmpValue
              this.controller.close()
              this.confirm()
            }
          })
          .backgroundColor(0xffffff).fontColor(Color.Black)
      }.margin({ bottom: 10 })
    }
    .backgroundColor(Color.White)
    .width('100%')
    .borderRadius(10)
  }
}


@CustomDialog
@Component
struct MultipleSelectDialog {
  @Link textValue: Resource
  @Link inputValue: string
  @Link selectList: string[]
  tmpList: string[] = []
  controller?: CustomDialogController
  cancel: () => void = () => {
  }
  confirm: () => void = () => {
  }

  build() {
    Column() {
      Text(this.textValue).fontSize(20).margin({ top: 10, bottom: 10 })
      List() {
        ForEach(this.selectList, (item: string) => {
          ListItem() {
            Row() {
              Text(item)
              Checkbox({ name: item, group: 'checkboxGroup' })
                .select(this.inputValue === item)
                .selectedColor(Color.Blue)
                .onChange((isChecked: boolean) => {
                  if (isChecked) {
                    this.tmpList.push(item)
                  } else {
                    let index = this.tmpList.indexOf(item)
                    this.tmpList.slice(index, 1)
                  }
                })
            }.width('95%')
            .margin({ left: 20, right: 20 })
            .justifyContent(FlexAlign.SpaceBetween)
          }
        })

      }.width('100%')
      .layoutWeight(1)

      Flex({ justifyContent: FlexAlign.SpaceAround }) {
        Button($r('app.string.apn_cancel'))
          .onClick(() => {
            if (this.controller != undefined) {
              this.controller.close()
              this.cancel()
            }
          }).backgroundColor(0xffffff).fontColor(Color.Black)
        Button($r('app.string.ok'))
          .onClick(() => {
            if (this.controller != undefined) {
              if (this.tmpList.length > 0) {
                this.inputValue = this.tmpList.join(',');
              }
              this.controller.close()
              this.confirm()
            }
          })
          .backgroundColor(0xffffff).fontColor(Color.Black)
      }.margin({ bottom: 10 })
    }.backgroundColor(Color.White)
    .width('100%')
    .height('50%')
    .borderRadius(10)
  }
}


@Entry
@Component
struct ApnDetail {

  private storage: ApnDataStorage = new ApnDataStorage()
  @State name: string = ''
  @State textValue: Resource | null = null
  @State inputValue: string = ''
  @State list: Array<ApnItemInfo> = []
  @State apnInfo: ApnInfo = router.getParams() as ApnInfo
  @State selectList: string[] = []
  @State title: string = ''
  @State edited: number = 0 //0不可编辑 1 可编辑 2 新增
  @State profileID: number = 0
  @StorageLink('ApnStatus') apnStatus: boolean = false;
  dialogController: CustomDialogController | null = new CustomDialogController({
    builder: EditDialog({
      cancel: () => {
        this.onCancel()
      },
      confirm: () => {
        this.onAccept()
      },
      textValue: $textValue,
      inputValue: $inputValue
    }),
    cancel: this.exitApp,
    autoCancel: true,
    alignment: DialogAlignment.Center,
    offset: { dx: 0, dy: -20 },
    gridCount: 4,
    customStyle: false,
    cornerRadius: 10,
  })
  singleSelectDialogController: CustomDialogController | null = new CustomDialogController({
    builder: SingleSelectDialog({
      cancel: () => {
        this.onCancel()
      },
      confirm: () => {
        this.onAccept()
      },
      selectList: $selectList,
      textValue: $textValue,
      inputValue: $inputValue
    }),
    cancel: this.exitApp,
    autoCancel: true,
    alignment: DialogAlignment.Center,
    offset: { dx: 0, dy: -20 },
    gridCount: 4,
    customStyle: false,
    cornerRadius: 10,
  })
  multipleSelectDialogController: CustomDialogController | null = new CustomDialogController({
    builder: MultipleSelectDialog({
      cancel: () => {
        this.onCancel()
      },
      confirm: () => {
        this.onAccept()
      },
      selectList: $selectList,
      textValue: $textValue,
      inputValue: $inputValue
    }),
    cancel: this.exitApp,
    autoCancel: true,
    alignment: DialogAlignment.Center,
    offset: { dx: 0, dy: -20 },
    gridCount: 4,
    customStyle: false,
    cornerRadius: 10,
  })

  aboutToAppear(): void {
    this.storage.initData(getContext() as common.UIAbilityContext)
    this.getDataList()
  }

  aboutToDisappear() {
    this.dialogController = null
    this.singleSelectDialogController = null
    this.multipleSelectDialogController = null
  }

  onCancel() {
  }

  onAccept() {
    for (let i = 0; i < this.list.length; i++) {
      if (this.list[i].key.id == this.textValue.id) {
        let apnInfo = new ApnItemInfo()
        apnInfo.id = this.list[i].id
        apnInfo.key = this.textValue
        apnInfo.value = this.inputValue
        this.list[i] = apnInfo
      }
    }
  }

  exitApp() {
    console.info('Click the callback in the blank area')
  }

  getProxyPort(pp: string[]): ApnProxy {
    let length = pp.length
    let resproxy: string = ''
    let resport: string = ''
    pp.forEach((value, index) => {
      if (index < length - 1) {
        if (resproxy === '') {
          resproxy += value
        } else {
          resproxy += ':' + value
        }
      } else {
        resport = value
      }
    })
    let res: ApnProxy = {
      proxy: resproxy,
      port: resport
    }
    return res;
  }

  getDataList() {
    let simOpKey: string = sim.getSimOperatorNumericSync(0);
    if (this.apnInfo) {
      this.title = this.apnInfo.profile_name
      this.edited = this.apnInfo.edited
      this.profileID = this.apnInfo.profile_id
    } else {
      this.edited = 2
      this.apnInfo = new ApnInfo()
    }

    //名称
    let name: ApnItemInfo = new ApnItemInfo()
    name.id = ApnDetailDataConst.PROFILE_NAME
    name.key = $r('app.string.apn_name')
    name.value = this.isNoConfig(this.apnInfo.profile_name)
    this.list.push(name)
    //apn
    let apn: ApnItemInfo = new ApnItemInfo()
    apn.id = ApnDetailDataConst.APN
    apn.key = $r('app.string.apn_apn')
    apn.value = this.isNoConfig(this.apnInfo.apn)
    this.list.push(apn)
    //代理
    let apnProxy: ApnItemInfo = new ApnItemInfo()
    apnProxy.id = ApnDetailDataConst.PROXY_IP_ADDRESS
    apnProxy.key = $r('app.string.apn_proxy')

    //代理端口
    let apnPort: ApnItemInfo = new ApnItemInfo()
    apnPort.id = ApnDetailDataConst.APNPORT
    apnPort.key = $r('app.string.apn_port')
    let proxyIPAddressList = this.apnInfo.proxy_ip_address.split(':');
    if (proxyIPAddressList.length >= 2) {
      let obj = this.getProxyPort(proxyIPAddressList)
      apnProxy.value = obj.proxy
      apnPort.value = obj.port
    } else {
      apnProxy.value = this.isNoConfig(this.apnInfo.proxy_ip_address)
      apnPort.value = this.ResourceToString($r('app.string.apn_not_configured'))
    }
    this.list.push(apnProxy)
    this.list.push(apnPort)

    //用户名
    let authName: ApnItemInfo = new ApnItemInfo()
    authName.id = ApnDetailDataConst.AUTH_USER
    authName.key = $r('app.string.apn_auth_user')
    authName.value = this.isNoConfig(this.apnInfo.auth_user)
    this.list.push(authName)
    //密码
    let authPwd: ApnItemInfo = new ApnItemInfo()
    authPwd.id = ApnDetailDataConst.AUTH_PWD
    authPwd.key = $r('app.string.apn_auth_pwd')
    authPwd.value = this.isNoConfig(this.apnInfo.auth_pwd)
    this.list.push(authPwd)
    //服务器
    let server: ApnItemInfo = new ApnItemInfo()
    server.id = ApnDetailDataConst.SERVER
    server.key = $r('app.string.apn_server')
    server.value = this.isNoConfig(this.apnInfo.server)
    this.list.push(server)
    //mmsc
    let mmsc: ApnItemInfo = new ApnItemInfo()
    mmsc.id = ApnDetailDataConst.HOME_URL
    mmsc.key = $r('app.string.apn_mmsc')
    mmsc.value = this.isNoConfig(this.apnInfo.home_url)
    this.list.push(mmsc)
    //彩信代理
    let mmsProxy: ApnItemInfo = new ApnItemInfo()
    mmsProxy.id = ApnDetailDataConst.MMS_IP_ADDRESS
    mmsProxy.key = $r('app.string.apn_mms_proxy')
    //彩信端口
    let mmsPort: ApnItemInfo = new ApnItemInfo()
    mmsPort.id = ApnDetailDataConst.MMSPORT
    mmsPort.key = $r('app.string.apn_mms_port')

    let mmsProxyIPAddressList = this.apnInfo.mms_ip_address.split(':');
    if (mmsProxyIPAddressList.length >= 2) {
      let obj = this.getProxyPort(mmsProxyIPAddressList)
      mmsProxy.value = obj.proxy
      mmsPort.value = obj.port
    } else {
      mmsProxy.value = this.isNoConfig(this.apnInfo.mms_ip_address)
      mmsPort.value = this.ResourceToString($r('app.string.apn_not_configured'))
    }
    this.list.push(mmsProxy)
    this.list.push(mmsPort)

    //mcc
    let mcc: ApnItemInfo = new ApnItemInfo()
    mcc.id = ApnDetailDataConst.MCC
    mcc.key = $r('app.string.apn_mcc')
    mcc.value = (this.apnInfo.mcc === '' ? simOpKey.substring(0, 3) : this.apnInfo.mcc)
    this.list.push(mcc)
    //mnc
    let mnc: ApnItemInfo = new ApnItemInfo()
    mnc.id = ApnDetailDataConst.MNC
    mnc.key = $r('app.string.apn_mnc')
    mnc.value = (this.apnInfo.mnc === '' ? simOpKey.substring(3, 5) : this.apnInfo.mnc)
    this.list.push(mnc)
    //身份验证类型
    let authType: ApnItemInfo = new ApnItemInfo()
    authType.id = ApnDetailDataConst.AUTH_TYPE
    authType.key = $r('app.string.apn_auth_type')
    authType.value = this.isNullDefaultTxt(this.apnInfo.auth_type)
    this.list.push(authType)
    //APN类型
    let apnType: ApnItemInfo = new ApnItemInfo()
    apnType.id = ApnDetailDataConst.APN_TYPES
    apnType.key = $r('app.string.apn_apn_types')
    apnType.value = (this.apnInfo.apn_types === '' ? 'default' : this.apnInfo.apn_types)
    this.list.push(apnType)
    //APN协议
    let apnProtocol: ApnItemInfo = new ApnItemInfo()
    apnProtocol.id = ApnDetailDataConst.APN_PROTOCOL
    apnProtocol.key = $r('app.string.apn_apn_protocol')
    apnProtocol.value = (this.apnInfo.apn_protocol === '' ? 'IPv4' : this.apnInfo.apn_protocol)
    this.list.push(apnProtocol)
    //APN漫游协议
    let apnRoamProtocol: ApnItemInfo = new ApnItemInfo()
    apnRoamProtocol.id = ApnDetailDataConst.APN_ROAM_PROTOCOL
    apnRoamProtocol.key = $r('app.string.apn_apn_roam_protocol')
    apnRoamProtocol.value = (this.apnInfo.apn_roam_protocol === '' ? 'IPv4' : this.apnInfo.apn_roam_protocol)
    this.list.push(apnRoamProtocol)
    //APN承载系统
    let apnBearingSystemType: ApnItemInfo = new ApnItemInfo()
    apnBearingSystemType.id = ApnDetailDataConst.BEARING_SYSTEM_TYPE
    apnBearingSystemType.key = $r('app.string.apn_bearing_system_type')
    apnBearingSystemType.value = this.isNullDefaultTxt(this.apnInfo.bearing_system_type)
    this.list.push(apnBearingSystemType)
    //mvno类型
    let mvnoType: ApnItemInfo = new ApnItemInfo()
    mvnoType.id = ApnDetailDataConst.MVNO_TYPE
    mvnoType.key = $r('app.string.apn_mvno_type')
    mvnoType.value = this.isNullDefaultTxt(this.apnInfo.mvno_type)
    this.list.push(mvnoType)
    //mvno值
    let mvnoData: ApnItemInfo = new ApnItemInfo()
    mvnoData.id = ApnDetailDataConst.MVNO_MATCH_DATA
    mvnoData.key = $r('app.string.apn_mvno_match_data')
    mvnoData.value = this.isNullDefaultTxt(this.apnInfo.mvno_match_data)
    this.list.push(mvnoData)
  }

  isNullDefaultTxt(value: string | number): string {
    return (value === '' || value === 0) ? this.ResourceToString($r('app.string.apn_null')) : value.toString()
  }

  isNoConfig(value: string | number): string {
    return (value === '' || value === 0) ? this.ResourceToString($r('app.string.apn_not_configured')) : value.toString()
  }

  ResourceToString(resource: Resource): string {
    return getContext(this).resourceManager.getStringSync(resource)
  }

  build() {
    Column() {
      Row() {
        Row() {
          Stack({ alignContent: Alignment.Center }) {
            Image($r('app.media.ic_back'))
              .width(24)
              .height(24)
              .fillColor($r('sys.color.ohos_id_color_primary'))
          }
          .margin({ right: 10 })
          .backgroundColor($r('app.color.color_00000000_transparent'))
          .onClick(() => {
            router.back()
          })

          Text(this.title === '' ? $r('app.string.apn_add') : this.title)
            .fontSize(20)
            .fontFamily('HarmonyHeiTi-Bold')
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .textAlign(TextAlign.Start)
            .margin({ top: 15, bottom: 15 });
        }

        Image($r('app.media.ic_apn_save'))
          .width(28)
          .height(28)
          .visibility(this.edited === 0 ? Visibility.None : Visibility.Visible)
          .fillColor($r('sys.color.ohos_id_color_primary'))
          .onClick((event: ClickEvent) => {
            let name = this.list[0].value
            if (name === '' || name === this.ResourceToString($r('app.string.apn_not_configured'))) {
              promptAction.showToast({
                message: this.ResourceToString($r('app.string.apn_tips_name_null')),
                duration: 2000
              });
              return
            }
            let apn = this.list[1].value
            if (apn === '' || apn === this.ResourceToString($r('app.string.apn_not_configured'))) {
              promptAction.showToast({
                message: this.ResourceToString($r('app.string.apn_tips_apn_null')),
                duration: 2000
              });
              return
            }
            if (this.edited == 2) { //新增
              this.storage.dataInsert(this.storage.listToApnInfo(this.list, 2, this.profileID))
                .then((success) => {
                  if (success) {
                    AppStorage.setOrCreate<boolean>('ApnStatus',!this.apnStatus)
                    router.back()
                  }
                })
            } else { //编辑
              this.storage.dataUpdate(this.storage.listToApnInfo(this.list, 1, this.profileID))
                .then((success) => {
                  if (success) {
                    AppStorage.setOrCreate<boolean>('ApnStatus',!this.apnStatus)
                    router.back()
                  }
                })
            }
          })
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .width('100%')
      .padding({ left: 12, right: 12 })
      .height(56)
      .alignItems(VerticalAlign.Center)
      .align(Alignment.Start)

      List() {
        ForEach(this.list, (item: ApnItemInfo) => {
          ListItem() {
            Row() {
              Text(item.key)
                .fontFamily('HarmonyHeiTi')
                .fontSize($r('sys.float.ohos_id_text_size_body1'))
                .fontWeight(FontWeight.Medium)
                .fontColor(this.edited == 0 ? '#666666' : $r('sys.color.ohos_id_color_text_primary'))
                .letterSpacing(1)
                .lineHeight(22)
                .textAlign(TextAlign.Start)

              Text(item.value.toString())
                .fontFamily('HarmonyHeiTi')
                .fontSize($r('sys.float.ohos_id_text_size_body1'))
                .fontWeight(FontWeight.Medium)
                .fontColor(this.edited == 0 ? '#666666' : $r('sys.color.ohos_id_color_text_primary'))
                .textAlign(TextAlign.Start)
            }
            .height(50)
            .width('96%')
            .justifyContent(FlexAlign.SpaceBetween)
            .borderRadius(10)
            .backgroundColor(Color.White)
            .margin({ top: 5, left: 10, right: 10, bottom: 5 })
            .padding({ left: 10, right: 10 })

          }
          .enabled(this.edited == 0 ? false : true)
          .onClick((event: ClickEvent) => {
            this.textValue = item.key
            this.inputValue = (item.value.toString() === this.ResourceToString($r('app.string.apn_not_configured'))) ? '' : item.value.toString()
            if (item.id == 'auth_type') {
              this.selectList = [this.ResourceToString($r('app.string.apn_null')), 'PAP', 'CHAP', 'PAP/CHAP']
              if (this.singleSelectDialogController != null){
                this.singleSelectDialogController.open()
              }
            } else if (item.id == 'apn_protocol') {
              this.selectList = ['IPv4', 'IPv6', 'IPv4/IPv6']
              if (this.singleSelectDialogController != null){
                this.singleSelectDialogController.open()
              }
            } else if (item.id == 'apn_roam_protocol') {
              this.selectList = ['IPv4', 'IPv6', 'IPv4/IPv6']
              if (this.singleSelectDialogController != null){
                this.singleSelectDialogController.open()
              }
            } else if (item.id == 'bearing_system_type') {
              this.selectList = [this.ResourceToString($r('app.string.apn_null')), 'LTE', 'HSPAP', 'HSPA', 'HSUPA', 'HSDPA', 'UMTS', 'EDGE', 'GPRS', 'eHRPD', 'EVDO_B', 'EVDO_A', 'EVDO_O', '1xRTT', 'IS95B', 'IS95A']
              if (this.multipleSelectDialogController != null){
                this.multipleSelectDialogController.open()
              }
            } else if (item.id == 'mvno_type') {
              this.selectList = [this.ResourceToString($r('app.string.apn_null')), 'SPN', 'IMSI', 'GID']
              if (this.singleSelectDialogController != null){
                this.singleSelectDialogController.open()
              }
            } else {
              this.dialogController.open()
            }
          })
        })
      }.width('100%')
      .layoutWeight(1)

      Row() {
        Image($r('app.media.ic_apn_delete')).width(25).height(25).onClick((even: ClickEvent) => {
          this.storage.dataDelete(this.profileID)
            .then((success) => {
              if (success) {
                AppStorage.setOrCreate<boolean>('ApnStatus',!this.apnStatus)
                router.back()
              }
            })
        })
      }
      .width('100%')
      .height(40)
      .backgroundColor(Color.White)
      .justifyContent(FlexAlign.Center)
      .visibility(this.edited === 1 ? Visibility.Visible : Visibility.None)
    }.backgroundColor($r('sys.color.ohos_id_color_sub_background'))
    .height('100%')
    .width('100%')

  }
}