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
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium'
import { AudioPlayerService } from '../../../main/ets/service/AudioPlayerService'
import media from '@ohos.multimedia.media';


let audio = AudioPlayerService.getInstance();

export default function AudioPlayerServiceTest() {
  describe('AudioPlayerServiceTest', () => {
    it('AudioPlayerServiceTest', 0, async () => {
      audio.destroyAvPlayerOfSos(() => {
      });
      (audio as object)['avPlayerOfSos'] = await media.createAVPlayer();
      audio.destroyAvPlayerOfSos(() => {
      });
      AudioPlayerService.getInstance();
    })
  })
}