import router from '@ohos.router';
import sim from '@ohos.telephony.sim';
import { ApnInfo } from '../common/constant/apnInfo';
import { PreferenceUtil } from '../common/utils/PreferenceUtil';
import { ApnDataStorage } from '../model/apnDataStorage';
import common from '@ohos.app.ability.common';
import { ApnDetailDataConst } from '../common/constant/apnData';

@Entry
@Component
struct ApnList {
  private storage: ApnDataStorage = new ApnDataStorage()
  @State apnList: ApnInfo[] = []
  @State mccmnc: string = ''
  // @State iccID: string = ''
  @State selectedApn: number = -1
  private cardTpye: number = 0
  @StorageLink('ApnStatus') @Watch("queryApnList") apnStatus: boolean = false;

  async aboutToAppear() {
    this.storage.initData(getContext() as common.UIAbilityContext).then(() => {
      this.queryApnList()
    })
    this.mccmnc = sim.getSimOperatorNumericSync(this.cardTpye)
    // this.iccID = await sim.getSimIccId(this.cardTpye)
    this.selectedApn = Number(PreferenceUtil.get('select_apn_common_' + this.mccmnc, -1))

  }

  queryApnList() {
    this.apnList = []
    this.storage.queryApnList(this.mccmnc).then((resultSet) => {
      if (resultSet == null)
        return
      while (resultSet.goToNextRow()) {
        let info: ApnInfo = new ApnInfo()
        info.profile_id = resultSet.getLong(resultSet.getColumnIndex(ApnDetailDataConst.PROFILE_ID));
        info.profile_name = resultSet.getString(resultSet.getColumnIndex(ApnDetailDataConst.PROFILE_NAME));
        info.mcc = resultSet.getString(resultSet.getColumnIndex(ApnDetailDataConst.MCC));
        info.mnc = resultSet.getString(resultSet.getColumnIndex(ApnDetailDataConst.MNC));
        info.mccmnc = resultSet.getString(resultSet.getColumnIndex(ApnDetailDataConst.MCCMNC));
        info.apn = resultSet.getString(resultSet.getColumnIndex(ApnDetailDataConst.APN));
        info.auth_type = resultSet.getLong(resultSet.getColumnIndex(ApnDetailDataConst.AUTH_TYPE));
        info.auth_user = resultSet.getString(resultSet.getColumnIndex(ApnDetailDataConst.AUTH_USER));
        info.auth_pwd = resultSet.getString(resultSet.getColumnIndex(ApnDetailDataConst.AUTH_PWD));
        info.apn_types = resultSet.getString(resultSet.getColumnIndex(ApnDetailDataConst.APN_TYPES));
        info.is_roaming_apn = resultSet.getLong(resultSet.getColumnIndex(ApnDetailDataConst.IS_ROAMING_APN));
        info.apn_protocol = resultSet.getString(resultSet.getColumnIndex(ApnDetailDataConst.APN_PROTOCOL));
        info.apn_roam_protocol = resultSet.getString(resultSet.getColumnIndex(ApnDetailDataConst.APN_ROAM_PROTOCOL));
        info.home_url = resultSet.getString(resultSet.getColumnIndex(ApnDetailDataConst.HOME_URL));
        info.mms_ip_address = resultSet.getString(resultSet.getColumnIndex(ApnDetailDataConst.MMS_IP_ADDRESS));
        info.proxy_ip_address = resultSet.getString(resultSet.getColumnIndex(ApnDetailDataConst.PROXY_IP_ADDRESS));
        info.bearing_system_type = resultSet.getLong(resultSet.getColumnIndex(ApnDetailDataConst.BEARING_SYSTEM_TYPE));
        info.mvno_type = resultSet.getString(resultSet.getColumnIndex(ApnDetailDataConst.MVNO_TYPE));
        info.mvno_match_data = resultSet.getString(resultSet.getColumnIndex(ApnDetailDataConst.MVNO_MATCH_DATA));
        info.edited = resultSet.getLong(resultSet.getColumnIndex(ApnDetailDataConst.EDITED));
        info.server = resultSet.getString(resultSet.getColumnIndex(ApnDetailDataConst.SERVER));
        this.apnList.push(info)
        let id = PreferenceUtil.get('select_apn_common_' + this.mccmnc, -1)
        if (id == -1) {
          PreferenceUtil.put('select_apn_common_' + this.mccmnc, resultSet.getLong(resultSet.getColumnIndex("profile_id")))
        }
        this.selectedApn = Number(PreferenceUtil.get('select_apn_common_' + this.mccmnc, -1))
      }
    })
  }

