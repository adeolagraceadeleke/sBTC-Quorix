# sBTC-Quorix – Smart Payment Requests on Stacks

**sBTC-Quorix** is a smart contract on the Stacks blockchain that allows users to create, fulfill, and manage structured payment requests using sBTC. Think of it as a decentralized invoice or "payment tag" system with expiration, state tracking, and indexing for efficient UI querying.

---

## 🚀 Features

* ✅ **Create PayTags** with amount, expiration, and optional memo
* 💰 **Fulfill payments** directly on-chain with sBTC
* ❌ **Cancel or expire tags** based on business logic
* 🔎 **Efficient indexing** of tags by creator and recipient
* 📦 **Batch read support** for UI/frontend use
* ⏳ **Expiration tracking** with block height-based timeouts
* 🛠️ **Built-in error codes** and consistent state machine

---

## 📄 Contract Overview

### Constants

* **States**: `pending`, `paid`, `expired`, `canceled`
* **Errors**: Range from `ERR-TAG-EXISTS` to `ERR-MAX-EXPIRATION-EXCEEDED`
* **Token**: Uses sBTC token at a defined contract address
* **Max Expiration**: 4320 blocks (\~30 days)

---

## 🗃️ Data Structures

### `pay-tags` (map)

Each PayTag is identified by an auto-incrementing `id` and contains:

* `creator`: Who created the tag
* `recipient`: Who receives payment
* `amount`: Required sBTC amount
* `created-at` / `expires-at`: Block-based timestamps
* `memo`: Optional string (e.g., reason or invoice ID)
* `state`: Current status
* `payment-tx`: Optional tx hash placeholder

### `tags-by-creator` / `tags-by-recipient` (map)

Efficient indexing of PayTags by user, storing up to 50 tag IDs per principal.

---

## 📜 Functions

### 🧾 Public Functions

| Function            | Description                                                    |
| ------------------- | -------------------------------------------------------------- |
| `create-pay-tag`    | Creates a new PayTag with expiration and optional memo         |
| `fulfill-pay-tag`   | Transfers sBTC and marks the tag as `paid`                     |
| `cancel-pay-tag`    | Cancels a tag if it's still pending and caller is creator      |
| `mark-expired`      | Updates state to `expired` if past expiration block            |
| `get-multiple-tags` | Returns up to 20 tags in one call (for frontend batch loading) |

### 🔍 Read-Only Functions

| Function             | Description                                             |
| -------------------- | ------------------------------------------------------- |
| `get-last-id`        | Returns the current counter of PayTag IDs               |
| `get-pay-tag`        | Returns metadata for a single PayTag                    |
| `get-creator-tags`   | Returns list of IDs created by a principal              |
| `get-recipient-tags` | Returns list of IDs where principal is recipient        |
| `check-tag-expired`  | Checks if a tag is logically expired but not yet marked |

---

## ✅ Requirements & Assumptions

* **sBTC** is the token used for payment (defined in `SBTC-CONTRACT`)
* **Contract owner** (currently `tx-sender`) can be used for future admin or upgrade paths
* **Tag expiration** is based on block height (e.g., 4320 blocks ≈ 30 days)
* **Memo** is optional but limited to 256 ASCII characters
* Each user can have up to **50 tags** indexed per role (creator/recipient)

---

## 🧪 Example Use Case

1. Alice creates a PayTag for Bob for `10 sBTC` with a 7-day expiration:

   ```clojure
   (create-pay-tag u1000000 u1008 (some "Invoice #1234"))
   ```
2. Bob later fulfills the tag, transferring sBTC to Alice:

   ```clojure
   (fulfill-pay-tag u1)
   ```
3. If unpaid and past expiration, anyone can mark the tag as expired:

   ```clojure
   (mark-expired u1)
   ```

---

## 📦 Events

```clojure
{ event: "pay-tag-created", id: uint, creator: principal, amount: uint }
{ event: "pay-tag-paid", id: uint, from: principal, to: principal, amount: uint, memo: (optional string) }
{ event: "pay-tag-canceled", id: uint, creator: principal }
{ event: "pay-tag-expired", id: uint }
```

---

## 🔐 Security Notes

* Only creators can cancel their tags
* Expired tags cannot be fulfilled
* Overflows are avoided by using `asserts!` and bounded `uint` values
* No `tx-hash` access due to Clarity limitations (set as `none`)

---
