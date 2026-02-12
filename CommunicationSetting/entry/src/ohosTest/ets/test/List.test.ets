/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
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
import SystemAndServiceUtilTest from './util/SystemAndServiceUtil.test'
import PageViewModelTest from './viewmodel/PageViewModel.test'
import AppInfoListDataSourceTest from './viewmodel/AppInfoListDataSource.test'
import AppInfoTest from './viewmodel/AppInfo.test'
import StringUtilTest from './util/StringUtil.test'
import DeviceUtilTest from './util/DeviceUtil.test'
import ArrayUtilTest from './util/ArrayUtil.test'
import SearchDataTest from './data/SearchData.test'
import CommonConstantsTest from './constants/CommonConstants.test'
import abilityTest from './Ability.test'
import BarBufferTest from './feature/mpchart/BarBuffer.test'
import AccessibilityTextHandlerTest from './feature/mpchart/utils/AccessibilityTextHandler.test'
import MatrixTest from './feature/mpchart/utils/Matrix.test'
import MPPointFTest from './feature/mpchart/utils/MPPointF.test'
import ObjectPollTest from './feature/mpchart/utils/ObjectPool.test'
import TransformerTest from './feature/mpchart/utils/Transformer.test'
import BarEntryTest from './feature/mpchart/data/BarEntry.test'
import BarDataSetTest from './feature/mpchart/data/BarDataSet.test'
import PaintTest from './feature/mpchart/data/Paint.test'
import CharDataTest from './feature/mpchart/data/ChartData.test'
import BarHighlighterTest from './feature/mpchart/highlight/BarHighlighter.test'
import ChartHighlighterTest from './feature/mpchart/highlight/ChartHighlighter.test'
import HighlightTest from './feature/mpchart/highlight/Highlight.test'
import DefaultAxisValueTest from './feature/mpchart/formatter/DefaultAxisValueFormatter.test'
import UtilsTest from './feature/mpchart/utils/Utils.test'
import BasicDataSourceTest from './viewmodel/BasicDataSource.test'
import FontScaleStateTest from './util/fontScaleState.test'
import AppInfoListPresenterTest from './presenter/AppInfoListPresenter.test'
import ChartColorModeTest from './util/ChartColorModeUtil.test'
import HDSUtilTest from './util/HDSUtil.test'
import CommunicationSettingAbilityTest from './entryability/CommunicationSettingAbility.test'
import MyAbilityStageTest from './application/MyAbilityStage.test'
import UIExtAbilityTest from './entryability/NetAccessPolicyUIExtAbility.test'
import TrafficPackagePresenterTest from './presenter/TrafficPackagePresenter.test'
import DisplayUtilsTest from './util/DisplayUtils.test'
import AppStorageUtilsTest from './util/AppStorageUtils.test'
import ScreenAdapterUtilTest from './util/ScreenAdapterUtils.test'
import TrafficPackageTest from './util/TrafficPackageUtil.test'
import SimManagerTest from './util/SimManager.test'
import WorkFactoryTest from './worker/work.test'
import SimServiceProxyTest from './model/simServiceProxy.test'
import DataShareHelperTest from './model/DataShareHelper.test'
import SimCradNameListenerTest from './util/SimCradNameListener.test'
import DotUtilTest from './util/DotUtil.test'
import ViewPortHandlerTest from './feature/mpchart/utils/ViewPortHandler.test'
import XAxisRendererTest from './feature/mpchart/renderer/XAxisRenderer.test'
import BarChartRendererTest from './feature/mpchart/renderer/BarChartRenderer.test'
import DataRendererTest from './feature/mpchart/renderer/DataRenderer.test'
import AxisRendererTest from './feature/mpchart/renderer/AxisRenderer.test'
import YAxisRendererTest from './feature/mpchart/renderer/YAxisRenderer.test'
import ViewUtilsTest from './util/Utils.test'
import ComponentBaseTest from './feature/mpchart/components/ComponentBase.test'
import YAxisTest from './feature/mpchart/components/YAxis.test'
import AxisBaseTest from './feature/mpchart/components/AxisBase.test'
import ChartTouchListenerTest from './feature/mpchart/listener/ChartTouchListener.test'
import ChartModelTest from './feature/mpchart/charts/ChartModel.test'
import BarChartModelTest from './feature/mpchart/charts/BarChartModel.test'

export default function testsuite() {
  abilityTest();
  CommonConstantsTest();
  SearchDataTest();
  AppInfoListPresenterTest();
  ArrayUtilTest();
  DeviceUtilTest();
  StringUtilTest();
  AppInfoTest();
  AppInfoListDataSourceTest();
  PageViewModelTest();
  SystemAndServiceUtilTest()
  BasicDataSourceTest();
  BarBufferTest();
  AccessibilityTextHandlerTest();
  MatrixTest();
  MPPointFTest();
  ObjectPollTest();
  TransformerTest();
  BarEntryTest();
  BarDataSetTest();
  PaintTest();
  CharDataTest();
  BarHighlighterTest();
  ChartHighlighterTest();
  HighlightTest();
  DefaultAxisValueTest();
  UtilsTest();
  FontScaleStateTest();
  ChartColorModeTest();
  HDSUtilTest();
  CommunicationSettingAbilityTest();
  UIExtAbilityTest();
  MyAbilityStageTest();
  TrafficPackagePresenterTest();
  DisplayUtilsTest();
  AppStorageUtilsTest();
  ScreenAdapterUtilTest();
  TrafficPackageTest();
  SimManagerTest();
  WorkFactoryTest();
  SimServiceProxyTest();
  DataShareHelperTest();
  SimCradNameListenerTest();
  DotUtilTest();
  ViewPortHandlerTest();
  ViewUtilsTest();
  XAxisRendererTest();
  BarChartRendererTest();
  DataRendererTest();
  AxisRendererTest();
  YAxisRendererTest();
  ComponentBaseTest();
  YAxisTest();
  AxisBaseTest();
  ChartTouchListenerTest();
  ChartModelTest();
  BarChartModelTest()
}