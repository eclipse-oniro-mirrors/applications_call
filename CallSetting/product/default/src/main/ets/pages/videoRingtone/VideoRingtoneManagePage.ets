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

import { EditableLeftIconType, EditableTitleBar, LengthMetrics, ToolBarOptions } from '@kit.ArkUI';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import { hiTraceMeter } from '@kit.PerformanceAnalysisKit';
import displaySync from '@ohos.graphics.displaySync';
import { Card } from './model/Card';
import { CardSection } from './model/CardSection';
import { StringUtil } from '../../common/utils/StringUtil';
import VideoRingtoneList from './VideoRingtoneList';
import VideoRingtoneHandler from './VideoRingtoneHandler';
import { AlertDialog } from '@ohos.arkui.advanced.Dialog';
import { Constants, LogUtils, sharedPreferencesUtils, TitleBarLayout } from '@ohos/common';
import { systemSoundManager } from '@kit.AudioKit';
import { manageParams } from './VideoRingtoneSettings';
import { isPhone } from '../../common/utils/Utils';
import { isDevicePortrait } from '../../common/utils/DeviceTypeUtils';
// import { NavDestination,  HdsNavDestinationAttribute, NavigationTitleBarOptions } from '@kit.UIDesignKit';

const VIDEO_MANAGE_INDEX_APPEAR_TASK_ID = 1005;
const TAG = 'VideoRingtoneManagePage';

@Builder
export function videoRingtoneManagePageLoader(): void {
  VideoRingtoneManagePage();
}

@Component
export default struct VideoRingtoneManagePage {
  @Consume('pathInfos') pathInfos: NavPathStack;
  public storage = LocalStorage.getShared();
  private session: UIExtensionContentSession =
    this.storage?.get<UIExtensionContentSession>('session') as UIExtensionContentSession;
  private simCard: string =
    this.storage?.get<string>('simCard') as string;
  private videoRingtoneSource: number =
    this.storage?.get<number>('videoRingtoneSource') as number;
  private contactsPath: string =
    this.storage?.get<string>('contactsPath') as string;
  scroller: Scroller = new Scroller();
  @StorageProp('statusBottomHeight') statusBottomHeight: number = 0;
  @StorageProp('fontSizeScale') fontSizeScale: number = 1;
  @StorageProp('fontSizeScaleMargin') fontSizeScaleMargin: string = '';
  @StorageProp('topMarginOnScal') topMarginOnScal: string = '10vp';
  @StorageProp('bottomMarginOnScal') bottomMarginOnScal: string = '11vp';
  @State isHideBackButton: boolean = false;
  myDisplaySync: displaySync.DisplaySync = displaySync.create();
  section: number = 0;
  @State @Watch('modelChange') model: CardSection[] = [];
  onCardClick?: (selectedCard: Card, index: number) => void;
  // 开始选择编辑
  @StorageLink('isManage') @Watch('isManageChange') isManage: boolean = false;
  // 我的视频铃声页面
  @StorageLink('isManagePage') isManagePage: boolean = false;
  @State selectList: number[] = [];
  @StorageLink('needUpdateNum') needUpdateNum: number = 0;
  @State manageNumber: number = 0;
  startManageClick?: () => void;
  @State historyVideoRingtoneNumber: number = 0;
  @State toolbarList: ToolBarOptions = new ToolBarOptions();
  @State isLoading: boolean = false;
  @StorageProp('curBp') curBp: string = '';
  private listParentWidth: number = 0;

  async aboutToAppear() {
    hiTraceMeter.startTrace('aboutToAppear', VIDEO_MANAGE_INDEX_APPEAR_TASK_ID);
    LogUtils.i(TAG, 'aboutToAppear');
    sharedPreferencesUtils.init(getContext(this));
    const pathParamsLen = this.pathInfos.getParamByName('videoRingtoneManagePage').length;
    if (pathParamsLen) {
      let params: manageParams = this.pathInfos.getParamByName('videoRingtoneManagePage')[pathParamsLen - 1] as manageParams;
      if (params.model) {
        this.model[0] = params.model;
      }
    }
    this.modelChange();
    hiTraceMeter.finishTrace('aboutToAppear', VIDEO_MANAGE_INDEX_APPEAR_TASK_ID);
  }

