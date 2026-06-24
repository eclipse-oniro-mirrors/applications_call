/**
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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

import { MarkType } from '../../model/NumberMark';
import { NumberMarkService } from '../../model/NumberMarkService';
import { noop } from '../utils/Misc';
import { StringUtil } from '../utils/StringUtil';
import { AlertDialog, CustomContentDialog } from '@ohos.arkui.advanced.Dialog';
import DefaultCallData from '../struct/TypeUtils';
import CallColumnUtils from '../utils/CallColumnUtils';
import { isScreenLocked } from '../utils/DeviceTypeUtils';
import screenLock from '@ohos.screenLock';
import LogUtils from '../utils/LogUtils';
import { ReportUtil } from '../utils/ReportUtils/ReportUtil';
import SplitScreenManager, { SplitScreenType } from '../../model/SplitScreenManager';
import ScreenAdapterUtils from '../utils/ScreenAdapterUtils';
import Utils from '../utils/utils';

interface SimpleButtonProps {
  icon: Resource;
  text: Resource;
  handleClick?: (this: void) => void;
}

interface PredefinedMark extends SimpleButtonProps {
  markType: MarkType;
}

const TAG = 'StrangeNumberHandlerPanel';

@Component
export struct StrangeNumberHandlerPanel {
  @Consume('screenreaderStatus') screenReaderStatus: boolean;
  @Link @Watch('refreshingData') callData: DefaultCallData;
  @State accountNumber: string = '';
  @State formatNumber: string = '';
  @State private countDown: number | null = null;
  @State private timeLeft: number = 10;
  @State private isMarking: boolean = false;
  @State private isShowAddContactMenu: boolean = false;
  @StorageProp('curBp') curBp: string = '';
  @StorageLink('SplitScreenType') splitScreenType: SplitScreenType = SplitScreenType.DEFAULT;
  @StorageLink('isNewFoldPhoneExternalScreen') isNewFoldPhoneExternalScreen: boolean = false;
  @StorageLink('SplitScreenHeight') splitHeight: number = 0;
  @StorageLink('newFoldSplitPortraitScreenType') newFoldSplitPortraitScreenType: SplitScreenType =
    SplitScreenType.DEFAULT;
  private service: NumberMarkService = new NumberMarkService();
  private addToBlocklistDialogController = new CustomDialogController({
    builder: AlertDialog({
      primaryTitle: $r('app.string.addToBlocklist'),
      content: $r('app.string.addToBlockListConfirm'),
      primaryButton: {
        value: $r('app.string.cancel'),
        action: () => {
          this.handleCancelAddToBlockList();
          ReportUtil.getInstance().reportCallEndClickAddBlackListDialogAction(0);
        },
      },
      secondaryButton: {
        value: $r('app.string.confirmAdd'),
        action: () => {
          this.handleConfirmAddToBlocklist();
          ReportUtil.getInstance().reportCallEndClickAddBlackListDialogAction(1);
        },
      },
    }),
    onWillDismiss: (action: DismissDialogAction) => {
      this.handleCancelAddToBlockList();
      action.dismiss();
    },
  })

  aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear');
    this.refreshingData();
    this.startCountDown();
  }

  refreshingData(): void {
    if (this.callData) {
      this.accountNumber = this.callData.accountNumber;
      this.formatNumber = this.callData.formatNumber;
    }
  }

  aboutToDisappear(): void {
    LogUtils.i(TAG, 'aboutToDisappear');
    this.stopCountDown();
    this.addToBlocklistDialogController.close();
  }

  startCountDown() {
    LogUtils.i(TAG, 'startCountDown');
    this.countDown = setInterval(() => {
      this.timeLeft--;
      if (this.timeLeft <= 0) {
        this.stopCountDown();
        this.service.completeSetNumberMarkSteps('count down finished');
      }
    }, 1000);
  }

  stopCountDown() {
    LogUtils.i(TAG, 'stopCountDown');
    if (this.countDown !== null) {
      clearInterval(this.countDown);
      this.countDown = null;
    }
  }

  handleSaveContact = async (): Promise<void> => {
    LogUtils.i(TAG, 'handleSaveContact');
    this.stopCountDown();
    if (!await this.tryUnlock('create new contact')) {
      return;
    }
    await this.service.createNewContact(this.accountNumber);
    this.service.completeSetNumberMarkSteps('created new contact');
  }
  handleSaveExistingContact = async () => {
    LogUtils.i(TAG, 'handleSaveExistingContact');
    this.stopCountDown();
    if (!await this.tryUnlock('add to existing contact')) {
      return;
    }
    await this.service.addToExistingContact(this.accountNumber);
    this.service.completeSetNumberMarkSteps('added to existing contact');
  }
  handleAddToBlockList = async (): Promise<void> => {
    LogUtils.i(TAG, 'handleAddToBlockList');
    this.stopCountDown();
    this.addToBlocklistDialogController.open();
  }
  handleCancelAddToBlockList = () => {
    LogUtils.i(TAG, 'handleCancelAddToBlockList');
    this.addToBlocklistDialogController.close();
  }
  handleConfirmAddToBlocklist = async () => {
    LogUtils.i(TAG, 'handleConfirmAddToBlocklist');
    await this.service.addToBlockList(this.accountNumber, this.formatNumber);
    this.service.completeSetNumberMarkSteps('added to block list');
  }
  handleToggleMarkPanel = (): void => {
    LogUtils.i(TAG, 'handleToggleMarkPanel');
    this.stopCountDown();
    this.isMarking = true;
  }
  handleClose = (): void => {
    LogUtils.i(TAG, 'handleClose');
    this.stopCountDown();
    this.service.completeSetNumberMarkSteps('canceled on handler panel');
    ReportUtil.getInstance().reportEndCallClickCloseBtn();
  }

  async tryUnlock(message: string): Promise<boolean> {
    if (isScreenLocked()) {
      try {
        const unlocked = await screenLock.unlock();
        if (!unlocked) {
          this.service.completeSetNumberMarkSteps(`Not unlocked, canceled to ${message}`);
          return false;
        }
      } catch (e) {
        this.service.completeSetNumberMarkSteps(`Unlocked failed, canceled to ${message}`);
        return false;
      }
    }
    return true;
  }

  private getRoundButtonTop() {
    if (this.isNewFoldPhoneExternalScreen) {
      return 23;
    }
    if (this.newFoldSplitPortraitScreenType > SplitScreenType.DEFAULT) {
      if (this.newFoldSplitPortraitScreenType === SplitScreenType.SMALL) {
        return 2;
      } else if (this.newFoldSplitPortraitScreenType === SplitScreenType.BIG) {
        return 20;
      }
      return 8;
    }
    if (SplitScreenManager.getInstance().isFoldableLandscapeMedum(this.splitHeight)) {
      return 10;
    }
    return 16;
  }

  private getNumString(): Resource | string {
    try {
      return StringUtil.formatResourceToString($r('app.string.closeCountDown'), `${Utils.transFormNum(this.timeLeft)}`);
    } catch (error) {
      LogUtils.e(TAG, 'Failed to format resource string');
      return $r('app.string.closeCountDown', `${this.timeLeft}`)
    }
  }

  build() {
    if (!this.isMarking) {
      GridRow({ columns: { xs: 2, sm: 4, md: 8, lg: 12 }, gutter: 24 }) {
        GridCol({ span: { xs: 2, sm: 4, md: 6, lg: 8 }, offset: { md: 1, lg: 2 } }) {
          Column() {
            Grid() {
              this.gridItem()
            }
            .opacity(1)
            .columnsGap(CallColumnUtils.getInstance().getItemSpace(this.curBp, this.isNewFoldPhoneExternalScreen))
            .rowsGap($r('sys.float.padding_level8'))
            .height(this.getGridHeight())
            .columnsTemplate('1fr 1fr 1fr')
            .rowsTemplate('1fr')

            Row() {
              RoundButton({
                icon: $r('sys.symbol.xmark'),
                text: this.countDown == null ? $r('app.string.close') : this.getNumString(),
                handleClick: this.handleClose,
              })
            }
            .margin({ top: this.getRoundButtonTop() })
          }
        }
      }
      .margin({
        left: this.isNewFoldPhoneExternalScreen ? '22vp' : CallColumnUtils.getInstance().getPaddingSpace(this.curBp),
        right: this.isNewFoldPhoneExternalScreen ? '22vp' : CallColumnUtils.getInstance().getPaddingSpace(this.curBp),
      })
    } else {
      MarkNumberPanel({
        isMarking: this.isMarking,
        service: this.service,
        accountNumber: this.accountNumber,
        formatNumber: this.formatNumber,
      })
    }
  }

  private getGridHeight(): Length {
    if (this.newFoldSplitPortraitScreenType > SplitScreenType.DEFAULT) {
      if (this.newFoldSplitPortraitScreenType === SplitScreenType.SMALL) {
        // 按钮64 + 间距2 + 文本高度12
        return 78;
      }
      // 按钮64 + 间距4 + 文本高度16
      return 84;
    }
    return this.isNewFoldPhoneExternalScreen ? 77 : 87;
  }

  getAddContactMenuPlacement(): Placement {
    if (SplitScreenManager.getInstance().isSplitScreen(this.splitScreenType)) {
      return SplitScreenManager.getInstance().getStrangeNumAddMenuPlacement(this.splitScreenType);
    }
    return Placement.TopLeft;
  }

  @Builder
  gridItem() {
    GridItem() {
      RoundButton({
        icon: $r('sys.symbol.plus'),
        text: $r('app.string.saveNumber'),
        handleClick: () => {
          LogUtils.i(TAG, 'show AddContactMenu');
          this.isShowAddContactMenu = true;
        },
      })
        .bindMenu(this.isShowAddContactMenu, this.AddContactMenu, {
          placement: this.getAddContactMenuPlacement(),
          aboutToAppear: () => {
            this.stopCountDown();
          },
          aboutToDisappear: () => {
            LogUtils.i(TAG, 'hide AddContactMenu');
            this.isShowAddContactMenu = false;
          },
        });
    }

    GridItem() {
      RoundButton({
        icon: $r('sys.symbol.nosign_fill'),
        text: $r('app.string.addToBlocklist'),
        handleClick: this.handleAddToBlockList,
      });
    }

    GridItem() {
      RoundButton({
        icon: $r('sys.symbol.bookmark_fill'),
        text: $r('app.string.markAs'),
        handleClick: this.handleToggleMarkPanel,
      });
    }
  }

  @Builder
  AddContactMenu() {
    Menu() {
      this.MenuItem($r('app.string.createNewContact'), () => {
        this.isShowAddContactMenu = false;
        this.handleSaveContact();
        ReportUtil.getInstance().reportCallEndSaveUnknownNumber(0);
      })
      this.MenuDivider();
      this.MenuItem($r('app.string.addToExistingContact'), () => {
        this.isShowAddContactMenu = false;
        this.handleSaveExistingContact();
        ReportUtil.getInstance().reportCallEndSaveUnknownNumber(1);
      })
    }
  }

  @Builder
  MenuItem(content: Resource, handler: () => void) {
    MenuItem({
      content,
    })
      .padding({ left: '16vp', right: '16vp' })
      .contentFont({ size: $r('sys.float.ohos_id_text_size_body1'), weight: FontWeight.Medium })
      .contentFontColor($r('sys.color.ohos_id_color_text_primary'))
      .onClick(handler)
      .gesture(LongPressGesture().onActionEnd(handler))
      .accessibilityText(!this.screenReaderStatus ? '' : StringUtil.formatResourceToString(content))
      .accessibilityDescription($r('app.string.one_finger_double_click'))
  }

  @Builder
  MenuDivider() {
    Divider()
      .color($r('sys.color.comp_divider'))
      .lineCap(LineCapStyle.Square)
      .width(0)
      .alignSelf(ItemAlign.Stretch)
      .padding({ left: '16vp', right: '16vp' })
  }
}

@Component
struct RoundButton {
  @Prop icon: Resource;
  @Prop text: Resource | string;
  @Consume('screenreaderStatus') screenReaderStatus: boolean;
  handleClick = noop;
  @State isPressed: boolean = false;
  @StorageLink('isNewFoldPhoneExternalScreen') isNewFoldPhoneExternalScreen: boolean = false;
  @StorageLink('newFoldSplitPortraitScreenType') newFoldSplitPortraitScreenType: SplitScreenType =
    SplitScreenType.DEFAULT;

  handleTouch = (e: TouchEvent) => {
    switch (e.type) {
      case TouchType.Down:
        this.isPressed = true;
        break;
      case TouchType.Move:
        this.isPressed = true;
        break;
      case TouchType.Up:
        this.isPressed = false;
        break;
      default:
        this.isPressed = false;
        break;
    }
  }

  getRoundBtnWidth(): Resource {
    return ScreenAdapterUtils.getInstance().getFuncBtnWidth(this.isNewFoldPhoneExternalScreen);
  }

  getRoundBtnBorderRadius(): Length {
    return this.isNewFoldPhoneExternalScreen ? '28vp' : $r('sys.float.corner_radius_level16');
  }

  build() {
    Column() {
      Stack() {
        Stack() {
          Row() {
          }
          .justifyContent(FlexAlign.Center)
          .backgroundColor('rgba(255, 255, 255, 0.15)')
          .width(this.getRoundBtnWidth())
          .height(this.getRoundBtnWidth())
          .borderRadius(this.getRoundBtnBorderRadius())
        }
        .width(this.getRoundBtnWidth())
        .height(this.getRoundBtnWidth())
        .borderRadius(this.getRoundBtnBorderRadius())
        .backgroundColor(this.isPressed ? $r('sys.color.ohos_id_color_click_effect') : 'rgba(255, 255, 255, 0)')

        SymbolGlyph(this.icon)
          .fontSize('28vp')
          .width(28)
          .height(28)
          .fontColor([$r('sys.color.white')])
          .fontWeight(FontWeight.Medium)
          .draggable(false)
      }
      .width(this.getRoundBtnWidth())
      .height(this.getRoundBtnWidth())
      .borderRadius(this.getRoundBtnBorderRadius())

      Text(this.text)
        .height(this.getTextHeight())
        .margin(this.getTextMargin())
        .fontSize(this.getTextFontSize())
        .fontColor($r('sys.color.ohos_id_color_text_secondary_dark'))
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxLines(1)
        .width('100%')
        .textAlign(TextAlign.Center)
    }
    .onClick(this.handleClick)
    .gesture(LongPressGesture().onActionEnd(this.handleClick))
    .onTouch(this.handleTouch)
    .accessibilityText(this.getText())
    .accessibilityDescription($r('app.string.one_finger_double_click'))
    .width('100%')
    .accessibilityRole(AccessibilityRoleType.BUTTON)
  }

  private getTextFontSize() {
    if (this.newFoldSplitPortraitScreenType === SplitScreenType.SMALL) {
      return '9vp';
    }
    return this.newFoldSplitPortraitScreenType > SplitScreenType.SMALL ? '12vp' : '14vp';
  }

  private getTextHeight(): Length {
    if (this.newFoldSplitPortraitScreenType === SplitScreenType.SMALL) {
      return '12vp';
    }
    return this.newFoldSplitPortraitScreenType > SplitScreenType.SMALL ? '16vp' : '19vp';
  }

  private getTextMargin(): Margin | Length | LocalizedMargin {
    if (this.isNewFoldPhoneExternalScreen) {
      return { top: '2vp' };
    }
    if (this.newFoldSplitPortraitScreenType > SplitScreenType.DEFAULT) {
      if (this.icon.id === $r('sys.symbol.xmark').id && this.newFoldSplitPortraitScreenType > SplitScreenType.SMALL) {
        return { top: '0vp' };
      }
      if (this.newFoldSplitPortraitScreenType === SplitScreenType.SMALL) {
        return { top: '2vp' };
      }
      return { top: '4vp' };
    }
    return { top: '4vp' };
  }

  private getText(): string {
    if (!this.screenReaderStatus) {
      return '';
    }
    if (typeof this.text === 'string') {
      return this.text;
    }
    return StringUtil.formatResourceToString(this.text);
  }
}

@Component
struct MarkNumberPanel {
  @Consume('screenreaderStatus') screenReaderStatus: boolean;
  @Link accountNumber: string;
  @Link formatNumber: string;
  @Link isMarking: boolean;
  @StorageProp('curBp') curBp: string = '';
  private service: NumberMarkService = new NumberMarkService();
  @StorageLink('SplitScreenType') @Watch('changeSplitScreenType') splitScreenType: SplitScreenType =
    SplitScreenType.DEFAULT;
  private markButtonHeight: number = 47
  @State private markGridHeight: number = 126
  @State private markButtonRowsGap: number = 32
  @StorageLink('isNewFoldPhoneExternalScreen') isNewFoldPhoneExternalScreen: boolean = false;
  @StorageLink('newFoldSplitPortraitScreenType') @Watch('changeSplitScreenType') newFoldSplitPortraitScreenType: SplitScreenType =
    SplitScreenType.DEFAULT;

  private customMarkController: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: $r('app.string.custom'),
      contentBuilder: () => {
        this.buildMarkDialog()
      },
      contentAreaPadding: {
        left: 0,
        right: 0,
      },
    }),
    alignment: DialogAlignment.Center,
    autoCancel: false,
  });

  aboutToAppear(): void {
    this.changeSplitScreenType();
  }

  changeSplitScreenType() {
    if (this.newFoldSplitPortraitScreenType > SplitScreenType.DEFAULT) {
      if (this.newFoldSplitPortraitScreenType === SplitScreenType.SMALL) {
        this.markButtonRowsGap = 2;
        this.markGridHeight = 78;
      } else if (this.newFoldSplitPortraitScreenType === SplitScreenType.MEDIUM) {
        this.markButtonRowsGap = 4;
        this.markGridHeight = 92;
      } else if (this.newFoldSplitPortraitScreenType === SplitScreenType.BIG) {
        this.markButtonRowsGap = 32;
        this.markGridHeight = 120;
      }
      return;
    }
    if (SplitScreenManager.getInstance().isSplitScreen(this.splitScreenType)) {
      this.markButtonRowsGap = SplitScreenManager.getInstance().getStrangeNumberMarkButtonRowsGap(this.splitScreenType)
      this.markGridHeight = this.markButtonRowsGap + this.markButtonHeight * 2
    } else {
      this.markButtonRowsGap = 32
      this.markGridHeight = 126
    }
  }

  build() {
    Column() {
      GridRow({ columns: { xs: 2, sm: 4, md: 8, lg: 12 }, gutter: 24 }) {
        GridCol({ span: { xs: 2, sm: 4, md: 6, lg: 8 }, offset: { md: 1, lg: 2 } }) {
          Grid() {
            ForEach(this.getPredefinedMarks(), (props: PredefinedMark) => {
              GridItem() {
                if (props.markType === MarkType.MARK_TYPE_CUSTOM) {
                  this.customMarkButton()
                } else {
                  this.predefinedMarkButton(props)
                }
              }
              .align(Alignment.Center)
            })
          }
          .opacity(1)
          .columnsGap(CallColumnUtils.getInstance().getItemSpace(this.curBp))
          .rowsGap(this.isNewFoldPhoneExternalScreen ? '4vp' : this.markButtonRowsGap)
          .height(this.isNewFoldPhoneExternalScreen ? '98vp' : this.markGridHeight)
          .clip(false)
          .columnsTemplate('1fr 1fr 1fr 1fr')
          .rowsTemplate('1fr 1fr')
          .width('100%')
        }
      }
      .margin({
        left: CallColumnUtils.getInstance().getPaddingSpace(this.curBp),
        right: CallColumnUtils.getInstance().getPaddingSpace(this.curBp)
      })

      Row() {
        RoundButton({
          icon: $r('sys.symbol.xmark'),
          text: $r('app.string.close'),
          handleClick: () => {
            LogUtils.i(TAG, 'close mark panel');
            this.isMarking = false;
          }
        })
      }
      .margin({ top: this.isNewFoldPhoneExternalScreen ? '4vp' : this.markButtonRowsGap })
    }
  }

  @Builder
  markButton(props: SimpleButtonProps) {
    Column() {
      SymbolGlyph(props.icon)
        .fontSize(24)
        .width(24)
        .height(24)
        .fontColor(['rgba(255, 255, 255, 0.6)'])
        .fontWeight(FontWeight.Regular)
        .draggable(false)

      Text(props.text)
        .margin({ top: this.newFoldSplitPortraitScreenType === SplitScreenType.SMALL ? '2vp' : '4vp' })
        .lineHeight(this.newFoldSplitPortraitScreenType === SplitScreenType.SMALL ? '12vp' :
          this.newFoldSplitPortraitScreenType > SplitScreenType.SMALL ? '16vp' : '19vp')
        .fontWeight(FontWeight.Regular)
        .fontFamily('HarmonyHeiTi')
        .fontSize(this.newFoldSplitPortraitScreenType === SplitScreenType.SMALL ? '9vp' :
          this.newFoldSplitPortraitScreenType > SplitScreenType.SMALL ? '12vp' : '14vp')
        .minFontSize('9vp')
        .maxFontSize(this.newFoldSplitPortraitScreenType === SplitScreenType.SMALL ? '9vp' :
          this.newFoldSplitPortraitScreenType > SplitScreenType.SMALL ? '12vp' : '14vp')
        .fontColor('rgba(255, 255, 255, 0.6)')
        .maxLines((this.isNewFoldPhoneExternalScreen ||
        SplitScreenManager.getInstance().isStrangeNumberMarkButtonOneLine(this.splitScreenType)) ? 1 : 2)
        .textAlign(TextAlign.Center)
    }
    .alignSelf(ItemAlign.Center)
    .justifyContent(FlexAlign.Center)
    .onClick(props.handleClick)
    .gesture(LongPressGesture().onActionEnd(props.handleClick))
    .accessibilityText(!this.screenReaderStatus ? '' : StringUtil.formatResourceToString(props.text))
    .accessibilityDescription($r('app.string.one_finger_double_click'))
    .accessibilityRole(AccessibilityRoleType.BUTTON)
  }

  @Builder
  customMarkButton() {
    this.markButton({
      icon: $r('sys.symbol.square_and_pencil_fill'),
      text: $r('app.string.custom'),
      handleClick: () => {
        LogUtils.i(TAG, 'open custom mark dialog');
        this.customMarkController.open();
      }
    })
  }

  @Builder
  predefinedMarkButton(props: PredefinedMark) {
    this.markButton({
      icon: props.icon,
      text: props.text,
      handleClick: async () => {
        LogUtils.i(TAG, `mark as ${props.markType}`);
        await this.service.setNumberMark({
          markType: props.markType,
          accountNumber: this.accountNumber,
          formatNumber: this.formatNumber,
        });
        this.service.completeSetNumberMarkSteps('set predefined mark finished');
        ReportUtil.getInstance().reportCallEndMarkNumber(props.text.id);
      }
    })
  }

  @Builder
  buildMarkDialog() {
    CustomMarkDialog({
      service: this.service,
      controller: this.customMarkController,
      accountNumber: this.accountNumber,
      formatNumber: this.formatNumber,
    })
  }

  // Returns the marks in order.
  private getPredefinedMarks(): PredefinedMark[] {
    return [
      {
        markType: MarkType.MARK_TYPE_PROMOTE_SALES,
        icon: $r('sys.symbol.ad_rectangle_fill'),
        text: $r('app.string.advertising_and_promotion')
      },
      {
        markType: MarkType.MARK_TYPE_HOUSE_AGENT,
        icon: $r('sys.symbol.house_fill'),
        text: $r('app.string.Real_Estate_Agency')
      },
      {
        markType: MarkType.MARK_TYPE_CRANK,
        icon: $r('sys.symbol.hand_raised_hexagon_fill'),
        text: $r('app.string.harassing_call')
      },
      {
        markType: MarkType.MARK_TYPE_FRAUD,
        icon: $r('sys.symbol.exclamationmark_shield_fill'),
        text: $r('app.string.fraud_phone_call')
      },
      {
        markType: MarkType.MARK_TYPE_EXPRESS,
        icon: $r('sys.symbol.truck_box_fill'),
        text: $r('app.string.courier_and_food_delivery')
      },
      {
        markType: MarkType.MARK_TYPE_INSURANCE,
        icon: $r('sys.symbol.briefcase_fill'),
        text: $r('app.string.financial_management_insurance')
      },
      {
        markType: MarkType.MARK_TYPE_TAXI,
        icon: $r('sys.symbol.car_fill'),
        text: $r('app.string.taxi')
      },
      {
        markType: MarkType.MARK_TYPE_CUSTOM,
        icon: $r('sys.symbol.square_and_pencil_fill'),
        text: $r('app.string.custom'),
      }
    ]
  }
}

@Component
struct CustomMarkDialog {
  private service: NumberMarkService = new NumberMarkService();
  @Prop accountNumber: string = '';
  @Prop formatNumber: string = '';
  @State customMark: string = '';
  controller: CustomDialogController = new CustomDialogController({ builder: null });
  @State inputFocus: boolean = false;

  build() {
    Column() {
      TextInput({
        text: $$this.customMark,
      })
        .maxLength(10)
        .defaultFocus(true)
        .backgroundColor(Color.Transparent)
        .borderRadius(0)
        .padding(0)
        .type(InputType.Normal)
        .height(48)
        .width('100%')
        .onFocus(() => {
          this.inputFocus = true;
        })
        .onBlur(() => {
          this.inputFocus = false;
        })
      Divider()
        .strokeWidth(this.inputFocus ? '2px' : '1px')
        .color(this.inputFocus ? $r('sys.color.ohos_id_color_primary') : $r('sys.color.ohos_id_color_list_separator'))
        .opacity(this.inputFocus ? 0.6 : 1)
      Flex({ justifyContent: FlexAlign.SpaceAround, alignItems: ItemAlign.Center }) {
        Button($r('app.string.cancel'))
          .backgroundColor(Color.Transparent)
          .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
          .onClick(() => this.onCancel())
        Divider()
          .vertical(true)
          .width(0.5)
          .height(24)
          .color($r('sys.color.comp_divider'))
          .opacity($r('sys.float.alpha_secondary'))

        Button($r('app.string.ok'))
          .backgroundColor(Color.Transparent)
          .fontColor($r('sys.color.font_emphasize'))
          .enabled(!!this.customMark)
          .onClick(() => this.onConfirm())
      }
      .margin({ top: 12 })
      .height(40)
    }
    .padding({
      top: 4,
      right: 24,
      bottom: 16,
      left: 24
    })
  }

  onCancel() {
    LogUtils.i(TAG, 'mark as custom cancel');
    this.controller.close();
  }

  async onConfirm() {
    if (!this.customMark) {
      return;
    }
    LogUtils.i(TAG, 'mark as custom confirm');
    await this.service.setNumberMark({
      markType: MarkType.MARK_TYPE_CUSTOM,
      customMark: this.customMark,
      accountNumber: this.accountNumber,
      formatNumber: this.formatNumber,
    });
    this.controller.close();
    this.service.completeSetNumberMarkSteps('set custom mark finished');
  }
}
