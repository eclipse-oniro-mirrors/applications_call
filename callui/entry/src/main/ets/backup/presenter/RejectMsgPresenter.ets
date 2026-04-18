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

import common from '@ohos.app.ability.common';
import RejectMsgModel from '../model/RejectMsgModel';

export default class RejectMsgPresenter {
  private static instance: RejectMsgPresenter;
  private static rejectMsgModel: RejectMsgModel;

  public static getInstance(): RejectMsgPresenter {
    if (!RejectMsgPresenter.instance) {
      RejectMsgPresenter.instance = new RejectMsgPresenter();
    }
    return RejectMsgPresenter.instance;
  }

  init() {
    RejectMsgPresenter.rejectMsgModel = new RejectMsgModel();
  }

  async migratePrefFile(context: common.ExtensionContext) {
    await RejectMsgPresenter.rejectMsgModel.migratePrefFile(context);
  }
}