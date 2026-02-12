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

import { LengthMetrics, OperationType, SubHeader, TextModifier, uiExtensionHost, window } from '@kit.ArkUI';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import { hiTraceMeter } from '@kit.PerformanceAnalysisKit';
import displaySync from '@ohos.graphics.displaySync';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import { CardSection } from './model/CardSection';
import { Card } from './model/Card';
import GalleryButton from './GalleryButton';
import VideoRingtoneList from './VideoRingtoneList';
import promptAction from '@ohos.promptAction';
import VideoRingtoneHandler, {
  DUPLICATE_ERROR_MESSAGE,
  ERROR_TOAST_TIME,
  KEY_DUPLICATE_NUMBER,
  VideoSetErrorType } from './VideoRingtoneHandler';
import VideoRingtoneEmpty from './VideoRingtoneEmpty';
import { Constants, LogUtils, sharedPreferencesUtils } from '@ohos/common';
import { FileUtils } from '../../common/utils/presenter/FileUtils';
import { BusinessError, settings } from '@kit.BasicServicesKit';
import fs from '@ohos.file.fs';
import { systemSoundManager } from '@kit.AudioKit';
import { AlertDialog } from '@ohos.arkui.advanced.Dialog';
import { isTablet } from '../../common/utils/DeviceTypeUtils';

const VIDEO_PAGE_INDEX_APPEAR_TASK_ID = 1003;
const VIDEO_RINGTONE_SUBWINDOW = 'subWindowForVideoTingtone';
const TAG = 'VideoRingtonePage';

export interface pathParams {
  pathUrl: string;
  fd: number;
  isFromRingtoneList: boolean;
  isBindSheet: boolean;
}

@Entry
@Component
struct VideoRingtonePage {
  @Provide('pathInfos') pathInfos: NavPathStack = new NavPathStack();
  @StorageProp('statusBottomHeight') statusBottomHeight: number = 0;
  @StorageProp('fontSizeScaleMargin') fontSizeScaleMargin: string = '';
  @StorageProp('topMarginOnScal') topMarginOnScal: string = '10vp';
  @StorageProp('bottomMarginOnScal') bottomMarginOnScal: string = '11vp';
  @State isHideBackButton: boolean = false;
  @State primaryModifier: TextModifier = new TextModifier().fontColor(Color.Black);
  @State secondaryModifier: TextModifier = new TextModifier().fontColor(Color.Gray);
  @State @Watch('modelUpdate') model?: CardSection = undefined;
  @State modelNum: number = 0;
  @BuilderParam videoRingtoneManagePageLoader: () => void;
  @BuilderParam videoPreviewLoader: () => void;
  @StorageLink('isManagePage') isManagePage: boolean = false;
  @StorageLink('needUpdateContactView') @Watch('updateVideo') updateVideoFrom: string = '';
  @StorageLink('videoPreviewShow') videoPreviewShow: boolean = false;
  public storage = LocalStorage.getShared();
  scroller: Scroller = new Scroller();
  section: number = 0;
  onCardClick?: (selectedCard: Card, index: number) => void;
  myDisplaySync: displaySync.DisplaySync = displaySync.create();
  fileName: string = '';
  videoUriPathSp: string = '';
  isFollowingSystemFontScale: boolean = false;
  maxAppFontScale: number = 1;
  private photoSelectOptionsHalf = new photoAccessHelper.PhotoSelectOptions();
  private session: UIExtensionContentSession =
    this.storage?.get<UIExtensionContentSession>('session') as UIExtensionContentSession;
  private uri: string = '';
  private simCard: string = this.storage?.get<string>('simCard') as string;
  private contactsPath: string = this.storage?.get<string>('contactsPath') as string;
  private sysSoundManager: systemSoundManager.SystemSoundManager = systemSoundManager.getSystemSoundManager();
  @State isLoading: boolean = false;
  extensionWindow: uiExtensionHost.UIExtensionHostWindowProxy | undefined =
    this.session?.getUIExtensionHostWindowProxy();
  subWindow: window.Window | undefined = undefined;
  private listParentWidth: number = 0;

