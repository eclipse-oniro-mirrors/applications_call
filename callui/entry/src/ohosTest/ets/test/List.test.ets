/**
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

import BackupExtensionTest from './backup/BackupExtension.test';
import RecordTimerTest from './RecordTimer.test';
import IncomingComVMTest, { IncomingComVMTest2 } from './IncomingComVM.test';
import BottomViewModelTest from './BottomViewModel.test';
import TypeUtilsTest from './TypeUtils.test';
import VideoCameraHelperTest from './common/struct/VideoCameraHelper.test';
import PhoneNumberFormatManagerTest from './PhoneNumberFormatManager.test';
import { ReportUtilTest, ReportUtilTest2 } from './common/utils/ReportUtil.test';
import RecordingTest from './common/utils/Recording.test';
import AudioDeviceManagerTest from './AudioDeviceManager.test';
import MultiContactCardTest from './MultiContactCard.test';
import FuncBtnTest from './FuncBtn.test';
import VideoFuncBtnTest from './VideoFuncBtnGroup.test';
import CallManagerTest from './CallManager.test';
import DisplayUtilTest from './DisplayUtil.test';
import ContactManagerTest from './ContactManager.test';
import LogUtilsTest from './LogUtils.test';
import IncomingComTest from './IncomingCom.test';
import LeatherManagerTest from './LeatherManager.test';
import DeviceTypeUtilsTest from './common/utils/DeviceTypeUtils.test';
import CommonEventUtilsTest from './common/utils/CommonEventUtils.test';
import GroupIdUtilTest from './common/utils/GroupIdUtil.test';
import SymbolIconUtilTest from './common/utils/SymbolIconUtil.test';
import VibrationAndProximityUtilsTest from './VibrationAndProximityUtils.test';
import CallColumnUtilsTest from './CallColumnUtils.test';
import abilityTest from './Ability.test';
import IncomingAnimation from './IncomingAnimation.test';
import CallUtilsTest from './common/utils/CallUtils.test';
import RejectMsgDialogTest from './RejectMsgDialog.test';
import SimManagerTest from './SimManager.test';
import IncomingCallRejectionSms from './IncomingCallRejectionSms.test';
import ComFuncBtnTest from './components/FuncBtn.test';
import StringUtilTest from './common/utils/StringUtil.test';
import BannerNotificationTest from './BannerNotification.test';
import UtilsTest from './common/utils/utils.test';
import VideoCallManagerTest from './VideoCallManager.test';
import BannerTest from './common/utils/Banner.test';
import DeviceTypeUtilTest from './DeviceTypeUtil.test';
import { CallListHelperTest, CallListHelperTest2 } from './common/utils/CallListHelper.test';
import CloneTest from './Clone.test';
import CallLabelUtilsTest from '../test/common/utils/CallLabelUtils.test';
import CallManagerServExtTest from './ServiceAbility/CallManagerServiceExt.test';
import VideoCallApiTest from './VideoCallApi.test';
import GlobalContextHelperTest from './GlobalContextHelper.test';
import TelephonyApiTest from './ServiceAbility/TelephonyApi.test';
import DataStorageUtilTest from './common/utils/DataStorageUtil.test';
import UtilDisplayUtilTest from './common/utils/DisplayUtil.test';
import CallEventUtilTest from './common/utils/CallEventUtil.test';
import ExternalCallModelTest from './external/ExternalCallModel.test';
import ExternalCallAbilityTest from './external/ExternalCallAbility.test';
import ExternalCallUtilsTest from './external/ExternalCallUtilsTest.test';
import SatelliteCallManagerTest from './SatelliteCallManager.test';
import BannerResourceManagerTest from './BannerResourceManager.test';
import CallCardScreenTest from './common/utils/CallCardScreen.test';
import FontScaleStateTest from './common/utils/FontScaleState.test';
import CallFaultEventUtilTest from './CallFaultEventUtil.test';
import CallManagerServiceTest from './ServiceAbility/CallManagerService.test';
import ContactsDataTest from './common/utils/ContactsData.test';
import ServiceAbilityTest from './ServiceAbility/ServiceAbility.test';
import FileUtilsTest from './backup/presenter/FileUtils.test';
import CopyDbDataHelperTest from './backup/presenter/CopyDbDataHelper.test';
import CallSettingDbHelperTest from './backup/presenter/CallSettingDbHelper.test';
import WallpaperHelperTest from './common/utils/WallpaperHelper.test';
import DistributedUtilsTest from './common/utils/DistributedUtils.test';
import ScreenAdapterUtilsTest from './common/utils/ScreenAdapterUtils.test';
import BehaviorDottingTest from './BehaviorDotting.test'
import DtmfPresenterTest from './presenter/DtmfPresenter.test'
import TrifoldManagerTest from './common/utils/TrifoldManager.test';
import ListenScreenUnlockedTest from './common/utils/ListenScreenUnlocked.test';
import CallSettingPresenterTest from './backup/presenter/CallSettingPresenter.test';
import { PrivacyEnhancedCallManagerTest } from './PrivacyEnhancedCallManager.test';
import SplitScreenManagerTest from './SplitScreenManager.test';
import CallAssistantConnectTest from './CallAssitantConnect.test';
import EmptyWindowForDialogTest from './EmptyWindowForDialog.test';
import isNotePadEnableTest from './CheckRestoresUtils.test';
import VideoControllerTest from './VideoController.test';

export default function testsuite() {
  abilityTest();
  CallColumnUtilsTest();
  CallSettingDbHelperTest()
  VibrationAndProximityUtilsTest();
  IncomingAnimation();
  IncomingComTest();
  LeatherManagerTest();
  DeviceTypeUtilsTest();
  CommonEventUtilsTest();
  GroupIdUtilTest();
  SymbolIconUtilTest();
  LogUtilsTest();
  ContactManagerTest();
  CallUtilsTest();
  DisplayUtilTest();
  CallManagerTest();
  RejectMsgDialogTest();
  MultiContactCardTest();
  FuncBtnTest();
  AudioDeviceManagerTest();
  SimManagerTest();
  IncomingCallRejectionSms();
  VideoFuncBtnTest();
  BottomViewModelTest();
  IncomingComVMTest();
  IncomingComVMTest2();
  CallListHelperTest();
  CallListHelperTest2();
  RecordingTest();
  ReportUtilTest();
  ReportUtilTest2();
  PhoneNumberFormatManagerTest();
  ComFuncBtnTest();
  StringUtilTest();
  BannerNotificationTest();
  UtilsTest();
  DeviceTypeUtilTest();
  VideoCallManagerTest();
  BannerTest();
  TypeUtilsTest();
  RecordTimerTest();
  VideoCameraHelperTest();
  CloneTest();
  CallLabelUtilsTest();
  CallManagerServiceTest();
  CallManagerServExtTest();
  FileUtilsTest();
  CopyDbDataHelperTest();
  DtmfPresenterTest();
  WallpaperHelperTest();
  BehaviorDottingTest();
  BackupExtensionTest();
  VideoCallApiTest();
  GlobalContextHelperTest();
  TelephonyApiTest();
  DataStorageUtilTest();
  UtilDisplayUtilTest();
  CallEventUtilTest();
  ExternalCallModelTest();
  ExternalCallUtilsTest();
  ExternalCallAbilityTest();
  SatelliteCallManagerTest();
  BannerResourceManagerTest();
  CallCardScreenTest();
  FontScaleStateTest();
  CallFaultEventUtilTest();
  ContactsDataTest();
  ServiceAbilityTest();
  ScreenAdapterUtilsTest();
  DistributedUtilsTest();
  TrifoldManagerTest();
  ListenScreenUnlockedTest();
  CallSettingPresenterTest();
  PrivacyEnhancedCallManagerTest();
  SplitScreenManagerTest();
  CallAssistantConnectTest();
  EmptyWindowForDialogTest();
  isNotePadEnableTest();
  VideoControllerTest();
}
