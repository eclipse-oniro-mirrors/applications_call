import commonEvent from '@ohos.commonEvent';
import LogUtils from './LogUtils'
let subscriber;
const TAG = "SubscriberManager"
const events = ['usual.event.SPN_INFO_CHANGED', 'usual.event.SIM_STATE_CHANGE'];

export class SubscriberManager {

  /**
   * Registered subscribers
   */
  public async registerSubscriber() {
    subscriber = await new Promise((resolve) => {
      commonEvent.createSubscriber({
        events,
        priority: 1000
      },
        (err, data) => {
          resolve(data);
        }
      );
    });

    commonEvent.subscribe(subscriber, (err, res) => {
      LogUtils.i(TAG, "commonEvent subscribe 1 : %s" + JSON.stringify(res));
      if (err.code === 0) {
        LogUtils.i(TAG, "commonEvent subscribe : %s" + JSON.stringify(res));
        if (!!res.parameters.CUR_PLMN) {
          AppStorage.SetOrCreate("operatorName", res.parameters);
        }
      } else {
        LogUtils.i(TAG, "commonEvent.subscribe err : %s" + JSON.stringify(err));
      }
    });
  }
  /**
   * unsubscribe
   */
  public unsubscribe() {
    commonEvent.unsubscribe(subscriber, (err) => {
      if (err.code !== 0) {
        LogUtils.i(TAG, "commonEvent.unsubscribe err: %s" + JSON.stringify(err))
      }
    });
  }
}

let mSubscriberManager = new SubscriberManager();

export default mSubscriberManager as SubscriberManager;