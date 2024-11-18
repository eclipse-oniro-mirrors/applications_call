import preferences from '@ohos.data.preferences'

export class PreferenceUtil {
  static getStore() {
    const context = AppStorage.get<Context>('abilityContext')
    return preferences.getPreferencesSync(context, {
      name: 'preference_apn'
    })
  }

  static put(key: string, value: preferences.ValueType) {
    const store = PreferenceUtil.getStore()
    store.putSync(key, value)
    store.flush()
  }

  static get(key: string, defaultValue: preferences.ValueType) {
    const store = PreferenceUtil.getStore()
    return store.getSync(key, defaultValue)
  }

  static delete(key: string) {
    const store = PreferenceUtil.getStore()
    store.deleteSync(key)
    store.flush()
  }
}
