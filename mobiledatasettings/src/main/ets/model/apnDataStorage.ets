import dataShare from '@ohos.data.dataShare'
import common from '@ohos.app.ability.common'
import { ApnInfo } from '../common/constant/apnInfo'
import { ValuesBucket } from '@ohos.data.ValuesBucket'
import { BusinessError } from '@ohos.base'
import dataSharePredicates from '@ohos.data.dataSharePredicates'
import DataShareResultSet from '@ohos.data.DataShareResultSet'
import { ApnItemInfo } from '../common/constant/apnItemInfo'
import { ApnDetailDataConst } from '../common/constant/apnData'


export class ApnDataStorage {
  private xmlUri: string = "datashare:///com.ohos.pdprofileability/net/pdp_profile/preferapn"
  private dbUri: string = "datashare:///com.ohos.pdpprofileability/net/pdp_profile"
  private dataShareHelper: dataShare.DataShareHelper | undefined = undefined;
  private xmlShareHelper: dataShare.DataShareHelper | undefined = undefined;
  private content:Context=null

  public async initData(context: Context) {
    this.content = context
    if (this.dataShareHelper == null || this.dataShareHelper == undefined) {
      this.dataShareHelper = await this.createDBHelper(context)
    }
    if (this.xmlShareHelper == null || this.xmlShareHelper == undefined) {
      this.xmlShareHelper = await this.createXmlHelper(context)
    }
  }

  async createXmlHelper(context: Context): Promise<dataShare.DataShareHelper> {
    return await dataShare.createDataShareHelper(context, this.xmlUri)
  }

  async createDBHelper(context: Context): Promise<dataShare.DataShareHelper> {
    return await dataShare.createDataShareHelper(context, this.dbUri)
  }


  public async updateXmlPeofileID(simID: number, profileID: number): Promise<boolean> {
    let success: boolean = false
    let xmlData = new dataSharePredicates.DataSharePredicates();
    let data: ValuesBucket = {
      'sim_id': simID,
      'profile_id': profileID,
    }
    this.xmlShareHelper.update(this.xmlUri, xmlData, data).then(insertData => {
      success = true
    }).catch((err: BusinessError) => {
      success = false
    })
    return success
  }

  ResourceToString(resource: Resource): string {
    return this.content.resourceManager.getStringSync(resource)
  }

  public async dataDelete(profileID: number): Promise<boolean> {
    let success: boolean = false
    let da = new dataSharePredicates.DataSharePredicates();
    da.equalTo('profile_id', Number(profileID));
    await this.dataShareHelper.delete(this.dbUri, da).then(data => {
      success = true
    }).catch((err: BusinessError) => {
      success = false
    })
    return success
  }


  public async dataInsert(apnInfo: ApnInfo): Promise<boolean> {
    let success: boolean = false
    let data = this.getValuesBucket(apnInfo)
    await this.dataShareHelper.insert(this.dbUri, data).then(insertData => {
      success = true
    }).catch((err: BusinessError) => {
      success = false
    })
    return success
  }


  public async dataUpdate(apnInfo: ApnInfo): Promise<boolean> {
    let success: boolean = false
    let data = this.getValuesBucket(apnInfo)
    let conditionData = new dataSharePredicates.DataSharePredicates();
    conditionData.equalTo('profile_id', Number(apnInfo.profile_id));
    await this.dataShareHelper.update(this.dbUri, conditionData, data).then(insertData => {
      success = true
    }).catch((err: BusinessError) => {
      success = false
    })
    return success
  }


  getValuesBucket(apnInfo: ApnInfo): ValuesBucket {
    let data: ValuesBucket = {
      'profile_name': apnInfo.profile_name,
      'apn': apnInfo.apn,
      'proxy_ip_address': apnInfo.proxy_ip_address,
      'auth_user': apnInfo.auth_user,
      'auth_pwd': apnInfo.auth_pwd,
      'home_url': apnInfo.home_url,
      'mms_ip_address': apnInfo.mms_ip_address,
      'mcc': apnInfo.mcc,
      'mnc': apnInfo.mnc,
      'mccmnc': apnInfo.mcc + apnInfo.mnc,
      'auth_type': Number(apnInfo.auth_type),
      'apn_types': apnInfo.apn_types,
      'apn_protocol': apnInfo.apn_protocol,
      'apn_roam_protocol': apnInfo.apn_roam_protocol,
      'is_roaming_apn': 1,
      'bearing_system_type': Number(apnInfo.bearing_system_type),
      'edited': 1,
      'server': apnInfo.server,
      'mvno_type': apnInfo.mvno_type,
      'mvno_match_data': apnInfo.mvno_match_data
    }
    return data
  }


