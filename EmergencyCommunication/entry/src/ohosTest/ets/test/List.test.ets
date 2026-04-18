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

import AudioPlayerServiceTest from './AudioPlayerService.test'
import SosLocationServiceTest from './SosLocationService.test'
import SosEncryptedTest from './SosEncrypted.test'
import SOSEmergencyCallAbilityTest from './SOSEmergencyCallAbility.test'
import ContactsServiceTest from './service/ContactsService.test'
import EccServiceExtAbilityTest from './serviceextability/EccServiceExtAbility.test'
import DynamicLoaderTest from './DynamicLoader.test'
import ScreenAdapterUtilsTest from './ScreenAdapterUtils.test'
import ReportPreferencesUtilsTest from './ReportPreferencesUtils.test'
import FontScaleStateTest from './utils/FontScaleState.test'
import TelephoneUtilTest from './utils/TelephoneUtil.test'
import AudioUtilTest from './utils/AudioUtil.test'
import SatelliteUtilTest from './utils/SatelliteUtil.test'
import SatelliteServiceApiTest from './utils/SatelliteServiceApi.test'
import OobeStatementAbilityPrivacyTest from './emergencycallability/OobeStatementAbilityPrivacy.test';
import OobeStatementAbilityDisclaimAbilityTest from './emergencycallability/OobeStatementAbilityDisclaimAbility.test';
import OobeStatementAbilityTest from './emergencycallability/OobeStatementAbility.test';
import EmergencyCallAbilityTest from './emergencycallability/EmergencyCallAbility.test';
import EmergencyInfoAbilityTest from './emergencycallability/EmergencyInfoAbility.test';
import LayoutUtilsTest from './utils/LayoutUtils.test';
import EmergencyWarningPreferencesUtilsTest from './utils/EmergencyWarningPreferencesUtils.test';
import IMediaPlayerTest from './IMediaPlayer.test';
import DetectorTest from './Detector.test';
import GeoTest from './Geo.test';
import MorandiColorTest from './data/MorandiColor.test';
import InitDataUtilTest from './utils/InitDataUtil.test';
import HiLogTest from './utils/HiLog.test';
import { EmergencyNumberTest, EmergencyNumberTest1 } from './utils/EmergencyNumber.test';
import EmergencyGlobalContextHelperTest from './utils/EmergencyGlobalContextHelper.test';
import CallColumnUtilsTest from './utils/CallColumnUtils.test';
import StateMonitorUtilTest from './utils/StateMonitorUtil.test';
import LocationDataTest from './data/LocationData.test';
import OnScreenOffTest from './control/OnScreenOff.test';
import EmergencyContactsDataSourceTest from './data/EmergencyContactsDataSource.test';
import CommonFunctionTest from './utils/CommonFunction.test';
import { DataStorageUtilTest, DataStorageUtilTest1 } from './utils/DataStorageUtil.test';
import DialerVoiceTest from './utils/DialerVoice.test';
import DialerSecretCodeTest from './utils/DialerSecretCode.test';
import EmergencyInfoUtilTest from './utils/EmergencyInfoUtil.test';
import ReportUtilTest from './utils/ReportUtil.test';
import SubscriberManagementTest from './utils/SubscriberManagement.test';
import AirplaneModeTest from './data/AirplaneMode.test';
import EmergencyCallControlTest from './control/EmergencyCallControl.test';
import BasicDataSourceTest from './data/BasicDataSource.test';
import RestoreUtilsTest from './backup/RestoreUtils.test';
import FileUtilsTest from './backup/FileUtils.test';
import ContactsRdbHelperTest from './backup/ContactsRdbHelper.test';
import PrefUtilsTest from './backup/PrefUtils.test';
import NetUtilsTest from './utils/NetUtils.test';
import HttpsUtilsTest from './utils/HttpsUtils.test';
import CryptoFrameworkUtilsTest from './utils/CryptoFrameworkUtils.test'
import EmergencyWarningControlTest from './control/EmergencyWarningControl.test';
import ClassStructTest from './utils/ClassStruct.test';
import DisplayUtilTest from './utils/DisplayUtil.test';
import SosEmergencyCallControllerTest from './control/SosEmergencyCallController.test'
import SosEmergencySmsControllerTest from './control/SosEmergencySmsController.test'
import SosSettingsControllerTest from './control/SosSettingsController.test'
import LocationUtilsTest from './utils/LocationUtils.test';
import SatelliteModelTest from './model/SatelliteModel.test';
import ContactsModelTest from './model/ContactsModel.test';
import StringUtilTest from './utils/StringUtil.test';
import SystemModeControllerTest from './control/SystemModeController.test';
import EmergencyContactsInfoControllerTest from './control/EmergencyContactsInfoController.test';

export default function testsuite() {
  SOSEmergencyCallAbilityTest();
  EmergencyCallControlTest();
  LocationDataTest();
  CallColumnUtilsTest();
  EmergencyContactsDataSourceTest();
  EmergencyGlobalContextHelperTest();
  HiLogTest();
  InitDataUtilTest();
  MorandiColorTest();
  CommonFunctionTest();
  EmergencyInfoUtilTest();
  SubscriberManagementTest();
  BasicDataSourceTest();
  AirplaneModeTest();
  StateMonitorUtilTest();
  DialerVoiceTest();
  ClassStructTest();
  EmergencyNumberTest();
  EmergencyNumberTest1();
  ReportUtilTest();
  DialerSecretCodeTest();
  DataStorageUtilTest1();
  DataStorageUtilTest();
  RestoreUtilsTest();
  PrefUtilsTest();
  FileUtilsTest();
  ContactsRdbHelperTest();
  GeoTest();
  DetectorTest();
  EmergencyWarningPreferencesUtilsTest();
  LayoutUtilsTest();
  CryptoFrameworkUtilsTest();
  HttpsUtilsTest();
  NetUtilsTest();
  OobeStatementAbilityTest();
  EmergencyCallAbilityTest();
  EmergencyInfoAbilityTest();
  OobeStatementAbilityDisclaimAbilityTest();
  OobeStatementAbilityPrivacyTest();
  EmergencyWarningControlTest();
  SosEmergencyCallControllerTest();
  SosEmergencySmsControllerTest();
  SosSettingsControllerTest();
  DisplayUtilTest();
  AudioUtilTest();
  TelephoneUtilTest();
  ContactsServiceTest();
  FontScaleStateTest();
  ReportPreferencesUtilsTest();
  DynamicLoaderTest();
  EccServiceExtAbilityTest();
  AudioPlayerServiceTest();
  ScreenAdapterUtilsTest();
  SosEncryptedTest();
  SosLocationServiceTest();
  OnScreenOffTest();
  IMediaPlayerTest();
  EmergencyContactsInfoControllerTest();
  SystemModeControllerTest();
  SosEmergencySmsControllerTest();
  SosEmergencyCallControllerTest();
  StringUtilTest();
  ContactsModelTest();
  SatelliteModelTest();
  SOSEmergencyCallAbilityTest()
  SatelliteServiceApiTest()
  SatelliteUtilTest()
  TelephoneUtilTest()
  LocationUtilsTest()
}