  build() {
    Column() {
      Row() {
        Row() {
          Stack({ alignContent: Alignment.Center }) {
            Image($r('app.media.ic_back'))
              .width(24)
              .height(24)
              .fillColor($r("sys.color.ohos_id_color_primary"))
          }
          .margin({ right: 16 })
          .backgroundColor($r('app.color.color_00000000_transparent'))
          .onClick(() => {
            router.back()
          })

          Text($r('app.string.apn_title'))
            .fontSize(20)
            .fontFamily('HarmonyHeiTi-Bold')
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .textAlign(TextAlign.Start)
            .margin({ top: 15, bottom: 15 });
        }

        Image($r("app.media.ic_add"))
          .width(24)
          .height(24)
          .fillColor($r("sys.color.ohos_id_color_primary"))
          .onClick((event: ClickEvent) => {
            router.pushUrl({
              url: 'pages/apnDetail'
            })
          })
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .width("100%")
      .padding({ left: 12, right: 12 })
      .height(56)
      .alignItems(VerticalAlign.Center)
      .align(Alignment.Start)

      Column() {
        List() {
          ForEach(this.apnList, (item: ApnInfo) => {
            ListItem() {
              Row() {
                Row() {
                  Image($r('app.media.ic_redio_check'))
                    .width(24)
                    .height(24)
                    .margin({ right: 10 })
                    .visibility(item.profile_id === this.selectedApn ? Visibility.Visible : Visibility.Hidden)
                  Column() {
                    Text(item.profile_name)
                      .fontFamily('HarmonyHeiTi')
                      .fontSize($r('sys.float.ohos_id_text_size_body1'))
                      .fontWeight(FontWeight.Medium)
                      .fontColor($r('sys.color.ohos_id_color_text_primary'))
                      .letterSpacing(1)
                      .lineHeight(22)
                      .textAlign(TextAlign.Start)
                    Text(item.apn)
                      .fontFamily('HarmonyHeiTi')
                      .fontSize($r('sys.float.ohos_id_text_size_body2'))
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#666666')
                      .letterSpacing(1)
                      .lineHeight(22)
                      .textAlign(TextAlign.Start)
                  }
                  .justifyContent(FlexAlign.Start)
                  .alignItems(HorizontalAlign.Start)
                }

                Navigator({ target: 'pages/apnDetail', type: NavigationType.Push }) {
                  Image($r("app.media.ic_about_apn"))
                    .padding(10)
                    .width(40)
                    .height(40)
                    .backgroundColor($r("sys.color.ohos_id_color_sub_background"))
                    .borderRadius(100)
                }.params(item)

              }
              .height(80)
              .width('96%')
              .justifyContent(FlexAlign.SpaceBetween)
              .borderRadius(15)
              .backgroundColor(Color.White)
              .margin({ top: 5, left: 10, right: 10, bottom: 5 })
              .padding({ left: 10, right: 10 })
            }.width('100%')
            .margin({ bottom: '1px' })
            .height(60)
            .onClick((event: ClickEvent) => {
              if (this.selectedApn != item.profile_id) {
                this.storage.initData(getContext() as common.UIAbilityContext).then(() => {
                  this.storage.updateXmlPeofileID(1, item.profile_id)
                    .then((success) => {
                      PreferenceUtil.put('select_apn_common_' + this.mccmnc, item.profile_id)
                      this.selectedApn = item.profile_id
                      if (success) {
                        router.back()
                      }
                    })
                })
              }
            })
          })
        }
        .width('100%')
        .height('100%')
        .margin({ bottom: 20 })
      }.layoutWeight(1)
      .width('100%')
    }
    .backgroundColor($r("sys.color.ohos_id_color_sub_background"))
    .width('100%')
    .height('100%')
  }
}