  settingOnReceiveSuccess(videoRingtoneName: string, path: string): void {
    LogUtils.i(TAG, 'settingOnReceiveSuccess start videoRingtoneName : ' + videoRingtoneName);
    this.session?.sendData({
      'ringtoneName': videoRingtoneName,
      'isShowUIExtension': true,
      'path': path
    })
    LogUtils.i(TAG, 'settingOnReceiveSuccess end');
  }

  backOnReceiveSuccess(): void {
    LogUtils.i(TAG, 'backOnReceiveSuccess start');
    this.session?.sendData({
      'isShowUIExtension': false
    })
  }

  async loadPage(key: string): Promise<void> {
    try {
      if (key === 'videoRingtoneManagePage') {
        let pageObj = await import('./VideoRingtoneManagePage');
        this.videoRingtoneManagePageLoader = pageObj.videoRingtoneManagePageLoader;
      } else if (key === 'videoPreview') {
        let pageObj = await import('./videoPreview');
        this.videoPreviewLoader = pageObj.videoPreviewLoader;
      }
    } catch (err) {
      LogUtils.e(TAG, 'loadPage import error');
    }
  }

  @Builder
  myRouter(name: string, params: Record<string, number>) {
    if (name === 'videoRingtoneManagePage') {
      if (this.videoRingtoneManagePageLoader != null) {
        this.videoRingtoneManagePageLoader();
      }
    } else if (name === 'videoPreview') {
      if (this.videoPreviewLoader != null) {
        this.videoPreviewLoader();
      }
    }
  }

  async aboutToAppear() {
    hiTraceMeter.startTrace('aboutToAppear', VIDEO_PAGE_INDEX_APPEAR_TASK_ID);
    LogUtils.i(TAG, 'aboutToAppear');
    // 半模态选项
    this.photoSelectOptionsHalf.MIMEType = photoAccessHelper.PhotoViewMIMETypes.VIDEO_TYPE;
    this.photoSelectOptionsHalf.maxSelectNumber = 1;
    this.photoSelectOptionsHalf.isOriginalSupported = true;
    this.photoSelectOptionsHalf.isEditSupported = false;
    // 单选兼容模式
    this.photoSelectOptionsHalf.singleSelectionMode = 1;
    this.photoSelectOptionsHalf.subWindowName = VIDEO_RINGTONE_SUBWINDOW;
    this.isLoading = true;
    // 获取当前铃声和历史铃声
    let cardList: Card[] = await VideoRingtoneHandler.readVideoRingtoneDataSection(this.simCard,
      Constants.VIDEO_RINGTONE_SOURCE_CONTACT, this.contactsPath);
    this.model = new CardSection({ cards: cardList });
    this.isLoading = false;
    this.modelNum = this.model?.getDataArray()?.length;
    try {
      sharedPreferencesUtils.init(getContext(this));
    } catch (e) {
      LogUtils.e(TAG, 'aboutToAppear end error : ' + JSON.stringify(e));
    }
    hiTraceMeter.finishTrace('aboutToAppear', VIDEO_PAGE_INDEX_APPEAR_TASK_ID);
  }

  async onPageShow(): Promise<void> {
    LogUtils.i(TAG, 'onPageShow');
    this.isManagePage = false;
  }

  onPageHide(): void {
    LogUtils.i(TAG, 'onPageHide');
  }

  aboutToDisappear(): void {
    LogUtils.i(TAG, 'aboutToDisappear');
  }

  @Styles
  pressedStyles() {
    .backgroundColor($r('sys.color.interactive_click'))
    .padding({
      left: $r('sys.float.padding_level0'),
      right: $r('sys.float.padding_level0')
    })
    .borderRadius($r('sys.float.corner_radius_level8'))
  }

  @Styles
  normalStyles() {
    .backgroundColor($r('sys.color.ohos_id_color_background_transparent'))
  }

