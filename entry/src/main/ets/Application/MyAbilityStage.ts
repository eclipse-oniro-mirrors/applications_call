import AbilityStage from "@ohos.application.AbilityStage"
import deviceInfo from '@ohos.deviceInfo';
import backgroundTaskManager from '@ohos.backgroundTaskManager';
import LogUtils from '../common/utils/LogUtils'
import notification from '@ohos.notification';

const TAG = "MyAbilityStage";

export default class MyAbilityStage extends AbilityStage {
  onCreate() {
    globalThis.deviceTypeInfo = deviceInfo.deviceType;
    this.applyEfficiencyResources();
    notification.enableNotification({
      bundle: "com.ohos.callui"
    }, true, (err, data) => {
      if (err) {
        LogUtils.e(TAG, "enableNotification err: " + JSON.stringify(err));
      }
    })
    LogUtils.i(TAG, "MyAbilityStage onCreate")
  }

  onDestroy() {
    LogUtils.i(TAG, "MyAbilityStage onDestroy")
    backgroundTaskManager.resetAllEfficiencyResources();
  }

  private applyEfficiencyResources() {
    let request: backgroundTaskManager.EfficiencyResourcesRequest = {
      resourceTypes: backgroundTaskManager.ResourceType.COMMON_EVENT,
      isApply: true,
      timeOut: 0,
      reason: "apply",
      isPersist: true,
      isProcess: false,
    }
    let res = backgroundTaskManager.applyEfficiencyResources(request);
    LogUtils.i(TAG, "result of applyEfficiencyResources is:" + res)
  }
}

