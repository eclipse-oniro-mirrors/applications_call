@Preview
@Component
export default struct NetworkStandItem {
  @Link networkMode: number;
  title: ResourceStr = '';
  thisNetworkMode: number = 5

  build() {
    Column() {
      Row() {
        Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
          Column() {
            Text(this.title)
              .fontFamily('HarmonyHeiTi')
              .fontSize($r('sys.float.ohos_id_text_size_body1'))
              .fontWeight(FontWeight.Medium)
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
              .opacity(this.networkMode == this.thisNetworkMode ? 0.9 : 0.6)
              .letterSpacing(1)
              .lineHeight(22)
              .textAlign(TextAlign.Start)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ right: 26 })

          Image($r('app.media.ic_redio_check'))
            .width(24)
            .visibility(this.networkMode === this.thisNetworkMode ? Visibility.Visible :  Visibility.Hidden)
            .height(24)
        }
      }
    }
    .height(50)
    .justifyContent(FlexAlign.Center)
    .borderRadius(16)
    .margin({ top: 5, left: 10, right: 10, bottom: 5 })
    .padding({ left: 10, right: 10 })
    .onClick(() => {
      this.networkMode = this.thisNetworkMode
    })
  }
}