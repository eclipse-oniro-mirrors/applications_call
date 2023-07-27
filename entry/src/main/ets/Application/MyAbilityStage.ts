import AbilityStage from '@ohos.app.ability.AbilityStage';
import LogUtils from '../common/utils/LogUtils';
import notification from '@ohos.notification';

const TAG = 'MyAbilityStage';

export default class MyAbilityStage extends AbilityStage {
  onCreate(): void {
    notification.enableNotification({
      bundle: 'com.ohos.callui'
    }, true, (err, data) => {
      if (err) {
        LogUtils.e(TAG, 'enableNotification err: ' + JSON.stringify(err));
      }
    })
    LogUtils.i(TAG, 'MyAbilityStage onCreate');
  }

  onDestroy(): void {
    LogUtils.i(TAG, 'MyAbilityStage onDestroy');
  }
}

