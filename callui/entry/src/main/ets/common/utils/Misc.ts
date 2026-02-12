/**
 * Copyright (c) 2022-2024 Huawei Device Co., Ltd.
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
import Clone from './Clone';
import LogUtils from './LogUtils';
import Method from './Method';

export type PromiseOr<T> = Promise<T> | T;

export const noop = (): void => {};

/**
 * A patch object is a subset of properties of the complete object type `<T>`.
 * The `<K>` is the identity property name (usually some ID) of `<T>`.
 */
export type Patch<T extends object, K extends keyof T> = {
  [P in Exclude<keyof T, K>]?: T[P];
} & {
  [P in K]: T[P];
};

export function isObject(value: unknown): value is object {
  return value != null && typeof value === 'object';
}

/**
 * Simple algorithm to compare two JavaScript object. Using depth first search to iterate through objects.
 * Parameter `result` will be changed in place and is always the return value.
 */
export function objDiff<T, P>(defaultValue: T, oldObj: T, newObj: P, path: string[], result: string[]): string[] {
  if (!isObject(oldObj)) {
    if (!Object.is(oldObj, newObj)) {
      let message = path.join('.');
      let info: string[] = [];
      if (typeof oldObj !== typeof newObj) {
        info.push(`type changed ${typeof oldObj} => ${typeof newObj}`);
      }
      if (Object.is(defaultValue, newObj)) {
        info.push('changed to default value');
      }
      result.push(message + (info.length ? `(${info.join(', ')})` : ''));
    }
    return result;
  }
  if (newObj == null) {
    result.push(path.join('.') + '(changed to null)');
    return result;
  }
  const newKeys = Object.keys(newObj);
  for (const key of newKeys) {
    const oldValue = oldObj[key];
    const newValue = newObj[key];
    path.push(key);
    objDiff(defaultValue?.[key], oldValue, newValue, path, result);
    path.pop();
  }
  return result;
}

export class Patcher<T extends object, P extends Patch<T, never>> {
  public readonly defaultValue: Readonly<T>;
  private readonly TAG: string;

  constructor(defaultValue: T, tag: string) {
    this.defaultValue = Object.freeze(defaultValue);
    this.TAG = `${tag} Patcher`;
  }

  getWithPriority<R>(select: (obj: T) => R, ...values: P[]): R {
    for (const value of values) {
      try {
        // @ts-expect-error not type safe
        const prop = select(value);
        if (prop != null) {
          return prop;
        }
      } catch {
        continue;
      }
    }
    return select(this.defaultValue);
  }

  /**
   * Constraint `U extends P` is just used to skip ArkTSCheck rule `arkts-no-untyped-obj-literals`
   */
  createPatch<U extends P>(patch: U): U {
    return patch;
  }

  /**
   * Does not update the old object, but returns a new object containing properties of both.
   * A clone of default value will be created and properties will be assigned to it.
   */
  merge(old: T, patch: P, debugPosition: string): T {
    // Log can be removed after deferred call data update problem solved.
    LogUtils.i(this.TAG, `merging at ${debugPosition}: ${objDiff(this.defaultValue, old, patch, [], []).join(' ')}`);
    return Method.assign(Clone.getInstance().clone(this.defaultValue), old, patch);
  }

  /**
   * Update old object in place and returns it.
   */
  apply(old: T, patch: P, debugPosition: string): T {
    // Log can be removed after deferred call data update problem solved.
    LogUtils.i(this.TAG, `applying at ${debugPosition}: ${objDiff(this.defaultValue, old, patch, [], []).join(' ')}`);
    return Method.assign(old, patch);
  }
}
