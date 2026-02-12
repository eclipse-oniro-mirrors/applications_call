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

// raw_contact表
interface rawContact {
  contactId: string
  isDeleted: string
}

// contact_data表
interface contactData {
  rawContactId: string
  formatNumber: string
  alphaName: string
  detailInfo: string
  typeId: string
}

//view_contact_data view of the contacts database
interface ViewContactData {
  contactId: string //contact_id
  isDeleted: string //is_deleted
  typeId: string //type_id
  detailInfo: string //detail_info
}

interface tableData {
  contactDataColumn: contactData
  rawContactColumn: rawContact
  viewContactData: ViewContactData
}

export default {
  rawContactColumn: {
    contactId: 'contact_id', // contact_id
    isDeleted: 'is_deleted', // is_deleted
  },
  contactDataColumn: {
    rawContactId: 'raw_contact_id', // raw_contact_id
    formatNumber: 'format_phone_number', // format_phone_number
    alphaName: 'alpha_name', // alpha_name
    detailInfo: 'detail_info', //detail_info
    typeId: 'type_id', //type_id
  },
  viewContactData: {
    contactId: 'contact_id', //contact_id
    isDeleted: 'is_deleted', //is_deleted
    typeId: 'type_id', //type_id
    detailInfo: 'detail_info', //detail_info
  }
} as tableData