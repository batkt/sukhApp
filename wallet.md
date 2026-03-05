## Wallet + QPay Integration (AmarSukh Backend)

### 1. Overview

This document describes how the AmarSukh backend integrates with the Wallet-Service (bpay) and QPay:

- Fetch billing and bills from Wallet
- Create Wallet invoices
- Create Wallet payments (via `/qpayGargaya` Wallet-QPay mode)
- How the frontend should call these endpoints

All endpoints below are **your backend** (behind `/api/...`). The backend, in turn, talks to `{{Wallet-Service}}` (for example `https://api.bpay.mn/v1`).

---

### 2. Auth / User Identity

All Wallet-related endpoints require:

- `Authorization: Bearer <token>` (orshinSuugch JWT)

The backend extracts:

- `orshinSuugch._id` from token
- `phoneNumber` = `orshinSuugch.utas`
- `walletUserId`, `walletBairId`, etc. if present

**Important:** For billing endpoints, **Wallet-Service uses phone number as `userId` header**, not `walletUserId`.

---

### 3. Billing Endpoints

#### 3.1 Get Wallet Billing List

**Backend endpoint**

```http
GET /api/wallet/billing/list
Authorization: Bearer <token>
```

**Backend → Wallet**

```http
GET {{Wallet-Service}}/api/billing/list
Headers:
  userId: <phoneNumber>
  Authorization: Bearer <walletToken>
```

**Response (backend → frontend)**

```json
{
  "success": true,
  "data": [
    {
      "billingId": "8b1320f6-d2e8-4e1b-ae71-5c64a794dd59",
      "billingName": "Орон сууцны төлбөр",
      "customerId": "cfeb1c02-e061-4b1e-ae82-6dff8ee28f6d",
      "customerName": "Н****Х",
      "customerAddress": "БЗД 13-р хороо 118-р байр, 22 ",
      "paidInvoicesCount": 0,
      "paidInvoicesTotal": 0,
      "hasNewBills": false,
      "newBillsCount": 0,
      "newBillsAmount": 0,
      "hasPayableBills": false,
      "payableBillCount": 0,
      "payableBillAmount": 0
    }
  ]
}
```

**Frontend**

- Use `res.data.data` as the list of billings.
- User picks a `billingId` to see bills and pay.

---

#### 3.2 Get Bills for a Billing

**Backend endpoint**

```http
GET /api/wallet/billing/bills/:billingId
Authorization: Bearer <token>
```

**Backend → Wallet**

```http
GET {{Wallet-Service}}/api/billing/bills/:billingId
Headers:
  userId: <phoneNumber>
  Authorization: Bearer <walletToken>
```

**Typical Wallet response (simplified)**

```json
{
  "responseCode": true,
  "responseMsg": "Амжилттай",
  "data": {
    "billingId": "90c7...f520",
    "billingName": "ЦАХИЛГААН",
    "customerName": "Д****Н",
    "customerAddress": "БЗД 25-Р ХОРОО",
    "newBills": [
      {
        "billId": "972e9088-...",
        "billerName": "ДАКО-84 СӨХ",
        "billtype": "СӨХ-ийн төлбөр",
        "billtypeGeneral": "HOUSE_OWNER_ASSOCIATION",
        "billNo": "435702487",
        "billAmount": 41200,
        "billTotalAmount": 41200,
        "billPeriod": "2026-3",
        "isNew": false
      }
    ]
  }
}
```

**Backend → frontend**

```json
{
  "success": true,
  "data": {
    "billingId": "...",
    "billingName": "...",
    "newBills": [ ... ]
  }
}
```

**Frontend**

- `const newBills = res.data.data.newBills || []`.
- Let the user choose bills.
- **Wallet limit:** `billIds.length <= 5`.

Example:

```js
const selectedBills = newBills.filter(b => b.selected).slice(0, 5);
const billIds = selectedBills.map(b => b.billId);
```

---

#### 3.3 Get Billing Payments (optional)

**Backend endpoint**

```http
GET /api/wallet/billing/payments/:billingId
Authorization: Bearer <token>
```

