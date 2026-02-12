/**
 * Copyright (c) 2023 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an 'AS IS' BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import { StaticNumberDataListStruct } from '../struct/RecorderSettingStruct';

export default class CommonData {
  public static defaultStaticNumberDataUse: StaticNumberDataListStruct[] = [];
  public static recordingObjectChange: Record<string, Resource> = {
    '1': $r('app.string.all_calls'),
    '2': $r('app.string.specified_number')
  };
  public static contactPage: Record<string, string> = {
    'PAGE_FLAG_MULTI_CHOOSE': 'page_flag_multi_choose'
  };
}