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
@Observed
export class SimCardOneInfoStruct {
  public slotId: number = -1;
  public isEsim: boolean = false;
  public isActive: boolean = false;
  public showNumber: string = '';
  public showName: string = '';

  constructor() {
  }

  public setData(slotId: number, isEsim: boolean, isActive: boolean, showNumber: string, showName: string) {
    this.slotId = slotId;
    this.isEsim = isEsim;
    this.isActive = isActive;
    this.showNumber = showNumber;
    this.showName = showName;
  }
}

@Observed
export class SimCardTwoInfoStruct {
  public slotId: number = -1;
  public isEsim: boolean = false;
  public isActive: boolean = false;
  public showNumber: string = '';
  public showName: string = '';

  constructor() {
  }
}

@Observed
export class SimCardInfoStruct {
  public slotId: number = -1;
  public isEsim: boolean = false;
  public isActive: boolean = false;
  public showNumber: string = '';
  public showName: string = '';

  public setData(slotId: number, isEsim: boolean, isActive: boolean, showNumber: string, showName: string) {
    this.slotId = slotId;
    this.isEsim = isEsim;
    this.isActive = isActive;
    this.showNumber = showNumber;
    this.showName = showName;
  }
}

export class SatelliteSimCardInfoStruct {
  public slotId: number = -1;
  public showNumber: string = '';
  public isChecked: boolean = false;
  public isHyacinthChecked: boolean = false;
  public isPreferences: boolean = false;
  public iMsi: string = '';
  public isEsim?: boolean = false;
  public simLabelIndex?: number = 1;
}