**Backend → Wallet**

```http
GET {{Wallet-Service}}/api/billing/payments/:billingId
Headers:
  userId: <phoneNumber>
  Authorization: Bearer <walletToken>
```

Used mainly by backend when a bill is already attached to another invoice.

---

### 4. Wallet Invoice Endpoints

These are thin wrappers over Wallet’s invoice APIs.

#### 4.1 Create Wallet Invoice

**Backend endpoint**

```http
POST /api/wallet/invoice
Authorization: Bearer <token>
Content-Type: application/json
```

**Body**

```json
{
  "billingId": "90c7...f520",
  "billIds": ["billId1", "billId2"],
  "vatReceiveType": "CITIZEN",
  "vatCompanyReg": ""
}
```

**Backend → Wallet**

```http
POST {{Wallet-Service}}/api/invoice
Headers:
  userId: <phoneNumber or walletUserId>
  Authorization: Bearer <walletToken>
Body: invoiceData
```

**Wallet response (simplified)**

```json
{
  "responseCode": true,
  "responseMsg": "Амжилттай",
  "data": {
    "invoiceId": "6df0897a-4b38-4a60-910d-1a374f60cb20",
    "invoiceStatus": "OPEN",
    "invoiceStatusText": "Нээлттэй",
    "isPayable": true,
    "billingId": "...",
    "invoiceAmount": 41200,
    "invoiceTotal": 41600
  }
}
```

Backend returns `data` as `result`.

#### 4.2 Get Wallet Invoice

```http
GET /api/wallet/invoice/:invoiceId
Authorization: Bearer <token>
```

Calls `GET {{Wallet-Service}}/api/invoice/:invoiceId`.

#### 4.3 Cancel Wallet Invoice

```http
PUT /api/wallet/invoice/:invoiceId/cancel
Authorization: Bearer <token>
```

Calls `PUT {{Wallet-Service}}/api/invoice/:invoiceId/cancel`.

---

### 5. Wallet Payment Endpoint (low-level)

Normally, use `/api/qpayGargaya` instead. For completeness:

```http
POST /api/wallet/payment
Authorization: Bearer <token>
Content-Type: application/json
```

Body must include at least `invoiceId`. Backend calls Wallet `createPayment`.

---

### 6. Combined Wallet QPay Endpoint: `/api/qpayGargaya`

This is the **main endpoint** the frontend should use to pay Wallet bills via QPay (bank transfer or QR).

#### 6.1 Request (Wallet QPay mode)

```http
POST /api/qpayGargaya
Authorization: Bearer <token>
Content-Type: application/json
```

**Body**

```json
{
  "baiguullagiinId": "698e7fd3b6dd386b6c56a808",
  "billingId": "90c76d19-f596-4f03-bf02-ad6faba8f520",
  "billIds": [
    "billId1",
    "billId2"
  ],
  "addressSource": "WALLET_API",
  "vatReceiveType": "CITIZEN",
  "vatCompanyReg": ""
}
```

**Rules**

- `billIds.length <= 5` (Wallet limit).
- `addressSource: "WALLET_API"` forces Wallet-QPay path.

#### 6.2 Backend (Wallet-QPay flow)

1. Detect Wallet mode (`addressSource === "WALLET_API"` and wallet data exists, or auto-detect).
2. If `invoiceId` not provided:
   - Call `createInvoice(phoneNumber, { billingId, billIds, ... })`.
   - Get `invoiceId`.
   - Save to `walletInvoice` collection:
     - `userId`, `orshinSuugchId`
     - `walletInvoiceId`
     - `billingId`, `billIds`
     - `billingName`, `customerId`, `customerName`, `customerAddress`
     - `totalAmount`
3. Create Wallet payment (`createPayment`) and extract:
   - `paymentId`
   - `amount`
   - Bank info: `receiverBankCode`, `receiverAccountNo`, `receiverAccountName`
   - Optional QR fields from Wallet (`qrText`, `url`, etc.)
   - **Backend-generated bank QR payload** `walletBankQr` / `walletBankQrText`

**Normal success response (Wallet-QPay path)**

