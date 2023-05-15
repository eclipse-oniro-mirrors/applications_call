import Want from '@ohos.application.Want';
import ServiceExtension from '@ohos.app.ability.ServiceExtensionAbility';
import CallManagerService from './CallManagerService';
import rpc from '@ohos.rpc';
import LogUtils from '../common/utils/LogUtils';
import DefaultCallData from '../common/struct/TypeUtils';

const TAG = "ServiceAbility";

export default class ServiceAbility extends ServiceExtension {
  callManagerService: CallManagerService

  onCreate(want) {
    LogUtils.i(TAG, "onCreate callUI service");
    this.callManagerService = CallManagerService.getInstance();
    this.callManagerService.init(this.context);
  }

  onConnect(want: Want) {
    LogUtils.i(TAG, "onConnect callUI service");
    let callData: DefaultCallData = new DefaultCallData();
    callData.accountNumber = want.parameters?.accountNumber;
    callData.videoState = want.parameters?.videoState;
    callData.callType = want.parameters?.callType;
    callData.callState = want.parameters?.callState;
    callData.callId = want.parameters?.callId;
    callData.startTime = want.parameters?.startTime;
    callData.accountId = want.parameters?.accountId;
    callData.isEcc = want.parameters?.isEcc;
    callData.conferenceState = want.parameters?.conferenceState;
    this.callManagerService.getCallData(callData);
    return new Stub('ServiceAbility');
  }

  onDisconnect(): void {
    LogUtils.i(TAG, 'onDisconnect callUI service');
    this.callManagerService.onDisconnected();
  }

  onRequest(want: Want, startId: number) {
    LogUtils.i(TAG, "onRequest callUI service");
  }

  onDestroy() {
    LogUtils.i(TAG, "onDestroy callUI service");
    this.callManagerService.removeRegisterListener();
  }
}

class Stub extends rpc.RemoteObject {
  constructor(descriptor) {
    super(descriptor);
  }

  onRemoteRequest(code, date, reply, option) {
    LogUtils.i(TAG, "Stub onRemoteRequest code:" + code)
    return true;
  }
}