  @Builder
  CustomSettingsNavBar() {
    Row() {
      Row() {
        this.backButton();
        Column() {
          Text($r('app.string.video_ringtone'))
            .fontSize('20vp')
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.icon_primary'))
            .textAlign(TextAlign.Start)
            .constraintSize({
              maxWidth: 'calc(100% - 48vp - 48vp)',
              maxHeight: `100%`
            })
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .accessibilityRole(AccessibilityRoleType.TITLE_BAR)
        }
        .layoutWeight(1)
        .margin({ start: LengthMetrics.vp(8) })
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Start)
      }.justifyContent(FlexAlign.Start)
      .layoutWeight(1)
      this.closeButton();
    }
    .width('100%')
    .height('56vp')
    .padding({
      left: $r('app.float.margin_16'),
      right: $r('app.float.margin_16')
    })
  }

  @Builder
  closeButton(): void {
    Button({ type: ButtonType.Circle }) {
      SymbolGlyph($r('sys.symbol.xmark'))
        .draggable(false)
        .fontSize('18vp')
        .fontColor([$r('sys.color.ohos_id_color_primary')])
    }
    .id('save_click_btn')
    .draggable(false)
    .width('40vp')
    .height('40vp')
    .buttonStyle(ButtonStyleMode.NORMAL)
    .alignSelf(ItemAlign.Center)
    .stateEffect(true)
    .onClick(() => {
      this.onBackPress();
    })
    .accessibilityText($r('app.string.close_button'))
  }

  @Builder
  backButton(): void {
    Button({ type: ButtonType.Circle }) {
      SymbolGlyph($r('sys.symbol.chevron_backward'))
        .width(24)
        .height(24)
        .draggable(false)
        .fontSize('24vp')
        .fontColor([$r('sys.color.ohos_id_color_primary')])
    }
    .id('backButton')
    .draggable(false)
    .width('40vp')
    .height('40vp')
    .backgroundColor($r('sys.color.ohos_id_color_text_field_sub_bg'))
    .onClick(() => {
      this.onBackPress();
    })
    .accessibilityText($r('app.string.InfoEdit_back'))
  }

  onBackPress(): boolean | void {
    if (this.pathInfos.size() === 0) {
      this.backOnReceiveSuccess();
    } else {
      this.pathInfos.pop()
    }
    return true;
  }

  build() {
    Navigation(this.pathInfos) {
      Scroll() {
        Column() {
          GalleryButton({
            isFromContact: true,
            onButtonClick: () => {
              this.jumpToPhotoPicker();
            }
          });

          SubHeader({
            primaryTitle: $r('app.string.my_video_ringtone'),
            operationType: OperationType.TEXT_ARROW
          }).id('ListParentPage').onSizeChange(() => {
            this.listParentWidth = this.getUIContext()
              .getComponentUtils()
              .getRectangleById('ListParentPage')
              .size
              .width;
          })
          if (this.isLoading) {
            Stack({ alignContent: Alignment.Center }) {
              LoadingProgress()
                .width(40)
                .color($r('sys.color.ohos_id_color_progress'))
            }.layoutWeight(1).margin({ bottom: this.statusBottomHeight + 'vp' })
          } else {
            if (this.modelNum == 0) {
              VideoRingtoneEmpty({ isFromContact: true });
            } else {
              VideoRingtoneList({
                model: this.model,
                parentWidth: this.listParentWidth,
                onCardSelected: (card, index): void => this.onCardSelected(card, index)
              });
            }
          }
        }
        .width('100%')
      }
      .align(Alignment.Top)
      .scrollable(ScrollDirection.Vertical)
      .height('100%')
      .width('100%')
    }
    .title({
      builder: () => {
        this.CustomSettingsNavBar()
      },
      height: TitleHeight.MainOnly
    })
    .padding({
      top: this.videoPreviewShow ? 0 : 8,
      left: !this.videoPreviewShow && isTablet() ? 8 : 0,
      right: !this.videoPreviewShow && isTablet() ? 8 : 0
    })
    .hideBackButton(true)
    // .titleMode(HdsNavigationTitleMode.Mini)
    .navDestination(this.myRouter)
    .expandSafeArea([SafeAreaType.SYSTEM])
    .mode(NavigationMode.Stack)
    .backgroundColor($r('app.color.color_bind_sheet_background'))
  }

  private onCardSelected(card: Card, index: number) {
    LogUtils.i(TAG, `onCardSelected card : ` + card.applyData);
    this.sysSoundManager.openToneList([card.applyData]).then((data) => {
      this.jumpToPreviewPage(data[0][1], card.applyData, true);
    })
  }

  jumpToPhotoPicker() {
    LogUtils.i(TAG, 'jumpToPhotoPicker');
    this.onButtonClick();
  }

  private jumpToPreviewPage(fds: number, uri: string, fromRingtoneList: boolean, isPhotoSelect = false) {
    try {
      let windowStatus =
        Number(settings.getValueSync(getContext(), 'contact_window_status', '-1', settings.domainName.USER_SECURITY));
      LogUtils.i(TAG, 'windowStatus = ' + windowStatus)
      if (windowStatus == window.WindowStatusType.SPLIT_SCREEN || windowStatus == window.WindowStatusType.FLOATING) {
        promptAction.showToast({
          message: $r('app.string.video_ringtone_small_no_show'),
          duration: 2000
        });
        return;
      }
    } catch (error) {
      LogUtils.e(TAG, 'Error in registering key observer');
    }
    let param: pathParams = {
      fd: fds,
      pathUrl: uri,
      isFromRingtoneList: fromRingtoneList,
      isBindSheet: true
    };
    this.loadPage('videoPreview');
    this.pathInfos.pushPathByName('videoPreview', param, (popInfo)=> {
      let popResult = popInfo.result as string ?? '';
      if (isPhotoSelect && popResult === 'cancel') {
        this.onButtonClick();
      }
    });
  }

  async destroySubWindow() {
    if (this.subWindow !== undefined) {
      await this.subWindow?.destroyWindow();
    }
  }

  onButtonClick() {
    let subWindowOpts: window.SubWindowOptions = {
      'title': 'This is a subwindow',
      decorEnabled: false,
      isModal: false
    };
    this.extensionWindow?.createSubWindowWithOptions(VIDEO_RINGTONE_SUBWINDOW, subWindowOpts)
      .then((subWindow: window.Window) => {
        this.subWindow = subWindow;
        if (this.subWindow === undefined) {
          return;
        }
        this.subWindow?.setWindowLayoutFullScreen(true)
        this.subWindow?.setUIContent('pages/BindSheetBackground', (err, data) => {
          if (err && err.code !== 0) {
            LogUtils.i(TAG, `Failed to show the subwindow!`);
            return;
          }
          this.subWindow?.setWindowBackgroundColor('#00000000');
          this.subWindow?.showWindow((err, data) => {
          });
          this.photoViewPickerSelect();
        });
      }).catch((error: BusinessError) => {
      LogUtils.i(TAG, `Create to show the subwindow: ${error.message}`);
    })
  }

  photoViewPickerSelect() {
    const photoViewPicker = new photoAccessHelper.PhotoViewPicker();
    let uris: string[] = [];
    photoViewPicker.select(this.photoSelectOptionsHalf).then(
      async (selectResult: photoAccessHelper.PhotoSelectResult) => {
      await this.destroySubWindow();
      uris = selectResult.photoUris;
      if (uris.length > 0) {
        this.uri = uris[0];
        if (!this.uri.toLowerCase().endsWith(Constants.VIDEO_RINGTONE_SUFFIX)) {
          promptAction.showToast({
            message: $r('app.string.video_ringtone_dialog_type_error'),
            duration: 2000
          });
          return;
        }
        let file = fs.openSync(this.uri, fs.OpenMode.READ_ONLY);
        let fileFd = file.fd;
        this.jumpToPreviewPage(fileFd, this.uri, false, true);
      }
    })
  }

  handleVideoData(videoUri: string, duplicateFileName?: string) {
    FileUtils.getVideoAssets(videoUri, async (asset: photoAccessHelper.PhotoAsset) => {
      if (asset == null) {
        LogUtils.e(TAG, 'handleVideoData asset is null');
        return;
      }
      this.isLoading = true;
      LogUtils.i(TAG, 'handleVideoData asset displayName: ' + asset.displayName);
      let duration = asset.get(photoAccessHelper.PhotoKeys.DURATION) as number;
      let size = asset.get(photoAccessHelper.PhotoKeys.SIZE);
      LogUtils.i(TAG, 'handleVideoData duration: ' + duration + ' size :' + size);
      let ringTone: systemSoundManager.ToneAttrs = systemSoundManager?.createCustomizedToneAttrs();
      let fileName: string;
      if (duplicateFileName) {
        fileName = duplicateFileName;
      } else {
        fileName = asset.get(photoAccessHelper.PhotoKeys.DISPLAY_NAME) as string
      }
      ringTone.setTitle(asset.get(photoAccessHelper.PhotoKeys.TITLE) as string);
      ringTone.setFileName(fileName);
      ringTone.setCategory(systemSoundManager.TONE_CATEGORY_CONTACTS);
      ringTone.setMediaType(1);
      // 打开fd，通过addCustomizedTone 方法添加到铃音库
      let file = fs.openSync(this.uri, fs.OpenMode.READ_ONLY);
      let fileFd = file.fd;
      this.sysSoundManager.addCustomizedTone(getContext(this), ringTone, fileFd, 0,
        asset.get(photoAccessHelper.PhotoKeys.SIZE) as number).then(async (value: string) => {
        this.settingOnReceiveSuccess(fileName, value);
        this.contactsPath = value;
        let cardList: Card[] = await VideoRingtoneHandler.readVideoRingtoneDataSection(this.simCard,
          Constants.VIDEO_RINGTONE_SOURCE_CONTACT, this.contactsPath);
        this.model = new CardSection({ cards: cardList });
        this.isLoading = false;
      }).catch(async (err: BusinessError) => {
        LogUtils.e(TAG, `addCustomizedTone error, error code: ${err.code}, error msg: ${err.message}`);
        if (err?.code === VideoSetErrorType.VIDEO_SET_ERROR_IO && err?.message === DUPLICATE_ERROR_MESSAGE) {
          let duplicateNumber = await sharedPreferencesUtils.getFromPreferences(KEY_DUPLICATE_NUMBER, 1) as number;
          this.handleVideoData(videoUri,
            fileName.replace(Constants.VIDEO_RINGTONE_SUFFIX, '_' + duplicateNumber + Constants.VIDEO_RINGTONE_SUFFIX));
          await sharedPreferencesUtils.saveToPreferences(KEY_DUPLICATE_NUMBER, duplicateNumber + 1);
          return;
        }
        this.showErrorRemind(err);
        this.isLoading = false;
      });
    });
  }

  showErrorRemind(err: BusinessError) {
    switch (err?.code ?? -1) {
      case VideoSetErrorType.VIDEO_SET_ERROR_MAX_SIZE:
        promptAction.showToast({
          message: $r('app.string.video_ringtone_size_limit', Constants.VIDEO_RINGTONE_MAX_SIZE_STR,
            Constants.VIDEO_RINGTONE_MAX_SIZE_STR),
          duration: ERROR_TOAST_TIME
        });
        break;
      case VideoSetErrorType.VIDEO_SET_ERROR_LIMIT_COUNT:
        let openExpandDialog: CustomDialogController = new CustomDialogController({
          builder: AlertDialog({
            primaryTitle: $r('app.string.video_ringtone_dialog_Exceeding_limit_title'),
            content: $r('app.string.video_ringtone_dialog_Exceeding_limit_content'),
            primaryButton: {
              value: $r('app.string.gotIt'),
              fontColor: $r('sys.color.font_emphasize'),
              action: () => {
                openExpandDialog.close();
              }
            },
          }),
          autoCancel: false,
          showInSubWindow: true,
        })
        openExpandDialog.open();
        break;
      case VideoSetErrorType.VIDEO_SET_ERROR_NO_SPACE:
        promptAction.showToast({
          message: $r('app.string.video_ringtone_dialog_no_space'),
          duration: ERROR_TOAST_TIME
        });
        break;
      default:
        promptAction.showToast({
          message: $r('app.string.video_ringtone_dialog_system_error'),
          duration: ERROR_TOAST_TIME
        });
    }
  }

  modelUpdate() {
    LogUtils.i(TAG, 'needUpdate model length: ' + this.model?.getDataArray()?.length);
    if (this.model?.getDataArray()?.length == null) {
      this.modelNum = 0;
    } else {
      this.modelNum = this.model?.getDataArray()?.length;
    }
  }

  updateVideo() {
    LogUtils.i(TAG, 'updateVideo is called, this.updateVideoFrom = ' + this.updateVideoFrom);
    if (this.updateVideoFrom === 'VideoRingtonePage') {
      this.handleVideoData(this.uri)
    }
    this.updateVideoFrom = '';
  }
}