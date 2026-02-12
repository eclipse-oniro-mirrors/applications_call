/**
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

export enum NotificationPosition {
  NOTIFICATION_BODY = 0,
  IGNORE_NOTIFY_BUTTON = 1,
  CLOSE_SATELLITE_NETWORK_BUTTON = 2,
}

export enum DetectCellularNetwork {
  NOT_EXIST = 0,
  EXIST = 1,
  INTERRUPTED = 2
}

export enum PageStartReason {
  DEFAULT = 'default',
  FROM_SEARCH = 'from_search',
  FROM_EXTERNAL = 'from_external',
  FROM_INTENT = 'from_intent',
  FROM_SUGGESTION = 'from_suggestion',
  FROM_STABILITY = 'from_stability',
}

