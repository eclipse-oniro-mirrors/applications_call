/**
 * Copyright (c) 2025-2025 Huawei Device Co., Ltd.
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

import { VideoController } from '../../controller/VideoController';
import { componentUtils, display, promptAction, SymbolGlyphModifier, window } from '@kit.ArkUI';
import CallColumnUtils from '../../common/utils/CallColumnUtils';
import SplitScreenManager from '../../model/SplitScreenManager';
import ScreenAdapterUtils from '../../common/utils/ScreenAdapterUtils';
import VideoRingtoneHandler from './VideoRingtoneHandler';
import { pathParams } from './VideoRingtonePage';
import { BusinessError, settings } from '@kit.BasicServicesKit';
import uiEffect from '@ohos.graphics.uiEffect';
import measure from '@ohos.measure';
import { btn, ScreenInfo } from './model/IncomingModel';
import { isTablet, isTwoInOne } from '../../common/utils/Utils';
import { TrifoldManager } from '../../manager/TrifoldManager';
import * as IncomingModel from './model/IncomingModel';
import { systemSoundManager } from '@kit.AudioKit';
import { offCallStateChange, onCallStateChange } from '../../common/utils/SettingUtil';
import { call, observer } from '@kit.TelephonyKit';
import { LogUtils } from '@ohos/common';
import { UIExtensionContentSession } from '@kit.AbilityKit';
import { DisplayUtil } from '../../common/utils/DisplayUtil';

const TAG = 'videoPreview';
const SAFE_TEXT_PADDING: number = 16;
const MAX_FONT_SCALE: number = 1.45;
const PHONE_NUMBER: string = '123 4567 XXXX';

@Builder
export function videoPreviewLoader(): void {
  videoPreview();
}

@Component
export default struct videoPreview {
  private xComponentController: XComponentController = new XComponentController();
  private surfaceID: string = '';
  private playVideoModel?: VideoController = new VideoController();
  @StorageProp('curBp') curBp: string = '';
  private btnList?: btn[] = undefined;
  @State backIcon: SymbolGlyphModifier = new SymbolGlyphModifier($r('sys.symbol.chevron_backward'));
  @Consume('pathInfos') pathInfos: NavPathStack;
  private fd: number = 0;
  @StorageLink('needUpdateView') updateVideoFrom: string = '';
  @StorageLink('needUpdateContactView') updateContactVideoFrom: string = '';
  @StorageLink('videoPreviewShow') videoPreviewShow: boolean = false;
  @StorageLink('VideoOnBackground') @Watch('fullScreenShow') isBackground: boolean = false;
  @State funcBtnRowWidth: number = 0;
  @State incomingBtnWidth: number = 0;
  public storage = LocalStorage.getShared();
  private simCard: string = this.storage?.get<string>('simCard') as string;
  private isNewFoldPhoneInnerScreen = ScreenAdapterUtils.getInstance().isNewFoldPhoneInnerScreen();
  private isVideoPaused = false;
  private sizeUpdateCallback: Function | undefined;
  private isFromRingtoneList: boolean = false;
  private isBindSheet: boolean = false;
  private videoUriPathSp: string = '';
  @StorageProp('statusBarHeight') statusBarHeight: number = 0;
  @State maxTextButtonWidth: number = 0;
  @State maxTextButtonHeight: number = 0;
  private visualEffortBackground: uiEffect.VisualEffect = uiEffect.createEffect();
  private advancedBlendmode: uiEffect.BrightnessBlender | undefined;
  private videoSize: ScreenInfo = {
    width: 0,
    height: 0
  }
  private session: UIExtensionContentSession =
    this.storage?.get<UIExtensionContentSession>('session') as UIExtensionContentSession;
  private isFullScreen = this.storage?.get('isFullScreen') as boolean ?? false;

  aboutToAppear(): void {
    LogUtils.i(TAG, `aboutToAppear is called`);
    this.btnList = IncomingModel.videoPreviewBtnList
    const pathParamsLen = this.pathInfos.getParamByName('videoPreview').length;
    let params: pathParams | undefined = undefined;
    if (this.isFullScreen) {
      params = this.storage?.get('pathParams') as pathParams
    } else {
      if (pathParamsLen) {
        params = this.pathInfos.getParamByName('videoPreview')[pathParamsLen - 1] as pathParams;
      }
    }
    if (params) {
      this.isFromRingtoneList = params.isFromRingtoneList;
      this.isBindSheet = params.isBindSheet
      this.fd = params.fd;
      this.videoUriPathSp = params.pathUrl;
    }
    this.registerSettingsKeyChange();
    this.registerCallStateChange()

    let blender: uiEffect.BrightnessBlender = uiEffect.createBrightnessBlender({
      cubicRate: 0.0,
      quadraticRate: 0.0,
      linearRate: 0.5895,
      degree: 0.46,
      saturation: 1.5,
      positiveCoefficient: [2, 2.2, 0.5],
      negativeCoefficient: [1.2, 1.8, 1],
      fraction: 0
    });
    this.advancedBlendmode = uiEffect.createBrightnessBlender({
      cubicRate: 0.0,
      quadraticRate: 0.0,
      linearRate: 0.3573,
      degree: 0.0904,
      saturation: 1.5,
      positiveCoefficient: [7, 10, 7],
      negativeCoefficient: [11, 11, 7.9],
      fraction: 0
    });
    this.visualEffortBackground.backgroundColorBlender(blender);
    this.updateBtnsRowWidth();
    this.changeButtonSize();
  }

  changeButtonSize(): void {
    const defaultTextSize: number = this.getNumberByResource($r('sys.float.ohos_id_text_size_button1'));
    const minTextBtnWidth: number = 76;
    const minTextBtnHeight: number = 32;
    let fontScale: number = 1;
    try {
      fontScale = Number(settings.getValueSync(getContext(), 'font_scale', '1', settings.domainName.USER_PROPERTY));
    } catch (e) {
      LogUtils.e(TAG, 'get font_scale error');
    }
    let cancelTextSize: SizeOptions = measure.measureTextSize({
      textContent: $r('app.string.InfoEdit_back'),
      fontSize: px2vp(defaultTextSize) * Math.min(fontScale, MAX_FONT_SCALE) + 'vp'
    });
    let applyTextSize: SizeOptions = measure.measureTextSize({
      textContent: $r('app.string.use'),
      fontSize: px2vp(defaultTextSize) * Math.min(fontScale, MAX_FONT_SCALE) + 'vp'
    });
    this.maxTextButtonWidth = Math.max(px2vp(Math.max(Number(cancelTextSize.width), Number(applyTextSize.width))) +
      SAFE_TEXT_PADDING * 2, minTextBtnWidth);
    this.maxTextButtonHeight = Math.max(px2vp(Math.max(Number(cancelTextSize.height), Number(applyTextSize.height))),
      minTextBtnHeight);
  }

  /**
   * get number by resource
   *
   * @param {Resource} resource
   * @return {number} resource name
   */
  getNumberByResource(res: Resource): number {
    let resNumber: number = getContext().resourceManager.getNumber(res);
    return resNumber;
  }

  fullScreenShow() {
    LogUtils.i(TAG, `fullScreenShow: ${this.isBackground}`);
    if (this.isBackground) {
      this.videoPreviewShow = false;
      this.playVideoModel?.pausePlay();
      this.isVideoPaused = true;
    } else {
      this.videoPreviewShow = true;
      if (this.isVideoPaused) {
        this.playVideoModel?.rePlay();
      }
    }
  }

  aboutToDisappear(): void {
    LogUtils.i(TAG, `videoPreview aboutToDisappear is called`);
    if (this.sizeUpdateCallback !== undefined) {
      this.playVideoModel?.removeSizeUpdateCallback(this.sizeUpdateCallback)
    }
    this.playVideoModel?.releasePlay();
    this.unRegisterSettingsKeyChange();
    offCallStateChange();
  }

  private getFlexAlign(type: string) {
    if (this.curBp === 'sm' || this.curBp === 'xs' || this.curBp === 'lg') {
      return FlexAlign.Center;
    }
    if (type === 'msg') {
      return FlexAlign.Center;
    } else if (type === 'remind') {
      return FlexAlign.Center;
    }
    return FlexAlign.Center;
  }

  build() {
    NavDestination() {
      Stack() {
        this.buildBackground()
        this.showLocalVideoFunc()
        this.showMaskingLayerFunc(false);
        this.mainlyView()
      }
      .expandSafeArea([SafeAreaType.KEYBOARD])
    }
    .hideTitleBar(true)
    .hideToolBar(true)
    .backButtonIcon(this.backIcon)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM, SafeAreaEdge.TOP])
    .backgroundColor($r('sys.color.background_secondary'))
    .onShown(() => {
      this.videoPreviewShow = true;
      if (this.isVideoPaused) {
        this.playVideoModel?.rePlay();
      }
    })
    .onHidden(() => {
      this.videoPreviewShow = false;
      this.playVideoModel?.pausePlay();
      this.isVideoPaused = true;
    })
    .onBackPressed(() => {
      this.playVideoModel?.releasePlay();
      LogUtils.i(TAG, `onBackPressed isFullScreen: ${this.isFullScreen}`);
      if (!this.isFullScreen) {
        this.pathInfos.pop('cancel');
      }
      return true;
    })
  }

  getCallPrimaryLabelMarginBottom() {
    if (this.isNewFoldPhoneInnerScreen) {
      return $r('sys.float.padding_level2');
    }
    if (isTwoInOne() || TrifoldManager.getInstance().isTrifold()) {
      return '5vp';
    }
    return $r('sys.float.padding_level1');
  }

  private isThreeBtnOrCurbpType(): boolean {
    return this.btnList?.length === 3 && this.curBp !== 'sm' && this.curBp !== 'xs';
  }

  getFuncBtnRowWidth(): number {
    this.updateBtnsRowWidth();
    return this.funcBtnRowWidth;
  }

  private updateBtnsRowWidth() {
    if (this.btnList?.length !== 3 || this.curBp === 'sm' || this.curBp === 'xs') {
      return;
    }
    let gridWidth = CallColumnUtils.getInstance().getGridWidth(this.curBp);
    let rowSpaceSize: number = CallColumnUtils.getInstance().getRowSpace(this.curBp);
    let btnWidth = (((gridWidth + rowSpaceSize) * (this.curBp === 'md' ? 3 : 4)) - 16) / 2;
    this.funcBtnRowWidth = btnWidth * 3 + 16;
    this.incomingBtnWidth = (gridWidth + rowSpaceSize) * (this.curBp === 'md' ? 6 : 8) - rowSpaceSize;
  }

  getAnswerBtnTop(): number {
    if (SplitScreenManager.getInstance().isIncomingSpliteScreenMedium()) {
      return 16;
    }
    return 32;
  }

  updateVideoFromStr(videoFrom: string) {
    LogUtils.i(TAG, 'updateVideoFromStr is called, videoFrom = ' + videoFrom);
    if (this.isBindSheet) {
      this.updateContactVideoFrom = videoFrom;
    } else {
      this.updateVideoFrom = videoFrom;
    }
  }

  refreshVideoSize() {
    let componentWidth: number = componentUtils.getRectangleById('xComponentId').size.width;
    let componentHeight: number = componentUtils.getRectangleById('xComponentId').size.height;
    LogUtils.i(TAG, 'refreshVideoSize is called, with = ' + componentWidth);
    LogUtils.i(TAG, 'refreshVideoSize is called, height = ' + componentHeight);
    let componentRatio: number = componentWidth / componentHeight;
    let videoWith = this.videoSize.width;
    let videoHeight = this.videoSize.height;
    let videoRatio: number = videoWith / videoHeight;
    let finalWith: number = videoWith;
    let finalHeight: number = videoHeight;
    if (componentRatio > 1 && videoRatio > 1 || componentRatio < 1 && videoRatio < 1) {
      let ratio = Math.max(componentWidth / videoWith, componentHeight / videoHeight);
      finalWith = videoWith * ratio;
      finalHeight = videoHeight * ratio;
      this.xComponentController.setXComponentSurfaceRect({
        surfaceWidth: componentWidth, // 单位px
        surfaceHeight: componentHeight // 单位px
      });
    } else if (componentRatio > 1 && videoRatio < 1 || componentRatio < 1 && videoRatio > 1) {
      // 屏幕宽度大于高度， 视频宽度小于高度， 高度填充，宽度左右剩余黑边
      let ratio = Math.min(componentWidth / videoWith, componentHeight / videoHeight);
      finalWith = videoWith * ratio;
      finalHeight = videoHeight * ratio;
      this.xComponentController.setXComponentSurfaceRect({
        surfaceWidth: finalWith, // 单位px
        surfaceHeight: finalHeight // 单位px
      });
    }
  }

  @Builder
  mainlyView() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      this.TopButton();
      this.IncomingCom();
    }.width('100%')
    .height('100%')
    .padding({ bottom: 64 })
    .accessibilityLevel('no')
  }

  @Builder
  TopButton() {
    Stack({ alignContent: Alignment.TopStart }) {
      Row() {
        Button() {
          Text($r('app.string.InfoEdit_back'))
            .draggable(false)
            .fontSize($r('sys.float.ohos_id_text_size_button1'))
            .maxFontScale(MAX_FONT_SCALE)
            .align(Alignment.Center)
            .fontWeight(FontWeight.Medium)
            .foregroundColor('#FFFFFFFF')
            .advancedBlendMode(this.advancedBlendmode)
            .margin({ top: 1 })
        }
        .fontColor($r('sys.color.font_primary'))
        .constraintSize({ minHeight: 32, minWidth: 76 })
        .backgroundColor('#FFFFFFFF')
        .visualEffect(this.visualEffortBackground)
        .align(Alignment.Center)
        .hoverEffect(HoverEffect.Scale)
        .borderRadius($r('sys.float.corner_radius_level10'))
        .size({
          width: this.maxTextButtonWidth,
          height: this.maxTextButtonHeight,
        })
        .onClick(async () => {
          LogUtils.i(TAG, `cancel button is called: ${this.isFullScreen}`)
          await this.playVideoModel?.releasePlay();
          if (this.isFullScreen) {
            await this.session.sendData({ 'back': 'pop' });
            AppStorage.setOrCreate('isFullScreenCancel', true);
          } else {
            this.pathInfos.pop('cancel');
          }
        })

        Button() {
          Text($r('app.string.use'))
            .draggable(false)
            .fontSize($r('sys.float.ohos_id_text_size_button1'))
            .maxFontScale(MAX_FONT_SCALE)
            .fontWeight(FontWeight.Medium)
            .foregroundColor('#FFFFFFFF')
            .advancedBlendMode(this.advancedBlendmode)
            .margin({ top: 1 })
        }
        .fontColor($r('sys.color.font_primary'))
        .constraintSize({ minHeight: 32, minWidth: 76 })
        .backgroundColor('#FFFFFFFF')
        .visualEffect(this.visualEffortBackground)
        .align(Alignment.Center)
        .hoverEffect(HoverEffect.Scale)
        .borderRadius($r('sys.float.corner_radius_level10'))
        .size({
          width: this.maxTextButtonWidth,
          height: this.maxTextButtonHeight,
        })
        .onClick(async () => {
          LogUtils.i(TAG, 'apply button is called');
          await this.playVideoModel?.releasePlay();
          if (this.isFromRingtoneList) {
            systemSoundManager.getSystemSoundManager()?.setRingtoneUri(getContext(this), this.videoUriPathSp,
              Number(this.simCard)).then(() => {
              LogUtils.e(TAG, `handleVideoData, successful setting of the system ringtone uri.`);
            }).catch((err: BusinessError) => {
              LogUtils.e(TAG, `handleVideoData, failed to set the system ringtone uri ${err}`);
            });
            await VideoRingtoneHandler.saveUriListToSp(this.videoUriPathSp, this.simCard);
            this.updateVideoFromStr('VideoRingtoneManagePage');
          } else {
            this.updateVideoFromStr('VideoRingtonePage');
          }
          if (this.isFullScreen) {
            this.session.sendData({ 'back': 'pop' });
          } else {
            this.pathInfos.pop();
          }
        })
      }
      .width('100%')
      .padding({ top: 16 + (this.isBindSheet ? 0 : this.statusBarHeight), left: 24, right: 24 })
      .justifyContent(FlexAlign.SpaceBetween)

      GridRow({
        columns: {
          xs: 2,
          sm: 4,
          md: 8,
          lg: 12
        },
        gutter: 24
      }) {
        GridCol({
          span: {
            xs: 2,
            sm: 4,
            md: 6,
            lg: 8
          },
          offset: { md: 1, lg: 2 }
        }) {
          Column() {
            Text(PHONE_NUMBER)
              .fontSize(38)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('sys.color.font_on_primary'))
              .maxLines(1)
              .maxFontScale(1)
              .maxFontSize(38)
              .minFontSize(20)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .textAlign(TextAlign.Center)
              .accessibilityText('[n1]123 [n1]4567 XXXX')
              .margin({ bottom: this.getCallPrimaryLabelMarginBottom() })
          }.margin({ top: 113.5 - this.maxTextButtonHeight })
        }
      }
      .margin({ top: 16 + (this.isBindSheet ? 0 : this.statusBarHeight) + this.maxTextButtonHeight })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  IncomingCom() {
    GridRow({
      columns: {
        xs: 2,
        sm: 4,
        md: 8,
        lg: 12
      },
      gutter: 24
    }) {
      GridCol({
        span: {
          xs: 2,
          sm: 4,
          md: this.btnList?.length === 3 ? 8 : 6,
          lg: this.btnList?.length === 3 ? 12 : 8
        },
        offset: {
          md: this.btnList?.length === 3 ? 0 : 1,
          lg: this.btnList?.length === 3 ? 0 : 2
        }
      }) {
        this.builderIncoming();
      }
    }
    .margin({
      left: CallColumnUtils.getInstance().getPaddingSpace(this.curBp),
      right: CallColumnUtils.getInstance().getPaddingSpace(this.curBp)
    })
  }

  @Builder
  builderIncoming() {
    Column() {
      Row({ space: this.isThreeBtnOrCurbpType() ? 8 : CallColumnUtils.getInstance().getRowSpace(this.curBp) }) {
        ForEach(this.btnList, (item: btn) => {
          Row() {
            Column() {
              SymbolGlyph($r(item.iconDefaultUrl))
                .fontSize($r('app.float.wh_value_24'))
                .fontColor(['#ffffff'])
                .width(24)
                .height(24)
                .draggable(false)
                .margin({ left: 0, right: 0 })

              Text(item.iconText)
                .fontColor($r('sys.color.icon_on_primary'))
                .fontSize($r('app.float.call_card_body_m_font'))
                .height($r('app.float.call_card_body_m_height'))
                .lineHeight($r('app.float.call_card_body_m_height'))
                .opacity(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .minFontSize('14vp')
                .maxFontSize('14vp')
                .margin({
                  top: $r('sys.float.padding_level4')
                })
            }
            .accessibilityGroup(true)
          }
          .justifyContent(this.getFlexAlign(item.type))
          .layoutWeight(1)
        })
      }
      .height(51)
      .width(this.isThreeBtnOrCurbpType() && this.isFullScreen ? this.funcBtnRowWidth : null)

      Column() {
        Row({ space: CallColumnUtils.getInstance().getRowSpace(this.curBp) }) {
          Column() {
            Button() {
              Stack() {
                Circle()
                  .width(64)
                  .height(64)
                  .borderRadius('32vp')
                  .fill('#e84026')
                  .margin({ left: 0, right: 0 })

                SymbolGlyph($r('sys.symbol.phone_down_fill'))
                  .width($r('app.float.answer_button_image_width'))
                  .height($r('app.float.answer_button_image_width'))
                  .fontColor(['#FFFFFF'])
                  .fontSize($r('app.float.answer_button_image_width'))
                  .draggable(false)
              }
            }
            .backgroundColor(Color.Transparent)
            .id('call_phone_down_fill')
          }
          .margin({ left: 0, right: 0 })
          .alignSelf(ItemAlign.Center)
          .layoutWeight(1)

          Column() {
            Stack() {
              Button()
                .backgroundColor($r('sys.color.confirm'))
                .width(64)
                .height(64)
                .borderRadius(32)

              SymbolGlyph($r('sys.symbol.phone_fill'))
                .width($r('app.float.answer_button_image_width'))
                .height($r('app.float.answer_button_image_width'))
                .fontColor(['#FFFFFF'])
                .fontSize($r('app.float.answer_button_image_width'))
                .draggable(false)
            }
            .margin({ left: 0, right: 0 })
            .alignSelf(ItemAlign.Center)
            .onAreaChange((oldValue: Area, newValue: Area) => {
              let startPoint: number = Number(newValue.position.x);
              let centerPoint: number = startPoint + 68 / 2;
              AppStorage.setOrCreate('incomingCenterPoint', centerPoint);
            })
            .id('call_answerBtn')
          }
          .layoutWeight(1)
        }
      }.margin({ top: this.getAnswerBtnTop() })
    }.width(this.isThreeBtnOrCurbpType() && this.isFullScreen ? this.incomingBtnWidth : null);
  }

  @Builder
  buildBackground() {
    this.showMaskingLayerFunc(true);
  }

  @Builder
  showLocalVideoFunc() {
    // 代码优化： 和 Index 里的xcomponent 代码高度相似，抽取出一个组件，
    Column() {
      XComponent({
        type: XComponentType.SURFACE,
        controller: this.xComponentController,
      }).onLoad(async () => {
        LogUtils.i(TAG, 'onLoad is started')
        this.surfaceID = this.xComponentController.getXComponentSurfaceId();
        this.sizeUpdateCallback = ((curWith: number, curHeight: number) => {
          this.videoSize.width = curWith;
          this.videoSize.height = curHeight;
          this.refreshVideoSize();
        });
        this.playVideoModel?.addSizeUpdateCallback(this.sizeUpdateCallback);
        LogUtils.i(TAG, 'onLoad is called')
        this.playVideoModel?.playVideoByFd(this.fd, this.surfaceID);
      }).expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        .onSizeChange(() => {
          // 记录内部的高度
          this.refreshVideoSize();
          if (isTablet() || DisplayUtil.isFoldable() && !DisplayUtil.isFoldedStatus()) {
            this.updateBtnsRowWidth();
          }
        })
    }
    .id('xComponentId')
    .width('100%').height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]);
  }

  @Builder
  showMaskingLayerFunc(isBackgroundColor: boolean) {
    Column()
      .backgroundColor(isBackgroundColor ? $r('app.color.background_color') : $r('app.color.normal_call_bg_color'))
      .height('100%')
      .width('100%')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]);
  }

  registerSettingsKeyChange() {
    try {
      settings.registerKeyObserver(getContext(), 'contact_window_status',
        settings.domainName.USER_SECURITY, () => {
          let windowStatus =
            settings.getValueSync(getContext(), 'contact_window_status', '-1', settings.domainName.USER_SECURITY)
          LogUtils.i(TAG, 'windowStatus = ' + windowStatus);
          this.checkMultiWindow(Number(windowStatus))
        });
      settings.registerKeyObserver(getContext(), 'settings.windowMode',
        settings.domainName.DEVICE_SHARED, () => {
          let windowStatus =
            settings.getValueSync(getContext(), 'settings.windowMode', '-1', settings.domainName.DEVICE_SHARED)
          LogUtils.i(TAG, 'windowStatus2 = ' + windowStatus);
          this.checkMultiWindow(Number(windowStatus))
        });
    } catch (error) {
      LogUtils.e(TAG, 'Error in registering key observer');
    }
  }

  registerCallStateChange() {
    onCallStateChange((data: observer.CallStateInfo) => {
      if (!data) {
        LogUtils.e(TAG, 'onCallStateChange: data is null');
        return;
      }
      LogUtils.i(TAG, 'onCallStateChange: json = ' + JSON.stringify(data))
      if (data.state === call.CallState.CALL_STATE_IDLE || data.state === call.CallState.CALL_STATE_UNKNOWN) {
        if (this.videoPreviewShow) {
          this.playVideoModel?.rePlay();
        }
      }
    });
  }

  unRegisterSettingsKeyChange() {
    try {
      settings.unregisterKeyObserver(getContext(), 'contact_window_status', settings.domainName.USER_SECURITY);
      settings.unregisterKeyObserver(getContext(), 'settings.windowMode', settings.domainName.DEVICE_SHARED);
    } catch (error) {
      LogUtils.e(TAG, 'Error in registering key observer');
    }
  }

  checkMultiWindow(windowType: number) {
    if (windowType == window.WindowStatusType.SPLIT_SCREEN || windowType == window.WindowStatusType.FLOATING) {
      promptAction.showToast({
        message: $r('app.string.video_ringtone_small_no_show'),
        duration: 2000
      });
      this.playVideoModel?.releasePlay();
      if (this.isFullScreen) {
        this.session.sendData({ 'back': 'pop' });
        AppStorage.setOrCreate('isFullScreenCancel', true);
      } else {
        this.pathInfos.pop('cancel');
      }
    }
  }
}