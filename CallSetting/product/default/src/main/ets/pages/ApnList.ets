/*
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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

import {
  LogUtils,
  ApnListCommon,
  ApnParamClass,
  DataListClass,
  ParamsType,
  ReportUtil,
  MobileDataGlobalContextHelper,
  Constants,
  TitleBarLayout
} from '@ohos/common/CommonIndex';
import { LoadingDialog } from '@ohos.arkui.advanced.Dialog';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import { SubHeader } from '@ohos.arkui.advanced.SubHeader';
import { display, EditableTitleBar, uiExtensionHost, window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { getPaddingByDevice } from '../common/utils/Utils';
import MdApnDetail from './MdApnDetail';
import { LengthMetrics } from '@kit.ArkUI';
import { DynamicLoader } from '../common/control/DynamicLoader';
import { common } from '@kit.AbilityKit';
import { CLOSE_SATELLITE_NETWORK_BUTTON } from '../common/constant/CallSettingsConstant';

// import { NavDestination ,  HdsNavDestinationAttribute} from '@hms.hds.hdsBaseComponent';

const TAG = 'apnIndex';

@Builder
export function apnLoader(): void {
  apn();
}

@Component
export default struct apn {
  @State @Watch('watchCommon') common: ApnListCommon = new ApnListCommon();
  @StorageLink('hasSimCard1') @Watch('watchHasSim') hasSimCard1: boolean = false;
  @StorageLink('hasSimCard2') @Watch('watchHasSim') hasSimCard2: boolean = false;
  @State dataList: DataListClass[] = [];
  @State dataMMSList: DataListClass[] = [];
  @StorageProp('selectId') selectId: number = -1;
  @Consume('pathInfos') pathInfos: NavPathStack;
  @StorageProp('foldStatus') foldStatus: number = -1;
  public storage = LocalStorage.getShared();
  private session: UIExtensionContentSession =
    this.storage?.get<UIExtensionContentSession>('session') as UIExtensionContentSession;
  @State showMenu: boolean = false;
  @State menuTitles: Array<Resource> = [$r('app.string.APN_Creating_an_APN'),
    $r('app.string.APN_Reset_to_Default')];
  @StorageProp('curBp') curBp: string = '';
  @StorageProp('fontSizeScale') fontSizeScale: number = 1;
  @StorageProp('fontSizeScaleMargin') fontSizeScaleMargin: string = '';
  @StorageProp('apnList') @Watch('watchApnList') apnListTest: number = 0;
  @State isFoldable: boolean = false;
  @State isShowBind: boolean = false;

  extensionWindow: uiExtensionHost.UIExtensionHostWindowProxy | undefined =
    this.session?.getUIExtensionHostWindowProxy();
  subWindow: window.Window | undefined = undefined;
  mainWindowId: number = 0;
  uiContextInSubWindow: UIContext | undefined = undefined;

  dialogLoading: CustomDialogController = new CustomDialogController({
    builder: LoadingDialog({
      content: $r('app.string.APN_Restoring_default_APN_settings')
    }),
    customStyle: false,
    autoCancel: false,
    showInSubWindow: true,
  });

  watchCommon() {
    this.dataList = this.common.dataList;
    this.dataMMSList = this.common.mmsDataList;
  }

  pushApnDetails(params: ParamsType) {
    DynamicLoader.getInstance().callFunction('apnDetails').then(() => {
      this.pathInfos.pushPathByName('apnDetails', params);
    });
  }

  async watchApnList() {
    let obj: ApnParamClass = this.pathInfos.getParamByName('apnIndex')[this.pathInfos.getParamByName('apnIndex')
      .length - 1] as ApnParamClass;
    if (await this.common.initSim(obj.cardType)) {
      await this.common.getMccmnc();
      await this.common.getAllApnList();
      await this.common.getSelectApn();
    } else {
      this.pathInfos.pop();
      LogUtils.e(TAG, 'aboutToAppear getParams null');
    }
    LogUtils.i(TAG, '[cardType]' + JSON.stringify(this.common.cardType));
    this.common.getPreferApn();
  }

  watchHasSim() {
    LogUtils.i(TAG, 'hasSimCard1:' + this.hasSimCard1 + ' hasSimCard2:' + this.hasSimCard2);
    // Temporarily return to the previous page, which is more friendly behavior.
    if (this.common.cardType === 0) {
      if (!this.hasSimCard1) {
        this.pathInfos.pop();
      }
    } else if (this.common.cardType === 1) {
      if (!this.hasSimCard2) {
        this.pathInfos.pop();
      }
    }
  }

  async aboutToAppear() {
    try {
      // this.isFoldable = display.isFoldable()
    } catch (err) {
      LogUtils.e(TAG, `aboutToAppear: isFoldable error: ${err?.code} ${err?.message}`);
    }
    let obj: ApnParamClass = this.pathInfos.getParamByName('apnIndex')[this.pathInfos.getParamByName('apnIndex')
      .length - 1] as ApnParamClass;
    LogUtils.i(TAG, '[obj]' + JSON.stringify(obj));
    if (await this.common.initSim(obj.cardType)) {
      await this.common.getMccmnc();
      await this.common.getAllApnList();
      await this.common.getSelectApn();
    } else {
      this.pathInfos.pop();
      LogUtils.e(TAG, 'aboutToAppear getParams null');
    }
    LogUtils.i(TAG, '[cardType]' + JSON.stringify(this.common.cardType));
    this.common.getPreferApn();
  }

  async showInit() {
    await this.common.getAllApnList();
    this.common.getPreferApn();
  }

  @Builder
  listHeader(titleContent: Resource) {
    SubHeader({ secondaryTitle: titleContent })
      .margin({ start: LengthMetrics.vp(-16) })
  }

  async getSubWindow() {
    let subWindowOpts: window.SubWindowOptions = {
      'title': 'This is a subwindow',
      decorEnabled: false,
      isModal: false
    };

    this.extensionWindow?.createSubWindowWithOptions('subWindowForHost', subWindowOpts)
      .then((subWindow: window.Window) => {
        this.subWindow = subWindow;
        if (this.subWindow === undefined) {
          return;
        }
        this.subWindow.setWindowLayoutFullScreen(true)
        this.subWindow?.setUIContent('pages/BindSheetBackground', (err, data) => {
          if (err && err.code !== 0) {
            LogUtils.i(TAG, `#zhb# Failed to show the subwindow!`);
            return;
          }
          this.subWindow?.setWindowBackgroundColor('#0000ff00');
          this.uiContextInSubWindow = this.subWindow?.getUIContext();
          this.isShowBind = true;
          this.subWindow?.showWindow((err, data) => {
          });
        });
      }).catch((error: BusinessError) => {
        LogUtils.i(TAG, `#zhb# Create to show the subwindow: ${JSON.stringify(error)}`);
    })
  }

  @Builder
  apnDetailContent() {
    Column() {
      MdApnDetail({
        isShowBind: $isShowBind
      })
    }
    .width('100%')
    .height('100%')
    .draggable(false)
  }

  build() {
    NavDestination() {
      Row(){
        EditableTitleBar({
          title:$r('app.string.APN_TITLE'),
          // menuItems: [
          //   {
          //     value: $r('app.string.APN_Creating_an_APN'),
          //     action: () => {
          //       let params: ParamsType = {
          //         cardType: this.common.cardType,
          //         simId: this.common.simId,
          //         mccmnc: this.common.mccmnc,
          //         profileID: -1,
          //         isDefault: 1
          //       };
          //       ReportUtil.getInstance().reportClickCreateApn();
          //       if (this.isFoldable) {
          //         AppStorage.setOrCreate('apnDetail', params);
          //         this.getSubWindow();
          //       } else {
          //         this.isShowBind = false;
          //         this.pushApnDetails(params);
          //       }}
          //   },
          //   {
          //     value: $r('app.string.APN_Reset_to_Default'),
          //     action: () => {
          //       this.dialogLoading.open();
          //       this.common.dataReset().then((data: boolean) => {
          //         this.dialogLoading.close();
          //       });
          //       ReportUtil.getInstance().reportClickResetDefaultApn();
          //     }
          //   }
          // ],
          isSaveIconRequired: false,
          contentMargin:{top:LengthMetrics.px(100)},
          onCancel:()=>{
            this.pathInfos.pop()
          }
        })
          .layoutWeight(1)
        Image($r("app.media.ic_public_more"))
          .height(36)
          .width(36)
          .margin({top:LengthMetrics.px(100)})
          //.backgroundEffect({color:Color.Transparent})

        .bindMenu(this.MyMenu)
        // .backgroundColor($r('sys.color.background_secondary'))
      }
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({start:LengthMetrics.vp(24), end:LengthMetrics.vp(24)})
      Column(){
        GridRow({ columns: { xs: 2, sm: 4, md: 8, lg: 12 }, gutter: { x: 24 } }) {
          GridCol({ span: { xs: 2, sm: 4, md: 8, lg: 12 }, offset: { sm: 0, md: 1, lg: 2 } }) {
            this.listContentBuilder()
          }
        }
      }.layoutWeight(1)
    }
    .hideTitleBar(true)
    .height('100%')
    // .titleBar({
    //   style: {
    //     scrollEffectOpts: {
    //       enableScrollEffect: false
    //     },
    //     originalStyle: {
    //       backgroundStyle: {
    //         backgroundColor: $r('sys.color.background_secondary')
    //       }
    //     }
    //   },
    //   avoidLayoutSafeArea: true,
    //   enableComponentSafeArea: true,
    //   content: {
    //     title: { mainTitle: $r('app.string.APN_TITLE') },
    //     menu: {
    //       maxCount: 1,
    //       value: [
    //         {
    //           content: {
    //             label: $r('app.string.APN_Creating_an_APN'),
    //             action: () => {
    //               let params: ParamsType = {
    //                 cardType: this.common.cardType,
    //                 simId: this.common.simId,
    //                 mccmnc: this.common.mccmnc,
    //                 profileID: -1,
    //                 isDefault: 1
    //               };
    //               ReportUtil.getInstance().reportClickCreateApn();
    //               if (this.isFoldable) {
    //                 AppStorage.setOrCreate('apnDetail', params);
    //                 this.getSubWindow();
    //               } else {
    //                 this.isShowBind = false;
    //                 this.pushApnDetails(params);
    //               }
    //             }
    //           }
    //         },
    //         {
    //           content: {
    //             label: $r('app.string.APN_Reset_to_Default'),
    //             action: () => {
    //               this.dialogLoading.open();
    //               this.common.dataReset().then((data: boolean) => {
    //                 this.dialogLoading.close();
    //               });
    //               ReportUtil.getInstance().reportClickResetDefaultApn();
    //             }
    //           }
    //         }
    //       ]
    //     }
    //   },
    // })
    //.title(this.myTitleBar)
    .onShown(() => {
      this.showInit();
    })
    .bindSheet(this.getBindState(), this.apnDetailContent(), {
      height: '100%',
      showClose: false,
      preferType: this.foldStatus === 2 ? SheetType.BOTTOM : SheetType.CENTER,
      uiContext: this.uiContextInSubWindow,
      onDisappear: () => {
        this.isShowBind = false;
        this.subWindow?.destroyWindow((err) => {});
      },
    })
    .backgroundColor($r('sys.color.background_secondary'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM, SafeAreaEdge.TOP])
  }

  getBindState(): boolean {
    return this.isFoldable ? this.isShowBind : false;
  }

  @Builder
  listContentBuilder() {
    List() {
      if (this.dataList.length > 0) {
        this.apnCommonBuilder()
      }
      if (this.dataMMSList.length > 0) {
        ListItemGroup({ header: this.listHeader($r('app.string.APN_MMS')) }) {
          this.listItemGroupContentBuilder()
        }.padding({ bottom: $r('sys.float.padding_level6') });
      }
    }
    .padding({
      left: getPaddingByDevice(),
      right: getPaddingByDevice()
    })
    .cachedCount(20)
    .size({ height: 'calc(100% - 56vp)' })
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    .clip(false)
  }

  @Builder
  listItemGroupContentBuilder() {
    ForEach(this.dataMMSList, (item: DataListClass, index?: number) => {
      ListItem() {
        this.listItemBuilder(item, index);
      }
      .backgroundColor($r('sys.color.comp_background_primary'))
      .borderRadius({
        topLeft: index === 0 ? $r('sys.float.corner_radius_level10') : 0,
        topRight: index === 0 ? $r('sys.float.corner_radius_level10') : 0,
        bottomLeft: this.dataMMSList.length - 1 === index ? $r('sys.float.corner_radius_level10') : 0,
        bottomRight: this.dataMMSList.length - 1 === index ? $r('sys.float.corner_radius_level10') : 0
      });
    }, (item: DataListClass) => JSON.stringify(item))
  }

  @Builder
  listItemBuilder(item: DataListClass, index: number | undefined) {
    Column() {
      mmsButton({
        buttonData: item,
        index,
        common: this.common,
        onEditAPN: ((params: ParamsType) => {
          if (this.isFoldable) {
            AppStorage.setOrCreate('apnDetail', params);
            this.getSubWindow();
          } else {
            this.pushApnDetails(params);
          }
        })
      })
        .margin({
          top: index === 0 ? $r('sys.float.padding_level2') : 0,
          bottom: this.dataMMSList.length - 1 === index ? $r('sys.float.padding_level2') : 0
        })
        .id(`callSetting_pages_apnList_mmsButton_${item.id}`);
      Divider()
        .color($r('sys.color.comp_divider'))
        .lineCap(LineCapStyle.Round)
        .margin({ left: $r('sys.float.padding_level6'), right: $r('sys.float.padding_level6') })
        .visibility(this.dataMMSList.length - 1 === index ? Visibility.None : Visibility.Visible)
        .id(`callSetting_pages_apnList_mmsButton_Divider_${item.id}`);
    }
  }

  @Builder
  apnCommonBuilder() {
    ListItemGroup({ header: this.listHeader($r('app.string.APN_common')) }) {
      ForEach(this.dataList, (item: DataListClass, index?: number) => {
        ListItem() {
          Column() {
            if (item.apnTypes === 'dun') {
              this.apnCommonNoSelectBuilder(item, index);
            } else {
              apnButton({
                buttonData: item,
                selectId: this.selectId,
                index,
                common: this.common,
                onEditAPN: ((params: ParamsType) => {
                  if (this.isFoldable) {
                    AppStorage.setOrCreate('apnDetail', params);
                    this.getSubWindow();
                  } else {
                    this.pushApnDetails(params);
                  }
                })
              })
                .margin({
                  top: index === 0 ? $r('sys.float.padding_level2') : 0,
                  bottom: this.dataList.length - 1 === index ? $r('sys.float.padding_level2') : 0
                })
                .id(`callSetting_pages_apnList_apnButton_${this.selectId}`);
            }
            Divider()
              .color($r('sys.color.comp_divider'))
              .lineCap(LineCapStyle.Round)
              .margin({ left: $r('sys.float.padding_level24'), right: $r('sys.float.padding_level6') })
              .visibility(this.dataList.length - 1 === index ? Visibility.None : Visibility.Visible)
              .id(`callSetting_pages_apnList_apnButton_Divider_${this.selectId}`);
          };
        }
        .backgroundColor($r('sys.color.comp_background_primary'))
        .borderRadius({
          topLeft: index === 0 ? $r('sys.float.corner_radius_level10') : 0,
          topRight: index === 0 ? $r('sys.float.corner_radius_level10') : 0,
          bottomLeft: this.dataList.length - 1 === index ? $r('sys.float.corner_radius_level10') : 0,
          bottomRight: this.dataList.length - 1 === index ? $r('sys.float.corner_radius_level10') : 0
        });
      }, (item: DataListClass) => JSON.stringify(item));
    }
  }

  @Builder
  apnCommonNoSelectBuilder(item: DataListClass, index?: number) {
    mmsButton({
      buttonData: item,
      index,
      common: this.common,
      onEditAPN: ((params: ParamsType) => {
        if (this.isFoldable) {
          AppStorage.setOrCreate('apnDetail', params);
          this.getSubWindow();
        } else {
          this.pushApnDetails(params);
        }
      })
    })
      .margin({
        top: index === 0 ? $r('sys.float.padding_level2') : 0,
        bottom: this.dataList.length - 1 === index ? $r('sys.float.padding_level2') : 0
      })
      .id(`callSetting_pages_apnList_apnButton_${item.id}`);
  }

  @Builder
  myTitleBar(){
    TitleBarLayout(
      $r('app.string.APN_TITLE'),
      $r('sys.color.background_secondary'),
      false,
      undefined,
      undefined,
      {
        value:[
          {
            value: $r('app.string.APN_Creating_an_APN'),
            action: () => {
          let params: ParamsType = {
            cardType: this.common.cardType,
            simId: this.common.simId,
            mccmnc: this.common.mccmnc,
            profileID: -1,
            isDefault: 1
          };
          ReportUtil.getInstance().reportClickCreateApn();
          if (this.isFoldable) {
            AppStorage.setOrCreate('apnDetail', params);
            this.getSubWindow();
          } else {
            this.isShowBind = false;
            this.pushApnDetails(params);
          }
        }
          },
          {
            value: $r('app.string.APN_Reset_to_Default'),
            action: () => {
              this.dialogLoading.open();
              this.common.dataReset().then((data: boolean) => {
                this.dialogLoading.close();
              });
              ReportUtil.getInstance().reportClickResetDefaultApn();
            }
          }

        ]
      }
    )
  }

  @Builder
  MyMenu(){
    Menu(){
      MenuItem({content: $r('app.string.APN_Creating_an_APN')})
        .onClick(()=> {
            let params: ParamsType = {
              cardType: this.common.cardType,
              simId: this.common.simId,
              mccmnc: this.common.mccmnc,
              profileID: -1,
              isDefault: 1
            };
            ReportUtil.getInstance().reportClickCreateApn();
            if (this.isFoldable) {
              AppStorage.setOrCreate('apnDetail', params);
              this.getSubWindow();
            } else {
              this.isShowBind = false;
              this.pushApnDetails(params);
            }
          })
      MenuItem({content: $r('app.string.APN_Reset_to_Default')})
        .onClick(()=>{
          this.dialogLoading.open();
          this.common.dataReset().then((data: boolean) => {
            this.dialogLoading.close();
          });
          ReportUtil.getInstance().reportClickResetDefaultApn();
        })
    }
  }
}

@Component
struct apnButton {
  @Prop buttonData: DataListClass = new DataListClass();
  @Prop index: number = -1;
  @Link selectId: number;
  @Link common: ApnListCommon;
  @Consume('pathInfos') pathInfos: NavPathStack;
  @StorageProp('fontSizeScale') fontSizeScale: number = 1;
  @StorageProp('fontSizeScaleMargin') fontSizeScaleMargin: string = '';
  private context: Context = MobileDataGlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constants.SETTINGS_ABILITY_CONTEXT);
  onEditAPN: (params: ParamsType) => void = () => {
  };

  @Styles
  normalStyles() {
    .backgroundColor(Color.Transparent)
  }

  @Styles
  pressedStyles() {
    .backgroundColor($r('sys.color.interactive_click'))
    .padding({
      left: $r('sys.float.padding_level0'),
      right: $r('sys.float.padding_level0')
    })
    .borderRadius($r('sys.float.corner_radius_level9'))
  }

  async selectButton() {
    await this.common.selectApnCommon(this.buttonData.id);
  }

  getText(): string {
    let str = this.buttonData.title + ' ' + this.buttonData.msg + ' ';
    if (this.selectId === this.buttonData.id) {
      str += this.context?.resourceManager.getStringSync($r('app.string.talkback_selected').id);
    } else {
      str += this.context?.resourceManager.getStringSync($r('app.string.talkback_not_selected').id);
    }
    return str;
  }

  build() {
    GridRow({ columns: { xs: 2, sm: 4, md: 8, lg: 12 }, gutter: { x: 24 } }) {
      GridCol({ span: { xs: 2, sm: 4, md: 8, lg: 12 }, offset: { sm: 0, md: 1, lg: 2 } }) {
        Column() {
          Column() {
            Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
              Row() {
                Radio({ value: '', group: 'radioGroup0' })
                  .touchable(false)// If touchable, Radio will always consume the touch event before it's parent!
                  .checked(this.selectId === this.buttonData.id)
                  .radioStyle({
                    checkedBackgroundColor: $r('sys.color.comp_background_emphasize'),
                    indicatorColor: $r('sys.color.comp_background_primary_contrary')
                  })
                  .height(20)
                  .width(20)
                  .margin($r('sys.float.padding_level1'))
                  .onChange((isChecked: boolean) => {
                    LogUtils.i(TAG, 'Radio1 status is ' + isChecked);
                  })
                  .responseRegion({
                    width: 0,
                    height: 0
                  })
                  .accessibilityLevel('yes')

                Flex({
                  direction: FlexDirection.Column,
                  justifyContent: FlexAlign.SpaceBetween,
                  alignItems: ItemAlign.Start
                }) {
                  Text(this.buttonData.title)
                    .fontSize($r('sys.float.Subtitle_M'))
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('sys.color.font_primary'))
                    .textAlign(TextAlign.Start)
                    .constraintSize({ minHeight: 22 })
                    .margin({ top: this.fontSizeScale < 1.75 ? $r('sys.float.padding_level5') :
                    this.fontSizeScaleMargin })

                  Text(this.buttonData.msg)
                    .fontSize($r('sys.float.Subtitle_S'))
                    .fontWeight(FontWeight.Regular)
                    .fontColor($r('sys.color.font_secondary'))
                    .textAlign(TextAlign.Start)
                    .constraintSize({ minHeight: 20 })
                    .margin({
                      top: $r('sys.float.padding_level1'),
                      bottom: this.fontSizeScale < 1.75 ? $r('sys.float.padding_level5') : this.fontSizeScaleMargin
                    })
                }
                .layoutWeight(1)
                .margin({ left: $r('sys.float.padding_level8'), right: $r('sys.float.padding_level8') })
              }
              .constraintSize({ minHeight: 64 })
              .onClick(async () => {
                await this.selectButton();
              })
              .padding({ left: $r('sys.float.padding_level4'), right: $r('sys.float.padding_level4') })

              Button() {
                SymbolGlyph($r('sys.symbol.info_circle'))
                  .fontSize($r('app.float.wh_value_24'))
                  .fontColor([$r('sys.color.comp_foreground_primary')])
                  .draggable(false)
              }
              .accessibilityLevel('yes')
              .onClick(() => {
                this.onEditAPN({
                  cardType: this.common.cardType,
                  simId: this.common.simId,
                  mccmnc: this.common.mccmnc,
                  profileID: this.buttonData.id,
                  isDefault: this.buttonData.isDefault
                });
              })
              .constraintSize({ minHeight: 48 })
              .width(24)
              .margin({ left: $r('sys.float.padding_level2'), right: $r('sys.float.padding_level4') })
              .accessibilityText($r('app.string.details'))
              .backgroundColor($r('sys.color.comp_background_primary'))
            }
          }
        }
        .backgroundColor($r('sys.color.comp_background_primary'))
        .margin({ left: $r('sys.float.padding_level2'), right: $r('sys.float.padding_level2') })
        .borderRadius($r('sys.float.corner_radius_level10'))
        .accessibilityGroup(true)
        .accessibilityText(this.getText())
      }
    }
  }
}

@Component
struct mmsButton {
  @Prop buttonData: DataListClass = new DataListClass();
  @Prop index: number = -1;
  @Link common: ApnListCommon;
  @State selectRadio: boolean = false;
  @Consume('pathInfos') pathInfos: NavPathStack;
  @StorageProp('fontSizeScale') fontSizeScale: number = 1;
  @StorageProp('fontSizeScaleMargin') fontSizeScaleMargin: string = '';
  onEditAPN: (params: ParamsType) => void = () => {
  };

  @Styles
  pressedStyles() {
    .backgroundColor($r('sys.color.interactive_click'))
    .padding({
      left: $r('sys.float.padding_level0'),
      right: $r('sys.float.padding_level0')
    })
    .borderRadius($r('sys.float.corner_radius_level9'))
  }

  build() {
    GridRow({ columns: { xs: 2, sm: 4, md: 8, lg: 12 }, gutter: { x: 24 } }) {
      GridCol({ span: { xs: 2, sm: 4, md: 8, lg: 12 }, offset: { sm: 0, md: 1, lg: 2 } }) {
        Column() {
          Column() {
            Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
              Row() {
                Flex({
                  direction: FlexDirection.Column,
                  justifyContent: FlexAlign.SpaceBetween,
                  alignItems: ItemAlign.Start
                }) {
                  Text(this.buttonData.title)
                    .fontSize($r('sys.float.Subtitle_M'))
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('sys.color.font_primary'))
                    .textAlign(TextAlign.Start)
                    .constraintSize({ minHeight: 22 })
                    .margin({ top: this.fontSizeScale < 1.75 ? $r('sys.float.padding_level5') :
                    this.fontSizeScaleMargin })

                  Text(this.buttonData.msg)
                    .fontSize($r('sys.float.Subtitle_S'))
                    .fontWeight(FontWeight.Regular)
                    .fontColor($r('sys.color.font_secondary'))
                    .textAlign(TextAlign.Start)
                    .constraintSize({ minHeight: 20 })
                    .margin({
                      top: $r('sys.float.padding_level1'),
                      bottom: this.fontSizeScale < 1.75 ? $r('sys.float.padding_level5') : this.fontSizeScaleMargin
                    })
                }
              }
              .constraintSize({ minHeight: 64 })
              .width('100%')

              Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
                SymbolGlyph($r('sys.symbol.chevron_right'))
                  .fontSize('24vp')
                  .fontColor([$r('sys.color.icon_fourth')])
                  .draggable(false)
              }
              .constraintSize({ minHeight: $r('app.float.wh_value_48') })
              .width(12)
            }
          }
          .constraintSize({ minHeight: 64 })
          .padding({ left: $r('sys.float.padding_level4'), right: $r('sys.float.padding_level4') })
          .onClick(() => {
            this.onEditAPN({
              cardType: this.common.cardType,
              simId: this.common.simId,
              mccmnc: this.common.mccmnc,
              profileID: this.buttonData.id,
              isDefault: this.buttonData.isDefault
            });
          })
        }
        .backgroundColor($r('sys.color.comp_background_primary'))
        .margin({ left: $r('sys.float.padding_level2'), right: $r('sys.float.padding_level2') })
        .borderRadius($r('sys.float.corner_radius_level10'))
        .stateStyles({
          pressed: this.pressedStyles
        })
      }
    }
  }
}