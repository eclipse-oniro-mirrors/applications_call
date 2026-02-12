/**
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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
import { RecordConfigContactDataStruct } from '../struct/RecorderSettingStruct';
import BasicDataSource from './BasicDataSource';

export default class RecorderDesignateNumberSource extends BasicDataSource {
  private dataArray: RecordConfigContactDataStruct[] = [];

  public totalCount(): number {
    return this.dataArray.length;
  }

  public getData(index: number): RecordConfigContactDataStruct {
    return this.dataArray[index];
  }

  public getAllData(): RecordConfigContactDataStruct[] {
    return this.dataArray;
  }

  public addData(index: number, data: RecordConfigContactDataStruct): void {
    this.dataArray.splice(index, 0, data);
    this.notifyDataAdd(index);
  }

  public pushData(data: RecordConfigContactDataStruct): void {
    this.dataArray.push(data);
    this.notifyDataReload();
  }

  public concatData(data: RecordConfigContactDataStruct[]): void {
    this.dataArray = this.dataArray.concat(data);
    this.notifyDataReload();
  }

  public deleteDataByIndex(index: number) {
    this.dataArray.splice(index, 1);
    this.notifyDataDelete(index);
  }

  public deleteDataAll() {
    this.dataArray = [];
    this.notifyDataReload();
  }

  public updateDataCheckStatusAll(status: boolean) {
    this.dataArray.map((item) => {
      item.isChecked = status;
      // 新增时间戳字段,用于在lazyforeach中触发dom刷新
      item.timestamp = new Date().getTime();
    });
    this.notifyDataReload();
  }
}