  aboutToDisappear(): void {
    LogUtils.i(TAG, 'aboutToDisappear');
  }

  isManageChange() {
    this.selectList = [];
    if (this.model[0] == null) {
      LogUtils.i(TAG, 'model length is null');
      return;
    }
    if (this.model[0].getDataArray() == null) {
      LogUtils.i(TAG, 'getDataArray length = 0');
      return;
    }
    this.model[0].getDataArray().forEach((item: Card) => {
      item.inSelect = false;
    })
  }

  modelChange() {
    this.historyVideoRingtoneNumber = 0;
    this.model[0]?.getDataArray()?.forEach((card: Card) => {
      if (!card.isInUse) {
        this.historyVideoRingtoneNumber++;
      }
    })
    LogUtils.i(TAG, `modelChange historyVideoRingtoneNumber : ` + this.historyVideoRingtoneNumber);
  }

  private onCardSelected(card: Card, index: number): void {
    LogUtils.i(TAG, `onCardSelected card : ` + card.applyData);
    LogUtils.i(TAG, `onCardSelected isManage : ` + this.isManage);
    if (card.inSelect) {
      LogUtils.i(TAG, `onCardSelected isInUse`);
      card.inSelect = false;
      this.selectList = this.selectList.filter(number => number !== index);
    } else {
      if (this.isManage) {
        card.inSelect = true;
      }
      if (card.noInUse) {
        LogUtils.i(TAG, `onCardSelected noInUse`);
      } else {
        LogUtils.i(TAG, `onCardSelected no noInUse`);
      }
      this.selectList.push(index);
    }
    LogUtils.i(TAG, `onCardSelected selectList length : ` + this.selectList.length);
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
    if (this.isManage) {
      Row() {
        Column() {
          Text($r('app.plural.video_ringtone_selected_tip', this.selectList.length, this.selectList.length))
            .fontSize('20vp')
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.icon_primary'))
            .textAlign(TextAlign.Start)
        }
        .layoutWeight(1)
        .margin({ start: LengthMetrics.vp(8) })
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height('56vp')
    } else {
      Row() {
        Column() {
          Text($r('app.string.my_video_ringtone'))
            .fontSize('20vp')
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.icon_primary'))
            .textAlign(TextAlign.Start)
        }
        .layoutWeight(1)
        .margin({ start: LengthMetrics.vp(8) })
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height('56vp')
    }
  }

  onBackPress(): boolean | void {
    if (this.pathInfos.size() === 0) {
      this.session.sendData({ 'action': 'pop' });
    } else {
      this.pathInfos.pop()
    }
    return true;
  }

  @Builder
  BottomButton() {
    GridRow({
      columns: {
        xs: 2,
        sm: 4,
        md: 8,
        lg: 8
      },
      gutter: { x: 24 }
    }) {
      GridCol({
        span: {
          xs: 2,
          sm: 4,
          md: 8,
          lg: isDevicePortrait() ? 8 : 6
        },
        offset: { sm: 0, md: 1, lg: 1 }
      }) {
        Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center }) {
          Flex({
            direction: FlexDirection.Column,
            justifyContent: FlexAlign.Center,
            alignItems: ItemAlign.Center
          }) {
            if (this.selectList.length == this.historyVideoRingtoneNumber && this.historyVideoRingtoneNumber != 0) {
              SymbolGlyph($r('sys.symbol.checkmark_square_on_square_fill'))
                .fontColor(['#0A59F7'])
                .fontSize('24vp')
                .width('24vp')
                .height('24vp')
                .draggable(false)
                .margin({ top: '5vp' })
              Text($r('app.string.video_ringtone_deselect_all'))
                .fontSize('10vp')
                .margin({ top: '2vp' })
                .fontColor('#0A59F7 ')
                .fontWeight(FontWeight.Medium)
                .fontFamily('HarmonyHeiTi');
            } else {
              SymbolGlyph($r('sys.symbol.checkmark_square_on_square'))
                .fontColor([$r('sys.color.ohos_id_color_primary')])
                .fontSize('24vp')
                .width('24vp')
                .height('24vp')
                .draggable(false)
                .margin({ top: '5vp' })
              Text($r('app.string.video_ringtone_select_all'))
                .fontSize('10vp')
                .margin({ top: '2vp' })
                .fontColor($r('sys.color.ohos_id_color_primary'))
                .fontWeight(FontWeight.Medium)
                .fontFamily('HarmonyHeiTi');
            }
          }
          .height(52)
          .width('50%')
          .onClick(() => {
            this.clickSelectCheckAll();
          });

          // delete button
          Flex({
            direction: FlexDirection.Column,
            justifyContent: FlexAlign.Center,
            alignItems: ItemAlign.Center
          }) {
            SymbolGlyph($r('sys.symbol.trash'))
              .width('24vp')
              .height('24vp')
              .draggable(false)
              .fontSize('24vp')
              .fontColor([$r('sys.color.ohos_id_color_primary')])
              .margin({ top: '5vp' });
            Text($r('app.string.delete'))
              .fontSize('10vp')
              .fontWeight(FontWeight.Medium)
              .fontColor($r('sys.color.ohos_id_color_primary'))
              .margin({ top: '2vp' })
              .fontFamily('HarmonyHeiTi');
          }
          .height(52)
          .width('50%')
          .opacity(this.selectList.length === 0 ? 0.4 : 1)
          .onClick(() => {
            if (this.selectList.length === 0) {
              LogUtils.i(TAG, 'deleteBlackController selectedNumber is zero no need to open')
              return
            }
            this.deleteDialogController.open();
          });
        }
        .alignRules({
          bottom: { anchor: '__container__', align: VerticalAlign.Bottom }
        })
      }
    }.alignRules({
      bottom: { anchor: '__container__', align: VerticalAlign.Bottom }
    }).margin({
      left: isPhone() ? 16 : 24,
      right: isPhone() ? 16 : 24,
    }).offset({y:-40})
  }

