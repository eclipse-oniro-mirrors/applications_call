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

import { LengthMetrics, OperationType, SubHeader, TextModifier, window } from '@kit.ArkUI';
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
import { Constants, LogUtils, sharedPreferencesUtils, TitleBarLayout, TitleParams } from '@ohos/common';
import { FileUtils } from '../../common/utils/presenter/FileUtils';
import { BusinessError, settings } from '@kit.BasicServicesKit';
import { systemSoundManager } from '@kit.AudioKit';
import fs from '@ohos.file.fs';
import { AlertDialog } from '@ohos.arkui.advanced.Dialog';
import ScreenAdapterUtils from '../../common/utils/ScreenAdapterUtils';
import { isTablet } from '../../common/utils/DeviceTypeUtils';
// import { Navigation, HdsNavigationAttribute, HdsNavigationTitleMode } from '@kit.UIDesignKit';

const VIDEO_SETTING_INDEX_APPEAR_TASK_ID = 1004;
const TAG = 'VideoRingtoneSettings';

export interface pathParams {
  pathUrl: string;
  fd: number;
  isFromRingtoneList: boolean;
  isBindSheet: boolean;
}

export interface manageParams {
  model: CardSection | undefined;
}

@Entry
@Component
struct VideoRingtoneSettings {
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
  @State isLoading: boolean = false;
  @BuilderParam videoRingtoneManagePageLoader: () => void;
  @BuilderParam videoPreviewLoader: () => void;
  @StorageLink('needUpdateNum') @Watch('needUpdate') needUpdateNum: number = 0;
  @StorageLink('needUpdateView') @Watch('updateVideo') updateVideoFrom: string = '';
  @StorageLink('videoPreviewShow') videoPreviewShow: boolean = false;
  @StorageProp('isFullScreenCancel') @Watch('fullScreenCancelHandle') isFullScreenCancel: boolean = false;
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
  private simCard: string = this.storage?.get<string>('simCard') as string;
  private uri: string = '';
  private sysSoundManager: systemSoundManager.SystemSoundManager = systemSoundManager.getSystemSoundManager();
  private isPhotoSelect: boolean = false;
  private listParentWidth: number = 0;

  settingOnReceiveSuccess(videoRingtoneName: string): void {
    LogUtils.i(TAG, 'settingOnReceiveSuccess start videoRingtoneName : ' + videoRingtoneName);
    this.session?.sendData({
      'ringtoneName': videoRingtoneName,
      'isShowUIExtension': true
    })
  }

