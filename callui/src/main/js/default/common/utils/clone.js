/*
 * Copyright (c) 2021 Huawei Device Co., Ltd.
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
 * @file: Deep copy
 */

const mapTag = '[object Map]';
const setTag = '[object Set]';
const arrayTag = '[object Array]';
const objectTag = '[object Object]';
const argsTag = '[object Arguments]';
const boolTag = '[object Boolean]';
const dateTag = '[object Date]';
const numberTag = '[object Number]';
const stringTag = '[object String]';
const symbolTag = '[object Symbol]';
const errorTag = '[object Error]';
const regexpTag = '[object RegExp]';
const funcTag = '[object Function]';

const deepTag = [mapTag, setTag, arrayTag, objectTag, argsTag];

/**
 * forEach
 * @param { array } array
 * @param { function } iteratee
 */
function forEach(array, iteratee) {
    let index = -1;
    const length = array.length;
    while (++index < length) {
        iteratee(array[index], index);
    }
    return array;
}

/**
 * is object
 * @param { any } target
 */
function isObject(target) {
    const type = typeof target;
    return target !== null && (type === 'object' || type === 'function');
}

/**
 * get type
 * @param { any } target
 */
function getType(target) {
    return Object.prototype.toString.call(target);
}

/**
 * get init
 * @param { any } target
 */
function getInit(target) {
    const Ctor = target.constructor;
    return new Ctor();
}

/**
 * clone symbol
 * @param { any } target
 */
function cloneSymbol(target) {
    return Object(Symbol.prototype.valueOf.call(target));
}

/**
 * clone reg
 * @param { any } target
 */
function cloneReg(target) {
    const reFlags = /\w*$/;
    const result = new target.constructor(target.source, reFlags.exec(target));
    result.lastIndex = target.lastIndex;
    return result;
}

/**
 * clone function
 * @param { function } func
 */
function cloneFunction(func) {
    const bodyReg = /(?<={)(.|\n)+(?=})/m;
    const paramReg = /(?<=\().+(?=\)\s+{)/;
    const funcString = func.toString();
    if (func.prototype) {
        const param = paramReg.exec(funcString);
        const body = bodyReg.exec(funcString);
        if (body) {
            if (param) {
                const paramArr = param[0].split(',');
                return new Function(...paramArr, body[0]);
            } else {
                return new Function(body[0]);
            }
        } else {
            return null;
        }
    } else {
        return eval(funcString);
    }
}

/**
 * clone other type
 * @param { any } target
 * @param { any } type - data type
 */
function cloneOtherType(target, type) {
    const Ctor = target.constructor;
    switch (type) {
        case boolTag:
        case numberTag:
        case stringTag:
        case errorTag:
        case dateTag:
            return new Ctor(target);
        case regexpTag:
            return cloneReg(target);
        case symbolTag:
            return cloneSymbol(target);
        case funcTag:
            return cloneFunction(target);
        default:
            return null;
    }
}

/**
 * clone
 * @param { any } target
 * @param { map } map
 */
function clone(target, map = new WeakMap()) {
    if (!isObject(target)) {
        return target;
    }

    const type = getType(target);
    let cloneTarget;
    if (deepTag.includes(type)) {
        cloneTarget = getInit(target, type);
    } else {
        return cloneOtherType(target, type);
    }

    if (map.get(target)) {
        return map.get(target);
    }
    map.set(target, cloneTarget);

    if (type === setTag) {
        target.forEach((value) => {
            cloneTarget.add(clone(value, map));
        });
        return cloneTarget;
    }

    if (type === mapTag) {
        target.forEach((value, key) => {
            cloneTarget.set(key, clone(value, map));
        });
        return cloneTarget;
    }

    const keys = type === arrayTag ? undefined : Object.keys(target);
    forEach(keys || target, (value, key) => {
        if (keys) {
            key = value;
        }
        cloneTarget[key] = clone(target[key], map);
    });

    return cloneTarget;
}

export default clone;