  @Styles
  pressedStylesOfCancel(){
    .backgroundColor($r('sys.color.ohos_id_color_click_effect'))
    .borderRadius($r('sys.float.ohos_id_corner_radius_clicked'))
  }

  @Styles
  normalStylesOfCancel(){
    .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
  }

  build() {
    NavDestination() {
      if(!this.isManage){
        this.TitleBackEdit()
      }else {
        this.TitleCancel()
      }
      Column() {
        Scroll() {
          Column() {
            if (this.isLoading) {
              Stack({ alignContent: Alignment.Center }) {
                LoadingProgress()
                  .width(40)
                  .color($r('sys.color.ohos_id_color_progress'))
              }.height('100%')
            } else {
              Column() {
                VideoRingtoneList({
                  model: this.model[0],
                  parentWidth:this.listParentWidth,
                  onCardSelected: (card, index): void => this.onCardSelected(card, index),
                });
              }.width('100%')
            }
          }.id('ListParentManage').width('100%').layoutWeight(1).onSizeChange(() => {
            this.listParentWidth = this.getUIContext()
              .getComponentUtils()
              .getRectangleById('ListParentManage')
              .size
              .width;
          })
        }
        .align(Alignment.Top)
        .scrollable(ScrollDirection.Vertical)
        .width('100%')
        .layoutWeight(1)
        .padding({ top: '8vp' })
        .clip(false)

        if (this.isManage) {
          this.BottomButton();
        }
      }
    }
    // .titleBar(this.isManage ? this.selectTitle(): this.title())
    //.title(this.myTitleBar)
    .hideTitleBar(true)
    .onShown(() => {
      LogUtils.i(TAG, 'onShown');
      this.isManagePage = true;
    })
    .onHidden(() => {
      LogUtils.i(TAG, 'onHidden');
      this.isManagePage = false;
    })
    .padding({ bottom: this.statusBottomHeight })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM, SafeAreaEdge.TOP])
    .backgroundColor($r('sys.color.background_secondary'))
    .onBackPressed(() => {
      return this.destinationBackPress();
    })
  }

  /**
   * 我的视频铃声标题：返回键 + 标题 + 编辑菜单栏
   */
  // private title(): NavigationTitleBarOptions {
  //   return {
  //     style: {
  //       scrollEffectOpts: {
  //         enableScrollEffect: false
  //       },
  //       originalStyle: {
  //         backgroundStyle: {
  //           backgroundColor: $r('sys.color.background_secondary')
  //         }
  //       }
  //     },
  //     avoidLayoutSafeArea: true,
  //     enableComponentSafeArea: true,
  //     content: {
  //       title: {
  //         mainTitle: $r('app.string.my_video_ringtone'),
  //       },
  //       backIcon: {
  //         label: $r('app.string.InfoEdit_back'),
  //         icon: $r('sys.symbol.chevron_backward')
  //       },
  //       menu: {
  //         value: [
  //           {
  //             content: {
  //               label: $r('app.string.InfoEdit_edits_info'),
  //               icon: $r('sys.symbol.square_and_pencil'),
  //               action: () => {
  //                 LogUtils.i(TAG, 'isManage');
  //                 this.isManage = true;
  //               }
  //             }
  //           }
  //         ]
  //       }
  //     }
  //   };
  // }
  @Builder
  TitleBackEdit(){
    Row(){
      EditableTitleBar({
        title:$r('app.string.my_video_ringtone'),
        //contentMargin:{top:LengthMetrics.px(10)},
        isSaveIconRequired: false,
        onCancel:()=>{
          this.onBackPress()
        }
      })
        .layoutWeight(1)
      Image($r('app.media.edit'))
        .height(36)
        .width(36)
        .padding(6)
        //.margin({top:LengthMetrics.px(10)})
        .backgroundColor('rgba(0, 0, 0, 0.05)')
        .borderRadius(18)
        .onClick(()=>{
          LogUtils.i(TAG, 'isManage');
          this.isManage = true;
        })
    }
    .margin({ end:LengthMetrics.vp(18)})
  }


  /**
   * 进入编辑标题: 关闭键 + 标题
   */
  // private selectTitle(): NavigationTitleBarOptions {
  //   return {
  //     style: {
  //       scrollEffectOpts: {
  //         enableScrollEffect: false
  //       },
  //       originalStyle: {
  //         backgroundStyle: {
  //           backgroundColor: $r('sys.color.background_secondary')
  //         }
  //       }
  //     },
  //     avoidLayoutSafeArea: true,
  //     enableComponentSafeArea: true,
  //     content: {
  //       title: {
  //         mainTitle: $r('app.plural.video_ringtone_selected_tip', this.selectList.length,
  //           this.selectList.length),
  //       },
  //       backIcon: {
  //         label: $r('app.string.close_button'),
  //         icon: $r('sys.symbol.xmark')
  //       },
  //       menu: undefined
  //     }
  //   };
  // }
  @Builder
  TitleCancel(){
    EditableTitleBar({
      title:$r('app.string.my_video_ringtone'),
      //contentMargin:{top:LengthMetrics.px(10)},
      isSaveIconRequired: false,
      leftIconStyle:EditableLeftIconType.Cancel,
      onCancel:()=>{
        this.isManage = false
      }
    })
      //.margin({start:LengthMetrics.vp(24), end:LengthMetrics.vp(24)})
  }

  deleteDialogController: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: $r('app.string.video_ringtone_delete_dialog_tip1'),
      primaryButton: {
        value: $r('app.string.cancel'),
        action: () => {
          LogUtils.i(TAG, 'deleteDialogCancel');
        }
      },
      secondaryButton: {
        value: $r('app.string.delete'),
        role: ButtonRole.ERROR,
        action: () => {
          LogUtils.i(TAG, 'deleteDialogConfirm');
          this.clickDelete();
        }
      },
    }),
    alignment: DialogAlignment.Center,
    showInSubWindow: true,
    autoCancel: true,
    maskColor: $r('sys.color.ohos_id_color_mask_thin'),
    closeAnimation: { duration: 100 },
  })

  destinationBackPress(): boolean {
    LogUtils.i(TAG, 'destinationBackPress start');
    if (this.isManage) {
      this.isManage = false;
      return true;
    } else {
      return false;
    }
  }

  clickSelectCheckAll() {
    LogUtils.i(TAG, 'clickSelectCheckAll');
    if (!this.model[0]) {
      LogUtils.i(TAG, 'model length is null');
      return;
    }
    if (!this.model[0].getDataArray()) {
      LogUtils.i(TAG, 'getDataArray length = 0');
      return;
    }
    if (this.selectList.length == this.historyVideoRingtoneNumber) {
      this.selectList.forEach((index: number) => {
        this.model[0].getDataArray().forEach((card: Card) => {
          if (card.historyIndex == index) {
            card.inSelect = false;
          }
        })
      })
      this.selectList = [];
    } else {
      this.selectList = [];
      this.model[0].getDataArray().forEach((item: Card) => {
        if (!item.isInUse) {
          this.selectList.push(item.historyIndex);
          item.inSelect = true;
        }
      })
    }
    LogUtils.i(TAG, 'clickSelectCheckAll selectList length: ' + this.selectList.length);
  }

  clickDelete() {
    LogUtils.i(TAG, 'clickDelete');
    if (this.selectList.length > 0) {
      this.deleteVideoRingtoneList(this.selectList);
    }
  }

  async deleteVideoRingtoneList(selectList: number[]) {
    let videoRingtoneHistoryDataList: string[] = await VideoRingtoneHandler.getHistoryVideoRingtoneData(this.simCard);
    if (videoRingtoneHistoryDataList.length <= 0) {
      LogUtils.e(TAG, 'deleteVideoRingtoneList videoRingtoneHistoryDataList.length <= 0');
      return;
    }
    let systemSoundManagerInstance: systemSoundManager.SystemSoundManager = systemSoundManager.getSystemSoundManager();
    let strArr: string[] = [];
    this.isLoading = true;
    for (let i = 0; i < selectList.length; i++) {
      let path: string = 'undefined';
      this.model[0]?.getDataArray()?.forEach((card: Card) => {
        if (card.historyIndex == selectList[i]) {
          path = card.applyData;
        }
      })
      if (StringUtil.isEmpty(path)) {
        LogUtils.e(TAG, 'deleteVideoRingtoneList path is null');
        continue;
      }
      let otherCardContain = await VideoRingtoneHandler.checkPathContainOnAnotherCard(this.simCard, path);
      LogUtils.i(TAG, 'deleteVideoRingtoneList otherCardContain = ' + otherCardContain);
      if (otherCardContain) {
        // 当前视频有其他卡在使用，不能删除视频文件，只删除指向
        LogUtils.e(TAG, 'deleteVideoRingtoneList checkPathContainOnAnotherCard is true');
        continue;
      }
      strArr.push(path);
    }
    if (strArr.length > 0) {
      systemSoundManagerInstance.removeCustomizedToneList(strArr).then((data) => {
      })
    }
    await this.deleteVideoRingtoneFromSp(videoRingtoneHistoryDataList, selectList);
    let cardList: Card[] = await VideoRingtoneHandler.readVideoRingtoneDataSection(this.simCard,
      Constants.VIDEO_RINGTONE_SOURCE_SETTING, this.contactsPath);
    LogUtils.i(TAG, 'deleteVideoRingtoneList cardList length: ' + cardList.length);
    this.model[0] = new CardSection({ cards: cardList });
    this.isManage = false;
    this.needUpdateNum++;
    this.isLoading = false;
    this.selectList = [];
    if (cardList.length == 0) {
      this.pathInfos.pop();
    }
  }

  async deleteVideoRingtoneFromSp(videoRingtoneHistoryDataList: string[], selectList: number[]) {
    LogUtils.i(TAG, 'deleteVideoRingtoneFromSp start videoRingtoneHistoryDataList length: ' +
    videoRingtoneHistoryDataList.length);
    videoRingtoneHistoryDataList =
      VideoRingtoneHandler.removeElementsByIndices(videoRingtoneHistoryDataList, selectList);
    let videoRingtoneHistoryData = StringUtil.arrayToString(videoRingtoneHistoryDataList.reverse());
    let videoRingtoneHistoryArraySp: string = Constants.VIDEO_RINGTONE_HISTORY_DATA_SP + this.simCard;
    sharedPreferencesUtils.saveToPreferences(videoRingtoneHistoryArraySp, videoRingtoneHistoryData);
    if (selectList.includes(-1)) {
      // -1 代表当前使用的视频也要呗删除，所以要把缓存的preference一并删除
      let videoRingtoneSp: string = Constants.VIDEO_RINGTONE_DATA_SP + this.simCard;
      sharedPreferencesUtils.saveToPreferences(videoRingtoneSp, '');
    }
  }
}