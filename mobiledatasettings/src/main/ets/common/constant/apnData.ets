export const apnProtocoloption: string[] = ['IPv4', 'IPv6', 'IPv4/IPv6']

export const bearingSystemType: string[] = ["无", 'LTE', 'HSPAP', 'HSPA', 'HSUPA', 'HSDPA', 'UMTS', 'EDGE', 'GPRS', 'eHRPD', 'EVDO_B', 'EVDO_A', 'EVDO_O', '1xRTT', 'IS95B', 'IS95A']

export class ApnDetailDataConst {
  static readonly PROFILE_ID = "profile_id"
  static readonly PROFILE_NAME = "profile_name"
  static readonly APN = "apn"
  static readonly PROXY_IP_ADDRESS = "proxy_ip_address"
  static readonly APNPORT = "apnPort"
  static readonly AUTH_USER = "auth_user"
  static readonly AUTH_PWD = "auth_pwd"
  static readonly SERVER = "server"
  static readonly HOME_URL = "home_url"
  static readonly MMS_IP_ADDRESS = "mms_ip_address"
  static readonly MMSPORT = "mmsPort"
  static readonly MCC = "mcc"
  static readonly MNC = "mnc"
  static readonly MCCMNC = "mccmnc"
  static readonly AUTH_TYPE = "auth_type"
  static readonly APN_TYPES = "apn_types"
  static readonly APN_PROTOCOL = "apn_protocol"
  static readonly APN_ROAM_PROTOCOL = "apn_roam_protocol"
  static readonly IS_ROAMING_APN = "is_roaming_apn"
  static readonly BEARING_SYSTEM_TYPE = "bearing_system_type"
  static readonly MVNO_TYPE = "mvno_type"
  static readonly MVNO_MATCH_DATA = "mvno_match_data"
  static readonly EDITED = "edited"
}