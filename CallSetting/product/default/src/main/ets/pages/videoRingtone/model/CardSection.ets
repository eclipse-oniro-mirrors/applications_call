/**
 * Copyright (c) 2025-2025 Huawei Device Co., Ltd.
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

import { Card } from './Card';

interface CardSectionContents {
  cards: Array<Card>;
  type?: string;
}

@Observed
export class CardSection {
  private dataModelArray: Card[] = [];
  public type: string;

  constructor(contents: CardSectionContents) {
    this.dataModelArray = contents.cards;
    this.type = contents.type ? contents.type : '';
  }

  public totalCount(): number {
    return this.dataModelArray.length;
  }

  public getDataArray(): Card[] {
    return this.dataModelArray;
  }

  public getData(index: number): Object {
    return this.dataModelArray[index];
  }

  public getDataModel(index: number): Card {
    return this.getData(index) as Card;
  }

  public addDataModel(index: number, dataModel: Card): void {
    this.dataModelArray.splice(index, 0, dataModel);
  }

  public pushDataModel(dataModel: Card): void {
    this.dataModelArray.push(dataModel);
  }
}