  public listToApnInfo(list: Array<ApnItemInfo>, edited: number, profileID: number): ApnInfo {
    let apnInfo = new ApnInfo()
    if (edited === 1) {
      apnInfo.profile_id = profileID
    }
    for (let i = 0; i < list.length; i++) {
      let apnItemInfo = list[i]
      if (apnItemInfo.value.toString() === this.ResourceToString($r('app.string.apn_not_configured'))
        || apnItemInfo.value.toString() == this.ResourceToString($r('app.string.apn_null'))) {
        apnItemInfo.value = ''
      }
      switch (apnItemInfo.id) {
        case ApnDetailDataConst.PROFILE_NAME:
          apnInfo.profile_name = apnItemInfo.value.toString()
          break
        case ApnDetailDataConst.APN:
          apnInfo.apn = apnItemInfo.value.toString()
          break
        case ApnDetailDataConst.PROXY_IP_ADDRESS:
          if (apnItemInfo.value.toString() == '') {
            apnInfo.proxy_ip_address = ''
          } else {
            apnInfo.proxy_ip_address = apnItemInfo.value.toString()
          }
          break
        case ApnDetailDataConst.APNPORT:
          if (apnItemInfo.value.toString() == '') {
            apnInfo.proxy_ip_address = apnInfo.proxy_ip_address
          } else {
            apnInfo.proxy_ip_address = apnInfo.proxy_ip_address + ":" + apnItemInfo.value.toString()
          }
          break
        case ApnDetailDataConst.AUTH_USER:
          apnInfo.auth_user = apnItemInfo.value.toString()
          break
        case ApnDetailDataConst.AUTH_PWD:
          apnInfo.auth_pwd = apnItemInfo.value.toString()
          break
        case ApnDetailDataConst.SERVER:
          apnInfo.server = apnItemInfo.value.toString()
          break
        case ApnDetailDataConst.HOME_URL:
          apnInfo.home_url = apnItemInfo.value.toString()
          break
        case ApnDetailDataConst.MMS_IP_ADDRESS:
          if (apnItemInfo.value.toString() == '') {
            apnInfo.mms_ip_address = ''
          } else {
            apnInfo.mms_ip_address = apnItemInfo.value.toString()
          }
          break
        case ApnDetailDataConst.MMSPORT:
          if (apnItemInfo.value.toString() == '') {
            apnInfo.mms_ip_address = apnInfo.mms_ip_address
          } else {
            apnInfo.mms_ip_address = apnInfo.mms_ip_address + ":" + apnItemInfo.value.toString()
          }
          break

        case ApnDetailDataConst.MCC:
          apnInfo.mcc = apnItemInfo.value.toString()
          break
        case ApnDetailDataConst.MNC:
          apnInfo.mnc = apnItemInfo.value.toString()
          break
        case ApnDetailDataConst.AUTH_TYPE:
          apnInfo.apn_types = apnItemInfo.value.toString()
          break
        case ApnDetailDataConst.APN_PROTOCOL :
          apnInfo.apn_protocol = apnItemInfo.value.toString()
          break
        case ApnDetailDataConst.APN_ROAM_PROTOCOL:
          apnInfo.apn_roam_protocol = apnItemInfo.value.toString()
          break
        case ApnDetailDataConst.BEARING_SYSTEM_TYPE:
          apnInfo.bearing_system_type = Number(apnItemInfo.value)
          break
        case ApnDetailDataConst.MVNO_TYPE:
          apnInfo.mvno_type = apnItemInfo.value.toString()
          break
        case ApnDetailDataConst.MVNO_MATCH_DATA:
          apnInfo.mvno_match_data = apnItemInfo.value.toString()
          break

      }
    }
    return apnInfo
  }


  public async queryApnList(mccmnc: string): Promise<DataShareResultSet> {
    let resultSet: DataShareResultSet = null
    let columns = ["*"];
    let da = new dataSharePredicates.DataSharePredicates();
    da.equalTo('mccmnc', mccmnc)
      .and()
      .beginWrap()
      .beginWrap()
      .beginWrap()
      .like('apn_types', '%default%')
      .endWrap()
    try {
      if (this.dataShareHelper != undefined) {
        await (this.dataShareHelper as dataShare.DataShareHelper).query(this.dbUri, da, columns)
          .then((dataShareResultSet: DataShareResultSet) => {
            resultSet = dataShareResultSet
          })
          .catch((err: BusinessError) => {
            resultSet = null
          });
      }
    } catch (err) {
      let code = (err as BusinessError).code;
      let message = (err as BusinessError).message;
      resultSet = null
    }
    return resultSet
  }
}