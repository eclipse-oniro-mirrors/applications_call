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
import { Poolable } from './Poolable';

export class ObjectPool<T extends Poolable> {
  private static ids = 0;
  public poolId: number = 0;
  private desiredCapacity: number = 0;
  public objects: Object[] | null = null;
  public objectsPointer: number = 0;
  private modelObject: T | null = null;
  private replenishPercentage: number = 0;

  public static create(withCapacity: number, object: Poolable) {
    let result = new ObjectPool<Poolable>(withCapacity, object);
    result.poolId = ObjectPool.ids;
    ObjectPool.ids++;
    return result;
  }

  constructor(withCapacity: number, object: T) {
    if (withCapacity <= 0) {
      throw new Error('Object Pool must be instantiated with a capacity greater than 0!');
    }
    this.desiredCapacity = withCapacity;
    this.objects = new Array<Object>(this.desiredCapacity);
    this.objectsPointer = 0;
    this.modelObject = object;
    this.replenishPercentage = 1.0;
    this.refillPool();
  }

  public setReplenishPercentage(percentage: number) {
    let p = percentage;
    if (p > 1) {
      p = 1;
    } else if (p < 0) {
      p = 0;
    }
    this.replenishPercentage = p;
    return this;
  }

  private refillPool(percentage?: number) {
    if (percentage == null) {
      percentage = this.replenishPercentage
    }
    let portionOfCapacity = (this.desiredCapacity * percentage);
    if (portionOfCapacity < 1) {
      portionOfCapacity = 1;
    } else if (portionOfCapacity > this.desiredCapacity) {
      portionOfCapacity = this.desiredCapacity;
    }
    for (let i = 0; i < portionOfCapacity; i++) {
      if (this.objects && this.modelObject) {
        let poolableObj = this.modelObject.instantiate();
        if (poolableObj !== null) {
          this.objects[i] = poolableObj;
        }
      }
    }
    this.objectsPointer = portionOfCapacity - 1;
  }

  public get(): T {
    if (this.objectsPointer == -1 && this.replenishPercentage > 0.0) {
      this.refillPool();
    }
    if (!this.objects) {
      this.objects = new Array<Poolable>(this.desiredCapacity);
    }
    let result: T = this.objects[this.objectsPointer] as T;
    result.currentOwnerId = Poolable.NO_OWNER;
    this.objectsPointer--;
    return result;
  }
  public recycle(object: T) {
    if (object.currentOwnerId != Poolable.NO_OWNER) {
      if (object.currentOwnerId == this.poolId) {
        throw new Error('The object passed is already stored in this pool!');
      } else {
        throw new Error(`The object to recycle already belongs to poolId ${object.currentOwnerId}` +
          `.  Object cannot belong to two different pool instances simultaneously!`);
      }
    }
    this.objectsPointer++;
    if (this.objects) {
      if (this.objectsPointer >= this.objects.length) {
        this.resizePool();
      }
      object.currentOwnerId = this.poolId;
      this.objects[this.objectsPointer] = object;
    }
  }

  private resizePool() {
    let oldCapacity = this.desiredCapacity;
    this.desiredCapacity *= 2;
    let temp: Object[] = new Array<Object>(this.desiredCapacity);
    if (this.objects) {
      for (let i = 0; i < oldCapacity; i++) {
        temp[i] = this.objects[i];
      }
    }
    this.objects = temp;
  }
}

