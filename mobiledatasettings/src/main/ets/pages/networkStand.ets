import NetworkStandItem from '../common/components/networkStandItem';
import radio from '@ohos.telephony.radio';
import HeadComponent from '../common/components/headComponent';
import LogUtils from '../common/utils/LogUtils';

const TAG = 'NetworkStand';

@Entry
@Component
struct NetworkStand {
  @State @Watch('networkModeChanged') networkMode: number = 5
  @State slotId: number = 0;

  aboutToAppear(): void {
    this.getPreferredNetwork(this.slotId);
  }

  /**
   * Get network mode
   *
   * @param {Object} slotId - call slotId
   */
  async getPreferredNetwork(slotId) {

    radio.getPreferredNetwork(slotId, (err, data: radio.PreferredNetworkMode) => {
      if (err) {
        LogUtils.e(TAG, 'getPreferredNetwork error, callback: data->' + JSON.stringify(err))
        return;
      }

      this.networkMode = data
      LogUtils.i(TAG, 'getPreferredNetwork success, callback: data-> ' + JSON.stringify(data))
    });

  }

  networkModeChanged() {
    LogUtils.i(TAG, 'networkMode Changed data-> ' + JSON.stringify(this.networkMode))
    try {
      radio.setPreferredNetwork(this.slotId, this.networkMode).then(() => {
        LogUtils.i(TAG, 'set 0 Preferred Network-> ' + JSON.stringify(this.networkMode) + ' success')
      }).catch((err) => {
        LogUtils.i(TAG, 'set 0 Preferred Network-> ' + JSON.stringify(this.networkMode) + ' failed' + JSON.stringify(err))
      });
    } catch (err) {
      LogUtils.i(TAG, 'set 0 Preferred Network-> ' + JSON.stringify(this.networkMode) + ' failed tryCatch ' + JSON.stringify(err))
    }
  }

  build() {

    Column() {
      HeadComponent({ title: $r('app.string.network_standard_select'), isTerminateSelf: false });
      Column() {
        NetworkStandItem({
          networkMode: $networkMode,
          title: $r("app.string.mobile_data_fiveAuto"),
          thisNetworkMode: radio.PreferredNetworkMode.PREFERRED_NETWORK_MODE_NR_LTE_WCDMA_GSM//34
        })
        Divider()
          .strokeWidth(0.5)
          .color("#E3E3E3")
          .lineCap(LineCapStyle.Round)
          .margin({ left: '2%', right: '2%' })
        NetworkStandItem({
          networkMode: $networkMode,
          title: $r("app.string.mobile_data_fourAuto"),
          thisNetworkMode: radio.PreferredNetworkMode.PREFERRED_NETWORK_MODE_LTE_WCDMA_GSM //5
        })
        Divider()
          .strokeWidth(0.5)
          .color("#E3E3E3")
          .lineCap(LineCapStyle.Round)
          .margin({ left: '2%', right: '2%' })
        NetworkStandItem({
          networkMode: $networkMode,
          title: $r("app.string.mobile_data_threeAuto"),
          thisNetworkMode: radio.PreferredNetworkMode.PREFERRED_NETWORK_MODE_WCDMA_GSM//6
        })
        Divider()
          .strokeWidth(0.5)
          .color("#E3E3E3")
          .lineCap(LineCapStyle.Round)
          .margin({ left: '2%', right: '2%' })
        NetworkStandItem({
          networkMode: $networkMode,
          title: $r("app.string.mobile_data_only_5g"),
          thisNetworkMode: radio.PreferredNetworkMode.PREFERRED_NETWORK_MODE_NR//31
        })
        Divider()
          .strokeWidth(0.5)
          .color("#E3E3E3")
          .lineCap(LineCapStyle.Round)
          .margin({ left: '2%', right: '2%' })
        NetworkStandItem({
          networkMode: $networkMode,
          title: $r("app.string.mobile_data_only_4g"),
          thisNetworkMode: radio.PreferredNetworkMode.PREFERRED_NETWORK_MODE_LTE//3
        })
        Divider()
          .strokeWidth(0.5)
          .color("#E3E3E3")
          .lineCap(LineCapStyle.Round)
          .margin({ left: '2%', right: '2%' })
        NetworkStandItem({
          networkMode: $networkMode,
          title: $r("app.string.mobile_data_only_3g"),
          thisNetworkMode: radio.PreferredNetworkMode.PREFERRED_NETWORK_MODE_WCDMA//2
        })
        Divider()
          .strokeWidth(0.5)
          .color("#E3E3E3")
          .lineCap(LineCapStyle.Round)
          .margin({ left: '2%', right: '2%' })
        NetworkStandItem({
          networkMode: $networkMode,
          title: $r("app.string.mobile_data_2g"),
          thisNetworkMode: radio.PreferredNetworkMode.PREFERRED_NETWORK_MODE_GSM//1
        })
      }
      .padding({
        left: 4,
        right: 4,
        top: 4,
        bottom: 4
      })
      .width("90%")
      .borderRadius(16)
      .backgroundColor(Color.White)
    }.height('100%')
    .width('100%')
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
  }
}