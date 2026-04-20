/**
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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

/**
 * Enable accessibility.
 * For the button components on the call and video call pages, after the page is refreshed,
 * it is necessary to delay sending the accessibility focus event to prevent focus loss.
 * The current setting is 100, which is determined by the actual test results.
 */
export const DELAY_SEND_DURATION: number = 100;

/**
 * Enable accessibility.
 * For the button component on the video call page, after the page is refreshed,
 * it is necessary to delay sending the accessibility focus event to prevent focus loss.
 * Dedicated to the speaker button, currently set to 650, to be determined by actual test results.
 */
export const SPEAKER_DELAY_SEND_DURATION: number = 650;