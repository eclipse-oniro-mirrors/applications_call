/**
 * Copyright (c) 2024-2024 Huawei Device Co., Ltd.
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
import BottomViewModel from '../../../viewmodel/BottomViewModel';
import DefaultCallData from '../../struct/TypeUtils';
import LogUtils from '../../utils/LogUtils';
import CallStateConst from '../../constant/CallStateConst';
import CallServiceProxy from '../../../model/CallServiceProxy';
import ConferenceConst from '../../constant/ConferenceConst';
import { ReportUtil } from '../../utils/ReportUtils/ReportUtil';
import { ReportDeviceType } from '../../utils/ReportUtils/ReportService';
import ImagePathConst from '../../constant/ImagePathConst';
import { HiCarSelectDeviceContentMenu } from './HiCarSelectDeviceContentMenu';
import Utils from '../../utils/utils';

const TAG: string = 'HiCarBottomBtn';
const BUTTON_TYPE_HANGUP: string = 'hangUP';
const BUTTON_TYPE_MUTE: string = 'mute';
const BUTTON_TYPE_SPEAKERPHONE: string = 'speakerphone';
const BUTTON_TYPE_KEYBOARD: string = 'keyboard';
const BUTTON_ACTIVE_BGCOLOR: ResourceColor = 'rgba(255, 255, 255, 0.9)';
const BUTTON_NORMAL_BGCOLOR: ResourceColor = $r('sys.color.ohos_id_color_button_normal');
const BUTTON_ACTIVE_BLUR: BlurStyle = BlurStyle.COMPONENT_ULTRA_THICK;
const BUTTON_NORMAL_BLUR: BlurStyle = BlurStyle.COMPONENT_ULTRA_THIN;

@Component
export default struct HiCarBottomBtn {
  private imageList: ImageList[] = [];
  private mCallServiceProxy: CallServiceProxy = CallServiceProxy.getInstance();
  @StorageLink('currentAudioDeviceIcon') currentAudioDeviceIcon: Resource =
    $r('app.media.ic_public_sound_louder');
  @StorageLink('isMute') @Watch('updateMuteState') isMute: boolean = false;
  @StorageLink('speakerSelected') speakerSelected: boolean = false;
  @StorageProp('curBp') curBp: string = '';
  @StorageProp('ratio') ratio: number = 0;
  @Link @Watch('refreshingData') callData: DefaultCallData;
  @Link callList: Array<DefaultCallData>;
  @Link hangup: boolean;
  @Link callListCount: number;
  @Link isShowKeyboardPage: boolean;
  @State mBottomViewModel: BottomViewModel = BottomViewModel.getInstance();
  @State muteIcon: string = 'ic_public_voice';
  @State muteIconBackgroundColor: ResourceColor = BUTTON_NORMAL_BGCOLOR;
  @State @Watch('cancel') isHaveMultiDevice: boolean = false;
  @State pressItemType: string = '';
  @State isShowMenu: boolean = false;
  @State callId: number = -1;
  @State callState: number = -1;
  @State conferenceState: number = -1;
  @State callType: number = -1;
  @State accountId: number = -1;

  private initImageList(): void {
    const hangUP: ImageList = {
      type: BUTTON_TYPE_HANGUP,
      img: $r('app.media.ic_hangup_bottom_btn'),
      backgroundColor: '#D94838'
    }
    const mute: ImageList = {
      type: BUTTON_TYPE_MUTE,
      img: '',
      backgroundColor: BUTTON_NORMAL_BGCOLOR
    }
    const speakerphone: ImageList = {
      type: BUTTON_TYPE_SPEAKERPHONE,
      img: $r('app.media.audio_mode_earpiece'),
      backgroundColor: BUTTON_NORMAL_BGCOLOR
    }
    const keyboard: ImageList = {
      type: BUTTON_TYPE_KEYBOARD,
      img: $r('app.media.ic_public_DTFS'),
      backgroundColor: BUTTON_NORMAL_BGCOLOR
    }
    this.imageList = [
      hangUP,
      mute,
      speakerphone,
      keyboard
    ];
  }

  private cancel(): void {
    this.isShowMenu = false;
  }

  private onImgClick(type: string) {
    LogUtils.i(TAG, `onImgClick, type: ${type}`);
    switch (type) {
      case BUTTON_TYPE_HANGUP:
        this.onHangUp();
        break;
      case BUTTON_TYPE_MUTE:
        this.onMuteOrUnHold();
        break;
      case BUTTON_TYPE_SPEAKERPHONE:
        this.onSpeakerPhone();
        break;
      case BUTTON_TYPE_KEYBOARD:
        this.onKeyboard();
        break;
      default:
        LogUtils.i(TAG, 'onImgClick, type error');
        break;
    }
  }

  private onHangUp(): void {
    LogUtils.i(TAG, `onHangUp this.callId : ${this.callId}`);
    ReportUtil.getInstance().reportIsDualCardOneInCallAndAnotherDialCancel(this.callList.length,
      this.accountId, this.callState,
      ReportDeviceType.HICAR);
    this.callState = CallStateConst.CALL_STATUS_DISCONNECTING;
    if (Utils.getInstance().isConferenceCall(this.callData)) {
      CallServiceProxy.getInstance()?.getMainCallId(this.callId, (mainId: number) => {
        this.mBottomViewModel.hangUpCall(mainId, this.callListCount);
        this.hangup = true;
      });
    } else {
      this.mBottomViewModel.hangUpCall(this.callId, this.callList.length);
      this.hangup = true;
    }
  }

  private onMuteOrUnHold(): void {
    if (this.callState === CallStateConst.CALL_STATUS_HOLDING) {
      this.mCallServiceProxy?.unHoldCall(this.callId);
      ReportUtil.getInstance().reportCallInterfaceClickBtn('wait', true, ReportDeviceType.HICAR);
    } else {
      LogUtils.i(TAG, `toggleMute: set to ${!this.isMute}`);
      if (this.isMute) {
        this.mCallServiceProxy.cancelMuted();
      } else {
        this.mCallServiceProxy.setMuted();
      }
      ReportUtil.getInstance().reportCallInterfaceClickBtn('mute', this.isMute ? false : true, ReportDeviceType.HICAR);
    }
  }

  private onSpeakerPhone(): void {
    if (this.isHaveMultiDevice) {
      LogUtils.i(TAG, 'onSpeakerButtonClicked menu open');
      this.isShowMenu = true;
      return;
    } else {
      this.mBottomViewModel.setButtonAudioDevice(this.callId, this.callType);
      this.isShowMenu = false;
    }
  }

  private onKeyboard(): void {
    this.isShowKeyboardPage = true;
  }

  private updateMuteState(): void {
    if (this.isMute) {
      this.muteIcon = 'ic_public_voice_Enabled';
      this.muteIconBackgroundColor = BUTTON_ACTIVE_BGCOLOR;
    } else {
      this.muteIcon = 'ic_public_voice';
      this.muteIconBackgroundColor = BUTTON_NORMAL_BGCOLOR;
    }
  }

  private iconUrl(imgName: string): string {
    return `${ImagePathConst.BASE_URL}${imgName}.svg`;
  }

  @Builder
  newGridItem(item: ImageList) {
    GridItem() {
      Stack() {
        this.flexBuildFunction(item);

        this.buildActiveLayer(item);

        if (this.isHaveMultiDevice && item.type === BUTTON_TYPE_SPEAKERPHONE) {
          Image($r('app.media.audio_mode_bluetooth_mark'))
            .width(10)
            .height(10)
            .draggable(false)
            .objectFit(ImageFit.Contain)
            .margin({ left: 54, top: 54 })
            .fillColor(Color.White);
        }
      }
    }
    .onTouch((event?: TouchEvent) => {
      switch (event?.type) {
        case TouchType.Down:
        case TouchType.Move:
          this.pressItemType = item.type;
          break;
        case TouchType.Up:
        case TouchType.Cancel:
          this.pressItemType = '';
          break;
        default:
          break;
      }
    })
    .onClick(() => {
      this.onImgClick(item.type);
    })
  }

  @Builder
  flexBuildFunction(item: ImageList) {
    Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
      if (item.type === BUTTON_TYPE_HANGUP) {
        this.buildHangUp(item);
      } else if (item.type === BUTTON_TYPE_MUTE) {
        this.buildMuteOrUnHold();
      } else if (item.type === BUTTON_TYPE_SPEAKERPHONE) {
        this.buildSpeakerPhone();
      } else if (item.type === BUTTON_TYPE_KEYBOARD) {
        this.buildKeyboard(item);
      }
    }
  }

  @Builder
  buildHangUp(item: ImageList) {
    Button() {
      Image(item.img)
        .bottomButtonImgStyle()
    }
    .bottomButtonStyle()
    .backgroundColor(item.backgroundColor)
    .backgroundBlurStyle(BlurStyle.NONE, undefined, { disableSystemAdaptation: true })
  }

  @Builder
  buildMuteOrUnHold() {
    if (this.callState === CallStateConst.CALL_STATUS_HOLDING) {
      Button() {
        Image(this.iconUrl('ic_public_pause_Enabled'))
          .bottomButtonImgStyle()
      }
      .bottomButtonStyle()
      .backgroundColor(BUTTON_ACTIVE_BGCOLOR)
      .backgroundBlurStyle(BUTTON_ACTIVE_BLUR, { colorMode: ThemeColorMode.LIGHT }, { disableSystemAdaptation: true })
    } else {
      Button() {
        Image(this.iconUrl(this.muteIcon))
          .fillColor(this.isMute ? $r('sys.color.ohos_id_color_warning_dark') : Color.White)
          .bottomButtonImgStyle()
      }
      .bottomButtonStyle()
      .backgroundColor(this.muteIconBackgroundColor)
      .backgroundBlurStyle(this.isMute ? BUTTON_ACTIVE_BLUR : BUTTON_NORMAL_BLUR, { colorMode: ThemeColorMode.LIGHT },
        { disableSystemAdaptation: true })
    }
  }

  @Builder
  buildSpeakerPhone() {
    Button() {
      SymbolGlyph(this.currentAudioDeviceIcon)
        .bottomButtonImgStyle()
        .fontSize(32)
        .fontColor([this.speakerSelected ? '#0A59f7' : Color.White])
    }
    .bottomButtonStyle()
    .backgroundColor(this.speakerSelected ? BUTTON_ACTIVE_BGCOLOR : BUTTON_NORMAL_BGCOLOR)
    .backgroundBlurStyle(this.speakerSelected ? BUTTON_ACTIVE_BLUR : BUTTON_NORMAL_BLUR,
      { colorMode: ThemeColorMode.LIGHT }, { disableSystemAdaptation: true })
    .bindMenu(this.isShowMenu, this.buildMenu, {
      placement: Placement.TopRight,
      onDisappear: () => {
        this.isShowMenu = false;
      }
    })
  }

  @Builder
  buildKeyboard(item: ImageList) {
    Button() {
      Image(item.img)
        .bottomButtonImgStyle()
    }
    .bottomButtonStyle()
    .backgroundColor(item.backgroundColor)
    .backgroundBlurStyle(BUTTON_NORMAL_BLUR, { colorMode: ThemeColorMode.LIGHT }, { disableSystemAdaptation: true })
  }

  @Builder
  buildActiveLayer(item: ImageList) {
    Column()
      .backgroundColor($r('sys.color.ohos_id_color_click_effect'))
      .visibility(this.pressItemType === item.type ? Visibility.Visible : Visibility.Hidden)
      .bottomButtonStyle()
  }

  @Builder
  buildMenu() {
    HiCarSelectDeviceContentMenu({
      callType: this.callType,
      hideCallBack: () => {
        this.isShowMenu = false;
      }
    })
  }

  @Styles
  bottomButtonStyle(){
    .size({
      width: 64,
      height: 64
    })
    .borderRadius(32)
  }

  @Styles
  bottomButtonImgStyle(){
    .size({
      width: 32,
      height: 32
    })
    .draggable(false)
  }

  aboutToAppear(): void {
    this.refreshingData();
    this.mBottomViewModel.aboutToAppear();
    this.updateMuteState();
    this.initImageList();
    this.isHaveMultiDevice = this.mBottomViewModel.getMultiDeviceState();
    this.mBottomViewModel.addMultiDeviceListener((bol: boolean) => {
      this.isHaveMultiDevice = bol;
    });
  }

  refreshingData(): void {
    this.callId = this.callData.callId;
    this.callState = this.callData.callState;
    this.callType = this.callData.callType;
    this.conferenceState = this.callData.conferenceState;
    this.accountId = this.callData.accountId;
  }

  build() {
    GridRow({ columns: { xs: 4, sm: 4, md: 8, lg: 12 }, gutter: 2 }) {
      GridCol({ span: { xs: 4, sm: 4, md: 6, lg: 8 }, offset: { md: 1, lg: 2 } }) {
        Grid() {
          ForEach(this.imageList, (item: ImageList) => {
            this.newGridItem(item);
          })
        }
        .columnsTemplate('1fr 1fr 1fr 1fr')
        .rowsTemplate('1fr')
        .size({
          width: '100%',
          height: '100%'
        })
      }
    }
    .size({
      width: '100%',
      height: 64
    })
  }
}

interface ImageList {
  type: string,
  img: ResourceStr,
  backgroundColor?: ResourceColor
}