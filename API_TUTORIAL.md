# Evolution API 完整使用教學

## 目錄
1. [基礎設定](#基礎設定)
2. [認證方式](#認證方式)
3. [實例管理 API](#實例管理-api)
4. [訊息發送 API](#訊息發送-api)
5. [群組管理 API](#群組管理-api)
6. [聊天管理 API](#聊天管理-api)
7. [聯絡人管理 API](#聯絡人管理-api)
8. [設定管理 API](#設定管理-api)
9. [Webhook 與事件](#webhook-與事件)

---

## 基礎設定

### API 基礎 URL
```
http://localhost:8080
```

### 必需 Header
| Header | 說明 | 範例 |
|--------|------|------|
| `apikey` | 全域 API Key | `429683C4C977415CAAFCCE10F7D57E11` |
| `Content-Type` | 內容類型 | `application/json` |

---

## 認證方式

Evolution API 使用 **API Key** 認證，有兩個層級：

### 1. 全域 API Key（管理用）
喺 `.env` 設定：`AUTHENTICATION_API_KEY`
用嚟建立實例、管理所有實例

### 2. 實例專屬 API Key
每個實例建立時可以設定自己嘅 token
用嚟操作特定實例（發訊息、取得資料等）

---

## 實例管理 API

### 1. 建立實例
```bash
curl -X POST http://localhost:8080/instance/create \
  -H "apikey: YOUR_GLOBAL_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "instanceName": "test-instance",
    "token": "my-instance-token",
    "qrcode": true
  }'
```

**參數說明：**
| 參數 | 類型 | 必填 | 說明 |
|------|------|------|------|
| `instanceName` | string | ✅ | 實例名稱（唯一） |
| `token` | string | ❌ | 實例專屬 API Key |
| `qrcode` | boolean | ❌ | 是否產生 QR Code |
| `number` | string | ❌ | 電話號碼（Business API 用） |

**成功回應：**
```json
{
  "instance": {
    "instanceName": "test-instance",
    "status": "created",
    "qrcode": "data:image/png;base64,..."
  }
}
```

---

### 2. 連接 WhatsApp（取得 QR Code）
```bash
curl -X GET "http://localhost:8080/instance/connect/test-instance" \
  -H "apikey: YOUR_GLOBAL_API_KEY"
```

**回應：**
```json
{
  "qrcode": {
    "base64": "data:image/png;base64,...",
    "pairingCode": "123-456"
  }
}
```

---

### 3. 查詢連線狀態
```bash
curl -X GET "http://localhost:8080/instance/connectionState/test-instance" \
  -H "apikey: YOUR_API_KEY"
```

**回應：**
```json
{
  "instance": {
    "instanceName": "test-instance",
    "state": "open",
    "status": "connected"
  }
}
```

**狀態說明：**
- `open` - 已連線
- `connecting` - 正在連線
- `close` - 已斷線
- `qrcode` - 等待掃描 QR Code

---

### 4. 取得所有實例
```bash
curl -X GET "http://localhost:8080/instance/fetchInstances" \
  -H "apikey: YOUR_GLOBAL_API_KEY"
```

---

### 5. 重新啟動實例
```bash
curl -X POST "http://localhost:8080/instance/restart/test-instance" \
  -H "apikey: YOUR_API_KEY"
```

---

### 6. 登出 WhatsApp
```bash
curl -X DELETE "http://localhost:8080/instance/logout/test-instance" \
  -H "apikey: YOUR_API_KEY"
```

---

### 7. 刪除實例
```bash
curl -X DELETE "http://localhost:8080/instance/delete/test-instance" \
  -H "apikey: YOUR_GLOBAL_API_KEY"
```

---

## 訊息發送 API

**注意：** 所有發訊息 API 都需要實例已連線（state = open）

### 1. 發送文字訊息
```bash
curl -X POST "http://localhost:8080/message/sendText/test-instance" \
  -H "apikey: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "number": "85298765432",
    "text": "你好！呢條係測試訊息",
    "delay": 1000
  }'
```

**參數說明：**
| 參數 | 類型 | 必填 | 說明 |
|------|------|------|------|
| `number` | string | ✅ | 接收者電話（國際格式） |
| `text` | string | ✅ | 訊息內容 |
| `delay` | number | ❌ | 延遲毫秒數 |
| `quoted` | object | ❌ | 引用訊息 |
| `mentionsEveryOne` | boolean | ❌ | @所有人 |
| `mentioned` | array | ❌ | 提及特定用戶 |
| `linkPreview` | boolean | ❌ | 連結預覽 |

---

### 2. 發送圖片
```bash
curl -X POST "http://localhost:8080/message/sendMedia/test-instance" \
  -H "apikey: YOUR_API_KEY" \
  -F "number=85298765432" \
  -F "mediatype=image" \
  -F "caption=呢張係測試圖片" \
  -F "file=@/path/to/image.jpg"
```

**或使用 Base64：**
```bash
curl -X POST "http://localhost:8080/message/sendMedia/test-instance" \
  -H "apikey: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "number": "85298765432",
    "mediatype": "image",
    "media": "base64encodedstring...",
    "caption": "呢張係測試圖片"
  }'
```

**MediaType 選項：**
- `image` - 圖片
- `video` - 影片
- `audio` - 音訊
- `document` - 文件

---

### 3. 發送影片
```bash
curl -X POST "http://localhost:8080/message/sendMedia/test-instance" \
  -H "apikey: YOUR_API_KEY" \
  -F "number=85298765432" \
  -F "mediatype=video" \
  -F "caption=測試影片" \
  -F "file=@/path/to/video.mp4"
```

---

### 4. 發送語音訊息
```bash
curl -X POST "http://localhost:8080/message/sendWhatsAppAudio/test-instance" \
  -H "apikey: YOUR_API_KEY" \
  -F "number=85298765432" \
  -F "encoding=true" \
  -F "file=@/path/to/audio.mp3"
```

**參數：**
- `encoding=true` - 自動轉換為 WhatsApp 語音格式（ogg/opus）

---

### 5. 發送文件
```bash
curl -X POST "http://localhost:8080/message/sendMedia/test-instance" \
  -H "apikey: YOUR_API_KEY" \
  -F "number=85298765432" \
  -F "mediatype=document" \
  -F "fileName=report.pdf" \
  -F "caption=請查收報告" \
  -F "file=@/path/to/document.pdf"
```

---

### 6. 發送貼紙 (Sticker)
```bash
curl -X POST "http://localhost:8080/message/sendSticker/test-instance" \
  -H "apikey: YOUR_API_KEY" \
  -F "number=85298765432" \
  -F "file=@/path/to/sticker.webp"
```

---

### 7. 發送按鈕訊息
```bash
curl -X POST "http://localhost:8080/message/sendButtons/test-instance" \
  -H "apikey: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "number": "85298765432",
    "title": "請選擇服務",
    "description": "你想查詢咩？",
    "footer": "謝謝",
    "buttons": [
      {
        "type": "reply",
        "displayText": "查詢價格",
        "id": "btn_price"
      },
      {
        "type": "reply",
        "displayText": "聯絡客服",
        "id": "btn_support"
      },
      {
        "type": "reply",
        "displayText": "了解更多",
        "id": "btn_info"
      }
    ]
  }'
```

**按鈕類型：**
- `reply` - 回覆按鈕（最多 3 個）
- `url` - 開啟連結
- `call` - 撥打電話
- `copy` - 複製文字
- `pix` - 巴西 Pix 付款

---

### 8. 發送列表訊息
```bash
curl -X POST "http://localhost:8080/message/sendList/test-instance" \
  -H "apikey: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "number": "85298765432",
    "title": "我哋嘅服務",
    "description": "請選擇你感興趣嘅服務",
    "buttonText": "查看選項",
    "footerText": "謝謝查詢",
    "sections": [
      {
        "title": "產品類別",
        "rows": [
          {
            "title": "電子產品",
            "description": "手機、電腦、配件",
            "rowId": "row_electronics"
          },
          {
            "title": "時尚服飾",
            "description": "男女裝、鞋履、袋",
            "rowId": "row_fashion"
          }
        ]
      },
      {
        "title": "支援",
        "rows": [
          {
            "title": "客戶服務",
            "description": "聯絡我哋嘅支援團隊",
            "rowId": "row_support"
          }
        ]
      }
    ]
  }'
```

---

### 9. 發送投票 (Poll)
```bash
curl -X POST "http://localhost:8080/message/sendPoll/test-instance" \
  -H "apikey: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "number": "85298765432",
    "name": "你最鍾意邊種顏色？",
    "selectableCount": 1,
    "values": ["紅色", "藍色", "綠色", "黃色"]
  }'
```

**注意：** 投票功能只限 Baileys 連接可用

---

### 10. 發送聯絡人名片
```bash
curl -X POST "http://localhost:8080/message/sendContact/test-instance" \
  -H "apikey: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "number": "85298765432",
    "contact": [
      {
        "fullName": "陳大文",
        "wuid": "85291234567@s.whatsapp.net",
        "phoneNumber": "85291234567"
      }
    ]
  }'
```

---

### 11. 發送位置
```bash
curl -X POST "http://localhost:8080/message/sendLocation/test-instance" \
  -H "apikey: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "number": "85298765432",
    "latitude": 22.3193,
    "longitude": 114.1694,
    "name": "旺角地鐵站",
    "address": "香港旺角"
  }'
```

---

### 12. 發送反應 (Reaction)
```bash
curl -X POST "http://localhost:8080/message/sendReaction/test-instance" \
  -H "apikey: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "key": {
      "remoteJid": "85298765432@s.whatsapp.net",
      "fromMe": false,
      "id": "MESSAGE_ID"
    },
    "reaction": "👍"
  }'
```

---

### 13. 發送狀態 (Stories)
```bash
curl -X POST "http://localhost:8080/message/sendStatus/test-instance" \
  -H "apikey: YOUR_API_KEY" \
  -F "type=image" \
  -F "caption=我嘅狀態" \
  -F "file=@/path/to/status.jpg"
```

**注意：** 狀態功能只限 Baileys 連接可用

---

## 群組管理 API

### 1. 建立群組
```bash
curl -X POST "http://localhost:8080/group/create/test-instance" \
  -H "apikey: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "subject": "測試群組",
    "description": "呢個係測試群組",
    "participants": ["85291234567", "85292345678"]
  }'
```

---

### 2. 取得群組資訊
```bash
curl -X GET "http://localhost:8080/group/findGroupInfos/test-instance?groupJid=123456789@g.us" \
  -H "apikey: YOUR_API_KEY"
```

---

### 3. 取得所有群組
```bash
curl -X GET "http://localhost:8080/group/fetchAllGroups/test-instance?getParticipants=true" \
  -H "apikey: YOUR_API_KEY"
```

---

### 4. 更新群組主題
```bash
curl -X POST "http://localhost:8080/group/updateGroupSubject/test-instance" \
  -H "apikey: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "groupJid": "123456789@g.us",
    "subject": "新群組名稱"
  }'
```

---

### 5. 更新群組描述
```bash
curl -X POST "http://localhost:8080/group/updateGroupDescription/test-instance" \
  -H "apikey: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "groupJid": "123456789@g.us",
    "description": "新群組描述"
  }'
```

---

### 6. 更新群組圖片
```bash
curl -X POST "http://localhost:8080/group/updateGroupPicture/test-instance" \
  -H "apikey: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "groupJid": "123456789@g.us",
    "image": "base64encodedimage..."
  }'
```

---

### 7. 取得群組成員
```bash
curl -X GET "http://localhost:8080/group/participants/test-instance?groupJid=123456789@g.us" \
  -H "apikey: YOUR_API_KEY"
```

---

### 8. 新增成員
```bash
curl -X POST "http://localhost:8080/group/updateParticipants/test-instance" \
  -H "apikey: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "groupJid": "123456789@g.us",
    "participants": ["85291234567", "85292345678"],
    "action": "add"
  }'
```

**Action 類型：** `add` | `remove` | `promote` | `demote`

---

### 9. 取得群組邀請連結
```bash
curl -X GET "http://localhost:8080/group/inviteCode/test-instance?groupJid=123456789@g.us" \
  -H "apikey: YOUR_API_KEY"
```

---

### 10. 透過連結加入群組
```bash
curl -X POST "http://localhost:8080/group/acceptInvite/test-instance" \
  -H "apikey: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "inviteCode": "ABC123XYZ"
  }'
```

---

### 11. 設定群組定時訊息
```bash
curl -X POST "http://localhost:8080/group/toggleEphemeral/test-instance" \
  -H "apikey: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "groupJid": "123456789@g.us",
    "ephemeralDuration": 86400
  }'
```

**ephemeralDuration 選項：**
- `0` - 關閉
- `86400` - 1 日
- `604800` - 1 星期
- `7776000` - 90 日

---

## 聊天管理 API

### 1. 檢查號碼是否用 WhatsApp
```bash
curl -X POST "http://localhost:8080/chat/whatsappNumbers/test-instance" \
  -H "apikey: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "numbers": ["85291234567", "85292345678"]
  }'
```

**回應：**
```json
[
  {
    "number": "85291234567",
    "exists": true,
    "jid": "85291234567@s.whatsapp.net"
  }
]
```

---

### 2. 標記訊息已讀
```bash
curl -X POST "http://localhost:8080/chat/markMessageAsRead/test-instance" \
  -H "apikey: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "number": "85298765432",
    "messageId": "MESSAGE_ID"
  }'
```

---

### 3. 封存聊天
```bash
curl -X POST "http://localhost:8080/chat/archiveChat/test-instance" \
  -H "apikey: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "number": "85298765432",
    "archive": true
  }'
```

---

### 4. 標記聊天未讀
```bash
curl -X POST "http://localhost:8080/chat/markChatUnread/test-instance" \
  -H "apikey: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "number": "85298765432"
  }'
```

---

### 5. 刪除訊息
```bash
curl -X DELETE "http://localhost:8080/chat/deleteMessageForEveryone/test-instance" \
  -H "apikey: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "key": {
      "remoteJid": "85298765432@s.whatsapp.net",
      "fromMe": true,
      "id": "MESSAGE_ID"
    }
  }'
```

---

### 6. 取得聯絡人資料
```bash
curl -X GET "http://localhost:8080/chat/findContacts/test-instance" \
  -H "apikey: YOUR_API_KEY"
```

---

### 7. 取得聊天紀錄
```bash
curl -X POST "http://localhost:8080/chat/findMessages/test-instance" \
  -H "apikey: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "where": {
      "key": {
        "remoteJid": "85298765432@s.whatsapp.net"
      }
    },
    "limit": 50
  }'
```

---

### 8. 取得媒體檔案 Base64
```bash
curl -X POST "http://localhost:8080/chat/getBase64FromMediaMessage/test-instance" \
  -H "apikey: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "key": {
        "id": "MESSAGE_ID",
        "remoteJid": "85298765432@s.whatsapp.net"
      }
    }
  }'
```

---

## 聯絡人管理 API

### 1. 取得所有聯絡人
```bash
curl -X GET "http://localhost:8080/chat/findContacts/test-instance" \
  -H "apikey: YOUR_API_KEY"
```

---

### 2. 封鎖/解封用戶
```bash
curl -X POST "http://localhost:8080/chat/blockUser/test-instance" \
  -H "apikey: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "number": "85298765432",
    "status": "block"
  }'
```

**Status：** `block` | `unblock`

---

### 3. 更新個人資料名稱
```bash
curl -X POST "http://localhost:8080/chat/updateProfileName/test-instance" \
  -H "apikey: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "我嘅新名稱"
  }'
```

---

### 4. 更新個人資料圖片
```bash
curl -X POST "http://localhost:8080/chat/updateProfilePicture/test-instance" \
  -H "apikey: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "picture": "base64encodedimage..."
  }'
```

---

### 5. 更新個人狀態
```bash
curl -X POST "http://localhost:8080/chat/updateProfileStatus/test-instance" \
  -H "apikey: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "status": "我係度用 Evolution API"
  }'
```

---

### 6. 取得個人資料圖片 URL
```bash
curl -X POST "http://localhost:8080/chat/fetchProfilePictureUrl/test-instance" \
  -H "apikey: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "number": "85298765432"
  }'
```

---

### 7. 取得用戶狀態
```bash
curl -X GET "http://localhost:8080/chat/findStatus/test-instance" \
  -H "apikey: YOUR_API_KEY"
```

---

## 設定管理 API

### 1. 取得實例設定
```bash
curl -X GET "http://localhost:8080/settings/find/test-instance" \
  -H "apikey: YOUR_API_KEY"
```

---

### 2. 更新實例設定
```bash
curl -X POST "http://localhost:8080/settings/update/test-instance" \
  -H "apikey: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "rejectCall": false,
    "msgCall": "我而家接唔到電話",
    "groupsIgnore": false,
    "alwaysOnline": true,
    "readMessages": true,
    "readStatus": true,
    "syncFullHistory": false
  }'
```

**設定說明：**
| 設定 | 說明 |
|------|------|
| `rejectCall` | 自動拒絕來電 |
| `msgCall` | 拒絕來電時嘅自動回覆 |
| `groupsIgnore` | 忽略群組訊息 |
| `alwaysOnline` | 保持上線狀態 |
| `readMessages` | 自動已讀訊息 |
| `readStatus` | 自動查看狀態 |
| `syncFullHistory` | 同步完整歷史訊息 |

---

### 3. 設定存在狀態
```bash
curl -X POST "http://localhost:8080/instance/setPresence/test-instance" \
  -H "apikey: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "number": "85298765432",
    "presence": "composing"
  }'
```

**Presence 選項：**
- `unavailable` - 離線
- `available` - 上線
- `composing` - 輸入中
- `recording` - 錄音中
- `paused` - 暫停

---

## Webhook 與事件

### Webhook 設定
建立實例時可以設定 webhook：

```bash
curl -X POST "http://localhost:8080/instance/create" \
  -H "apikey: YOUR_GLOBAL_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "instanceName": "test-instance",
    "webhook": {
      "enabled": true,
      "url": "https://your-server.com/webhook",
      "events": [
        "MESSAGES_UPSERT",
        "CONNECTION_UPDATE",
        "QRCODE_UPDATED"
      ],
      "headers": {
        "X-Custom-Header": "value"
      }
    }
  }'
```

### 支援嘅事件類型
| 事件 | 說明 |
|------|------|
| `MESSAGES_UPSERT` | 收到新訊息 |
| `MESSAGES_UPDATE` | 訊息更新 |
| `MESSAGES_DELETE` | 訊息刪除 |
| `SEND_MESSAGE` | 發送訊息 |
| `CONNECTION_UPDATE` | 連線狀態更新 |
| `QRCODE_UPDATED` | QR Code 更新 |
| `CONTACTS_UPSERT` | 聯絡人新增/更新 |
| `CHATS_UPSERT` | 聊天新增/更新 |
| `GROUPS_UPSERT` | 群組新增/更新 |
| `PRESENCE_UPDATE` | 存在狀態更新 |
| `CALL` | 來電 |

---

## 錯誤處理

### 常見錯誤碼
| 狀態碼 | 說明 | 解決方法 |
|--------|------|----------|
| `400` | Bad Request | 檢查請求參數 |
| `401` | Unauthorized | 檢查 API Key |
| `403` | Forbidden | 實例無權限 |
| `404` | Not Found | 實例唔存在 |
| `500` | Internal Server Error | 伺服器錯誤 |

### 錯誤回應格式
```json
{
  "status": 400,
  "error": "Invalid request",
  "message": "Number is required"
}
```

---

## 電話號碼格式

- **個人用戶：** `85298765432`（國際格式，唔需要加 +）
- **群組：** `123456789@g.us`
- **廣播：** `123456789@broadcast`

---

## 重要注意事項

1. **實例必須連線後先可以發訊息**
   - 檢查狀態：`connectionState` API
   - 等待 `state: "open"`

2. **Baileys vs Business API 功能差異**
   - 投票、狀態、貼紙只限 Baileys
   - 範本訊息只限 Business API

3. **Rate Limiting**
   - 避免短時間內發送大量訊息
   - WhatsApp 可能會封鎖濫用行為

4. **訊息延遲**
   - 建議使用 `delay` 參數（1000-3000ms）
   - 模擬真人輸入

5. **媒體檔案限制**
   - 圖片：建議 < 5MB
   - 影片：建議 < 16MB
   - 文件：最大 100MB
