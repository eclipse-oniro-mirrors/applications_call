import ContactCard from '../common/components/ContactCard';
import FuncBtnGroup from '../common/components/FuncBtnGroup';
import BottomBtn from '../common/components/BottomBtn';
import Keyboard from '../common/components/Keyboard';
import IncomingCom from '../common/components/IncomingCom';
import CallStateConst from '../common/constant/CallStateConst';
import LogUtils from '../common/utils/LogUtils';
import byTrace from "@ohos.bytrace"
import NotificationManager from '../model/NotificationManager';
import CallManager from '../model/CallManager';

const TAG = "MainAbility";

/**
 * @file: Main interface
 */
@Entry
@Component
struct Index {
  @State message: string = 'Hello World'
  @StorageLink("InputNum") inputNum: any = [];
  @State callData: any = CallStateConst.defaultCallData;
  @State isShowKeyboard: boolean = false;
  @State callList: Array<any> = [];
  private notificationManager: NotificationManager;

  aboutToAppear(): void {
    LogUtils.i(TAG, "aboutToAppear :")
    byTrace.startTrace('aboutToAppear', 0);
    this.notificationManager = new NotificationManager();
    globalThis.callManager = new CallManager(this)
    AppStorage.SetOrCreate<NotificationManager>('notificationManager', this.notificationManager);
    byTrace.finishTrace('aboutToAppear', 0);
  }

  onPageShow() {
    LogUtils.i(TAG, "onPageShow : ")
    byTrace.startTrace('onPageShow', 1);
    globalThis.appInactiveState = false;
    this.notificationManager.cancelNotification();
    this.notificationManager.sendCapsuleNotification(this.callData, false);
    byTrace.finishTrace('onPageShow', 1);
    LogUtils.i(TAG, "onPageShow end : ")
  }

  onPageHide() {
    LogUtils.i(TAG, "onPageHide :")
    globalThis.appInactiveState = true;
    const {callState, accountNumber, contactName, callId} = this.callData;
    let fool = (callState !== CallStateConst.callStateObj.CALL_STATUS_DISCONNECTED && callId)
    if (callState !== CallStateConst.callStateObj.CALL_STATUS_DISCONNECTED && callId) {
      let text = '';
      if (contactName) {
        text = contactName + '  ' + accountNumber + '  ';
      } else {
        text = accountNumber + '  ';
      }
      this.notificationManager.sendNotification(text, this.callData);
      this.notificationManager.sendCapsuleNotification(this.callData, true);
      LogUtils.i(TAG, "onPageHide end : ")
    }
  }

  /**
   * method to control the display of DTMF keyboard
   *
   * parent component pass by value child component
   */
  public showKeyboard() {
    this.isShowKeyboard = !this.isShowKeyboard;
  }

  /**
   * Call status
   *
   * @return {number} -  callState
   */
  private callState() {
    LogUtils.i(TAG, "callState : " + this.callData.callState)
    return this.callData.callState;
  }

  build() {
    Column() {
      Stack() {
        Flex({
          direction: FlexDirection.Column,
          alignItems: ItemAlign.Center,
          justifyContent: FlexAlign.SpaceBetween
        }) {
          Column() {
            ContactCard({
              callData: $callData,
              isShowKeyboard: this.isShowKeyboard,
              callList: $callList
            })
          }
          .margin({ top: 56 })

          if (this.callState() !== CallStateConst.callStateObj.CALL_STATUS_WAITING
          && this.callState() !== CallStateConst.callStateObj.CALL_STATUS_INCOMING) {
            Column() {
              Column() {
                Column() {
                  FuncBtnGroup({ callData: $callData, callList: $callList })
                }
                .margin({ bottom: 29.5 })
              }
              .visibility(!this.isShowKeyboard ? Visibility.Visible : Visibility.None)

              Column() {
                Column() {
                  Keyboard({ callData: $callData })
                }
                .margin({ bottom: 32 })
              }
              .visibility(this.isShowKeyboard ? Visibility.Visible : Visibility.None)

              Column() {
                BottomBtn({
                  callData: $callData,
                  onItemClick: () => {
                    this.showKeyboard()
                  }
                })
              }
            }
            .margin({ bottom: 106 })
          } else {
            Column() {
              IncomingCom({
                callData: $callData,
              })
            }
            .margin({ bottom: 106 })
          }
        }
      }
    }
    .width("100%")
    .height("100%")
    .backgroundImage('assets/picture/wallpaper.png', ImageRepeat.NoRepeat)
    .backgroundImageSize(ImageSize.Cover)
  }
}
