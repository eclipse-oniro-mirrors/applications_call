/*
 * Copyright (c) 2025 Huawei Device Co., Ltd.
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
import { SearchMode } from '../constants/CommonConstants';

export interface ChartSizeInterface {
  top: number,
  left: number,
  bottom: number,
  right: number,
  firstNodeWidth: number,
  lastNodeWidth: number,
  nodeWidth: number
}

export class VirtualNodeParam {
  public edgeSize: ChartSizeInterface = {
    top: 0,
    left: 0,
    bottom: 0,
    right: 0,
    firstNodeWidth: 0,
    lastNodeWidth: 0,
    nodeWidth: 0
  };
  public chartStr: string[] = [];
  public nodeId: string = '';
  public searchMode : number = SearchMode.NOT_SEARCHING;
}

@Builder
export function chartVirtualNodeBuild(param: VirtualNodeParam) {
  Stack() {
    Row() {
    }
    .id(param.nodeId)
    .width('100%')
    .height('100%')

    Row() {
      ForEach(param.chartStr, (item: string, index: number) => {
        Column()
          .height('100%')
          .width(getVirtualNodeWidth(index, param))
          .accessibilityText(item)
          .accessibilityLevel(getAccessibilityLevel(index, param))
      })
    }
    .width(`calc(100% - ${param.edgeSize.left}vp - ${param.edgeSize.right}vp)`)
    .height(`calc(100% - ${param.edgeSize.top}vp - ${param.edgeSize.top}vp)`)
    .margin({
      left: param.edgeSize.left,
      top: param.edgeSize.top,
      bottom: param.edgeSize.bottom
    })
  }
  .alignContent(Alignment.Start)
  .width('100%')
  .height('100%')
}

function getVirtualNodeWidth(index: number, param: VirtualNodeParam): number {
  if (index === 0) {
    return param.edgeSize.firstNodeWidth
  }
  if (index === param.chartStr.length - 1) {
    return param.edgeSize.lastNodeWidth;
  }
  return param.edgeSize.nodeWidth;
}

function getAccessibilityLevel(index: number, param: VirtualNodeParam): string {
  if (param.searchMode !== SearchMode.NOT_SEARCHING) {
    return 'no';
  }
  if (index === 0) {
    return param.edgeSize.firstNodeWidth > param.edgeSize.nodeWidth * 0.1 ? 'yes' : 'no';
  }
  if (index === param.chartStr.length - 1) {
    return param.edgeSize.lastNodeWidth > param.edgeSize.nodeWidth * 0.1 ? 'yes' : 'no';
  }
  return 'yes';
}