```json
{
  "success": true,
  "data": {
    "paymentId": "4b7de417-58ba-4f28-8ed1-aaa15a321500",
    "amount": 41600,
    "receiverBankCode": "340000",
    "receiverAccountName": "Зэвтабс ХХК",
    "receiverAccountNo": "MN190034349901404632",
    "paymentStatus": "NEW",
    "paymentStatusText": "Төлөгдөөгүй",
    "qrText": "...",        // sometimes
    "url": "..."            // sometimes
  },
  "source": "WALLET_API",
  "invoiceId": "6df0897a-4b38-4a60-910d-1a374f60cb20",
  "needsPolling": false,
  "pollingEndpoint": null,
  "walletBankQr": {
    "type": "WALLET_BANK_PAYMENT",
    "paymentId": "4b7de417-58ba-4f28-8ed1-aaa15a321500",
    "invoiceId": "6df0897a-4b38-4a60-910d-1a374f60cb20",
    "receiverBankCode": "340000",
    "receiverAccountNo": "MN190034349901404632",
    "receiverAccountName": "Зэвтабс ХХК",
    "amount": 41600,
    "currency": "MNT",
    "description": "eBill: 138537  cid: 2003250084301710"
  },
  "walletBankQrText": "{\"type\":\"WALLET_BANK_PAYMENT\",...}"
}
```

**Frontend**

- If `qrText` / `url` present → render QR/open URL as-is.
- Otherwise, if `walletBankQrText` is present:
  - Encode `walletBankQrText` as a QR code image (plain text QR).
  - When scanning inside your own app, parse it back to JSON and:
    - Pre-fill “bank transfer” form with:
      - `receiverBankCode`
      - `receiverAccountNo`
      - `receiverAccountName`
      - `amount`
      - `description`
  - If you have your own deep-linking into bank apps, you can map these fields into your bank URI schema.
- If `needsPolling: true` and `pollingEndpoint` not null → poll until bank info or paid status.

#### 6.3 “Bill already in another invoice” case

If Wallet returns e.g.:

> `Билл өөр нэхэмжлэлээр төлөлт хийгдэж байна: ...`

Backend:

1. Detects this error message.
2. Calls `getBillingPayments(phoneNumber, billingId)` and picks latest payment.
3. Calls `getPayment(phoneNumber, paymentId)` to fetch full details.
4. Extracts:
   - `receiverBankCode`
   - `receiverAccountNo`
   - `receiverAccountName`
   - `amount`
   - builds `transactionDescription` (e.g. `eBill: 138537  cid: ...`).

**Response**

```json
{
  "success": true,
  "data": {
    "paymentId": "4b7de417-58ba-4f28-8ed1-aaa15a321500",
    "paymentAmount": 41600,
    "receiverBankCode": "340000",
    "receiverAccountName": "Зэвтабс ХХК",
    "receiverAccountNo": "MN190034349901404632",
    "transactionDescription": "eBill: 138537  cid: 2003250084301710"
  },
  "source": "WALLET_API"
}
```

**Frontend**

- Show these bank details as a normal bank-transfer view.
- Optionally generate your own QR from:
  - `paymentAmount`
  - `receiverBankCode`
  - `receiverAccountNo`
  - `receiverAccountName`
  - `transactionDescription`

---

### 7. Frontend Flow Summary

1. **List billings**

   ```http
   GET /api/wallet/billing/list
   ```

2. **Select a billing and fetch its bills**

   ```http
   GET /api/wallet/billing/bills/:billingId
   ```

3. **User selects bills to pay (max 5)** and frontend calls:

   ```http
   POST /api/qpayGargaya
   {
     "baiguullagiinId": "...",
     "billingId": "...",
     "billIds": [...],
     "addressSource": "WALLET_API"
   }
   ```

4. **Handle response**

- If `source === "WALLET_API"` and `data.qrText/url` → show Wallet-QPay QR/payment.
- If only `receiver*` + `paymentAmount` → show bank-transfer view or generate QR.
- Respect `needsPolling` and `pollingEndpoint` flags for background status/bank-info updates.