  backOnReceiveSuccess(): void {
    LogUtils.i(TAG, 'backOnReceiveSuccess start');
    this.session?.sendData({
      'isShowUIExtension': false
    })
    LogUtils.i(TAG, 'backOnReceiveSuccess end');
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
  myRouter(name: string) {
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
    hiTraceMeter.startTrace('aboutToAppear', VIDEO_SETTING_INDEX_APPEAR_TASK_ID);
    LogUtils.i(TAG, 'aboutToAppear');
    // 半模态选项
    this.photoSelectOptionsHalf.MIMEType = photoAccessHelper.PhotoViewMIMETypes.VIDEO_TYPE;
    this.photoSelectOptionsHalf.maxSelectNumber = 1;
    this.photoSelectOptionsHalf.isOriginalSupported = true;
    this.photoSelectOptionsHalf.isEditSupported = false;
    // 单选兼容模式
    this.photoSelectOptionsHalf.singleSelectionMode = 1;
    try {
      sharedPreferencesUtils.init(getContext(this));
    } catch (e) {
      LogUtils.e(TAG, `aboutToAppear end error : ${e?.code}`);
    }
    this.isLoading = true;
    let cardList: Card[] = await VideoRingtoneHandler.readVideoRingtoneDataSection(this.simCard,
      Constants.VIDEO_RINGTONE_SOURCE_SETTING, '');
    this.model = new CardSection({ cards: cardList });
    this.modelNum = this.model?.getDataArray()?.length;
    this.isLoading = false;
    hiTraceMeter.finishTrace('aboutToAppear', VIDEO_SETTING_INDEX_APPEAR_TASK_ID);
  }

  onPageShow(): void {
    LogUtils.i(TAG, 'onPageShow');
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
            isFromContact: false,
            onButtonClick: () => {
              this.jumpToPhotoPicker();
            }
          }).id('ListParentSettings').onSizeChange(() => {
            this.listParentWidth = this.getUIContext()
              .getComponentUtils()
              .getRectangleById('ListParentSettings')
              .size
              .width;
          })
          if (this.modelNum === 0 || this.isLoading) {
            SubHeader({
              primaryTitle: $r('app.string.my_video_ringtone')
            })
          } else {
            SubHeader({
              primaryTitle: $r('app.string.my_video_ringtone'),
              operationType: OperationType.BUTTON,
              operationItem: [{
                value: $r('app.string.manage'),
                action: () => {
                  LogUtils.i(TAG, 'jump to VideoRingtoneManagePage');
                  this.loadPage('videoRingtoneManagePage');
                  let param: manageParams = {
                    model: this.model
                  };
                  this.pathInfos.pushPathByName('videoRingtoneManagePage', param);
                }
              }]
            })
          }
          if (this.isLoading) {
            Stack({ alignContent: Alignment.Center }) {
              LoadingProgress()
                .width(40)
                .color($r('sys.color.ohos_id_color_progress'))
            }.layoutWeight(1).margin({ bottom: this.statusBottomHeight + 'vp' })
          } else {
            if (this.modelNum === 0) {
              VideoRingtoneEmpty({ isFromContact: false });
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
      .padding({
        left: !this.videoPreviewShow && isTablet() ? 8 : 0,
        right: !this.videoPreviewShow && isTablet() ? 8 : 0
      })
      .height('100%')
      .width('100%')
      .clip(false)
    }
    // .titleBar(TitleParams.MiniTitleParams($r('app.string.video_ringtone'), $r('sys.color.background_secondary'), false,
    //   !this.videoPreviewShow))
    .title($r('app.string.video_ringtone'))
    .titleMode(NavigationTitleMode.Mini)
    .padding({top:45})
    .hideBackButton(false)
    // .titleMode(HdsHdsNavigationTitleMode.MINI)
    .navDestination(this.myRouter)
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP])
    .mode(NavigationMode.Stack)
    .backgroundColor($r('sys.color.background_secondary'))
  }


  private onCardSelected(card: Card, index: number) {
    LogUtils.i(TAG, `onCardSelected is called`);
    this.sysSoundManager.openToneList([card.applyData]).then((data) => {
      this.jumpToPreviewPage(data[0][1], card.applyData, true);
    })
  }

  jumpToPhotoPicker() {
    LogUtils.i(TAG, 'jumpToPhotoPicker');
    this.onButtonClick();
  }

  private jumpToPreviewPage(fds: number, uri: string, fromRingtoneList: boolean, isPhotoSelect = false) {
    // try {
    //   let windowStatus = Number(settings.getValueSync(getContext(), 'settings.windowMode', '-1'));
    //   LogUtils.i(TAG, 'windowStatus = ' + windowStatus)
    //   if (windowStatus == window.WindowStatusType.SPLIT_SCREEN || windowStatus == window.WindowStatusType.FLOATING) {
    //     promptAction.showToast({
    //       message: $r('app.string.video_ringtone_small_no_show'),
    //       duration: 2000
    //     });
    //     return;
    //   }
    // } catch (error) {
    //   LogUtils.e(TAG, 'Error in registering key observer');
    // }
    let param: pathParams = {
      fd: fds,
      pathUrl: uri,
      isFromRingtoneList: fromRingtoneList,
      isBindSheet: false
    };

    this.isPhotoSelect = isPhotoSelect;
    LogUtils.i(TAG, `fullScreenCancel jumpToPreviewPage: ${isPhotoSelect}`);
    if (ScreenAdapterUtils.isSettingSplitProduct()) {
      this.session.sendData({
        'videoRingtoneFullScreen': true,
        'parameters': {
          'pathParams': param,
          'simCard': this.simCard
        }
      });
    } else {
      this.loadPage('videoPreview');
      this.pathInfos.pushPathByName('videoPreview', param, (popInfo)=> {
        let popResult = popInfo.result as string ?? '';
        if (isPhotoSelect && popResult === 'cancel') {
          LogUtils.i(TAG, `videoPreview popInfo onButtonClick`);
          this.onButtonClick();
        }
      });
    }
  }

  private fullScreenCancelHandle() {
    LogUtils.i(TAG, `fullScreenCancel select: ${this.isPhotoSelect} cancel: ${this.isFullScreenCancel}`);
    if (this.isPhotoSelect && this.isFullScreenCancel) {
      setTimeout(() => {
        LogUtils.i(TAG, `fullScreenCancel onButtonClick`);
        this.onButtonClick();
      }, 50)
    }
    AppStorage.setOrCreate('isFullScreenCancel', false);
  }

  onButtonClick() {
    const photoViewPicker = new photoAccessHelper.PhotoViewPicker();
    let uris: string[] = [];
    photoViewPicker.select(this.photoSelectOptionsHalf).then((selectResult: photoAccessHelper.PhotoSelectResult) => {
      uris = selectResult.photoUris;
      if (uris.length > 0) {
        this.uri = uris[0];
        if (!this.uri.toLowerCase().endsWith(Constants.VIDEO_RINGTONE_SUFFIX)) {
          LogUtils.e(TAG, 'is not mp4 type, return.')
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

  updateVideo() {
    LogUtils.i(TAG, 'updateVideo is called, this.updateVideoFrom = ' + this.updateVideoFrom);
    if (this.updateVideoFrom === 'VideoRingtonePage') {
      this.handleVideoData(this.uri)
    } else if (this.updateVideoFrom === 'VideoRingtoneManagePage') {
      this.needUpdate();
    }
    this.updateVideoFrom = '';
  }

  handleVideoData(videoUri: string, duplicateFileName?: string) {
    FileUtils.getVideoAssets(videoUri, async (asset: photoAccessHelper.PhotoAsset) => {
      if (asset == null) {
        LogUtils.i(TAG, 'handleVideoData asset is null');
        return;
      }
      this.isLoading = true;
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
      ringTone.setCategory(systemSoundManager.TONE_CATEGORY_RINGTONE);
      ringTone.setMediaType(1);

      let file = fs.openSync(this.uri, fs.OpenMode.READ_ONLY);
      let fileFd = file.fd;
      this.sysSoundManager.addCustomizedTone(getContext(this), ringTone, fileFd, 0,
        asset.get(photoAccessHelper.PhotoKeys.SIZE) as number).then(async (value: string) => {
        this.sysSoundManager.setRingtoneUri(getContext(this), value, Number(this.simCard)).then(() => {
          LogUtils.i(TAG,
            `handleVideoData, Promise returned to indicate a successful setting of the system ringtone uri.`);
        }).catch((err: BusinessError) => {
          LogUtils.e(TAG, `handleVideoData, Failed to set the system ringtone uri ${err}`);
        });
        // 将URI 存储到本地缓存中
        await VideoRingtoneHandler.saveUriListToSp(value, this.simCard);
        this.settingOnReceiveSuccess('');
        let cardList: Card[] = await VideoRingtoneHandler.readVideoRingtoneDataSection(this.simCard,
          Constants.VIDEO_RINGTONE_SOURCE_SETTING, '');
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

  async needUpdate() {
    LogUtils.i(TAG, 'needUpdate start fileName = ' + this.fileName);
    this.settingOnReceiveSuccess(this.fileName);
    this.isLoading = true;
    let cardList: Card[] = await VideoRingtoneHandler.readVideoRingtoneDataSection(this.simCard,
      Constants.VIDEO_RINGTONE_SOURCE_SETTING, '');
    this.model = new CardSection({ cards: cardList });
    this.isLoading = false;
  }

  modelUpdate() {
    LogUtils.i(TAG, 'needUpdate model length: ' + this.model?.getDataArray()?.length);
    if (this.model?.getDataArray()?.length == null) {
      this.modelNum = 0;
    } else {
      this.modelNum = this.model?.getDataArray()?.length;
    }
  }
}