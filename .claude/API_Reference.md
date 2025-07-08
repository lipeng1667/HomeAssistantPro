
# API Reference

This document provides a detailed reference for the Home Assistant Backend API.

## APIs Table

### For APP

#### 🔑 Auth

| Method | Endpoint             | Description                            |Done|
| ------ | -------------------- | -------------------------------------- |----|
| POST   | `/api/auth/anonymous`| Anonymous login using device_id        | ✅ |
| POST   | `/api/auth/logout`   | End session                            | ✅ |
| POST   | `/api/auth/register` | Register with username and password    | ✅ |
| POST   | `/api/auth/login`    | Register with username and password    | ✅ |

#### 💬 Forum

| Method | Endpoint                         | Description                  |Done|
| ------ | -------------------------------- | ---------------------------- |----|
| GET    | `/api/forum/topics`              | List all topics with pagination | ❌ |
| GET    | `/api/forum/topics/:id`          | Get topic details with replies  | ❌ |
| POST   | `/api/forum/topics`              | Create a new topic           | ❌ |
| PUT    | `/api/forum/topics/:id`          | Update topic (author only)   | ❌ |
| DELETE | `/api/forum/topics/:id`          | Delete topic (author only)   | ❌ |
| GET    | `/api/forum/topics/:id/replies`  | Get replies for a topic      | ❌ |
| POST   | `/api/forum/topics/:id/replies`  | Add reply to topic           | ❌ |
| PUT    | `/api/forum/replies/:id`         | Update reply (author only)   | ❌ |
| DELETE | `/api/forum/replies/:id`         | Delete reply (author only)   | ❌ |
| POST   | `/api/forum/topics/:id/like`     | Like/unlike topic            | ❌ |
| POST   | `/api/forum/replies/:id/like`    | Like/unlike reply            | ❌ |
| GET    | `/api/forum/search`              | Search topics and replies    | ❌ |
| GET    | `/api/forum/categories`          | Get available categories     | ❌ |
| POST   | `/api/forum/upload`              | Upload image attachments     | ❌ |
| GET    | `/api/forum/drafts`              | Get user's saved drafts      | ❌ |
| POST   | `/api/forum/drafts`              | Save/update draft            | ❌ |
| DELETE | `/api/forum/drafts/:id`          | Delete draft                 | ❌ |

#### 📩 Instant Messaging (IM)

| Method | Endpoint             | Description                |Done|
| ------ | -------------------- | -------------------------- |----|
| GET    | `/api/chat/messages` | Fetch chat history         | ❌ |
| POST   | `/api/chat/messages` | Send message to admin/user | ❌ |

#### 📊 Logs

| Method | Endpoint             | Description                                |Done|
| ------ | -------------------- | ------------------------------------------ |----|
| POST   | `/api/logs/activity` | Log user actions (login, navigation, etc.) | ❌ |

### For WebManger

#### 🛠️ Admin

| Method | Endpoint                               | Description                       |Done|
| ------ | -------------------------------------- | --------------------------------- |----|
| POST   | `/api/admin/login`                     | Admin login                       | ❌ |

---

## Authentication

### App-Level Authentication (APP Client Validation)

All authentication endpoints require **app-level authentication** to verify requests originate from authorized mobile APP clients.

**Required Headers:**

| Header | Value | Description |
|--------|-------|-------------|
| `X-Timestamp` | Unix timestamp (ms) | Current timestamp for replay protection |
| `X-Signature` | HMAC-SHA256 hex | Signature: `HMAC-SHA256(app_secret, timestamp)` |

**Signature Generation:**

```javascript
const timestamp = Date.now().toString()
const payload = `${timestamp}`
const signature = crypto.createHmac('sha256', app_secret).update(payload).digest('hex')
```

#### App-Level Authentication Errors

| Error Message | Cause | Solution |
|---------------|-------|----------|
| `"Missing required headers"` | Missing X-Timestamp, X-Signature, or X-App-Type headers | Include all required headers in request |
| `"Invalid timestamp"` | Timestamp is outside 5-minute window or malformed | Use current timestamp in milliseconds |
| `"Invalid signature"` | HMAC-SHA256 signature doesn't match expected value | Verify payload and secret key for signature generation |
| `"Timestamp too old"` | Request timestamp is more than 5 minutes old | Use fresh timestamp for each request |
| `"Timestamp too far in future"` | Request timestamp is more than 5 minutes in future | Check system clock synchronization |

**Security Notes:**

- Timestamp must be within ±5 minutes of server time
- **app_secret** is both store at the client and the server
- Signatures prevent unauthorized access and replay attacks
- All authentication requests are validated before user authentication

---

## APP : Auth API

Handles user authentication.

### `POST /api/auth/anonymous`

Logs in a user anonymous. User set device_id which is generated at the APP side, then server generate user id to
mark this new user, and store the information into the table 'user' in database.

**App Authentication:** Required (see headers above)

**Parameters:**

| Name | Type | Description | Required |
|---|---|---|---|
| `device_id` | String | A unique identifier for the user's device. | Yes |

**Example Request:**

```bash
curl -X POST http://localhost:10000/api/auth/anonymous \
  -H "Content-Type: application/json" \
  -H "X-Timestamp: 1672531200000" \
  -H "X-Signature: a1b2c3d4e5f6..." \
  -d '{"device_id": "iPhone_12_ABC123"}'
```

**Response Structure:**

| Field | Type | Description |
|-------|------|-------------|
| `status` | String | Request status ("success" or "error") |
| `data` | Object | Response data container |
| `data.user` | Object | User information object |
| `data.user.id` | Integer | User's unique database ID |

**Response Error Codes:**

| Status | Error Message | Cause | Solution |
|--------|---------------|-------|----------|
| **400** | `"parameter not found"` | Missing device_id in request body | Include device_id parameter |
| **500** | `"Internal server error"` | Database or Redis error | Check server logs, retry request |

**Example Responses:**

**Success (200)**:

```json
{
  "status": "success",
  "data": {
    "user": {
      "id": 1
    }
  }
}
```

**Error (400)**:

```json
{
  "status": "error",
  "message": "parameter not found"
}
```

### `POST /api/auth/register`

Since user can login anonymously, the APP client should provids two registions options: on the login screen or via settings
menu. If a user register from a setting's menu, it means they've already had an anonymous session and therefor already have a
user ID, this user ID MUST also be sent with the register request. The server will use this user ID to valide that the provided
device id matches the ones stored in Database.

**App Authentication:** Required (see headers above)

**Parameters:**

| Name | Type | Description | Required |
|---|---|---|---|
| `device_id` | String | A unique identifier for the user's device. | Yes |
| `account_name` | String | user name | Yes |
| `phone_number` | String | phone number | Yes |
| `password` | String | sha-256(original password) | Yes |
| `user_id` | String | A id generate by the server and sent to client after anonymously login | NO |

**Example Request:**

```bash
curl -X POST http://localhost:10000/api/auth/register \
  -H "Content-Type: application/json" \
  -H "X-Timestamp: 1672531200000" \
  -H "X-Signature: a1b2c3d4e5f6..." \
  -d '{"device_id": "iPhone_12_ABC123", "account_name": "michale", "phone_number":"18611112222", "password":"64-bit sha256 password"}'
```

**Response Structure:**

| Field | Type | Description |
|-------|------|-------------|
| `status` | String | Request status ("success" or "error") |
| `data` | Object | Response data container |
| `data.user` | Object | User information object |
| `data.user.id` | Integer | User's unique database ID |

**Response Error Codes:**

| Status | Error Message | Cause | Solution |
|--------|---------------|-------|----------|
| **400** | `"parameter invalid"` | parameters missed incorrect format(8-bit password, letters & numbers) | Include required parameter |
| **500** | `"Internal server error"` | Database or Redis error | Check server logs, retry request |

**Example Responses:**

**Success (200)**:

```json
{
  "status": "success",
  "data": {
    "user": {
      "id": 1
    }
  }
}
```

**Error (400)**:

```json
{
  "status": "error",
  "message": "parameter invalid"
}
```

### `POST /api/auth/login`

login with phonenumber and password. database will store the sha-256(original passowrd), so server can compaire the password
using the same encryption method.

**App Authentication:** Required (see headers above)

**Parameters:**

| Name | Type | Description | Required |
|---|---|---|---|
| `user_id` | String | A unique identifier for the user. | Yes |
| `phone_number` | String | phone number | Yes |
| `password` | String | sha-256(sha-256(original password)+timestamp) | Yes |

**Example Request:**

```bash
curl -X POST http://localhost:10000/api/auth/login \
  -H "Content-Type: application/json" \
  -H "X-Timestamp: 1672531200000" \
  -H "X-Signature: a1b2c3d4e5f6..." \
  -d '{"user_id":"23", "phone_number":"18611112222", "password":"64-bit sha256 password"}'
```

**Response Structure:**

| Field | Type | Description |
|-------|------|-------------|
| `status` | String | Request status ("success" or "error") |
| `data` | Object | Response data container |
| `data.user` | Object | User information object |
| `data.user.id` | Integer | User's unique database ID |

**Response Error Codes:**

| Status | Error Message | Cause | Solution |
|--------|---------------|-------|----------|
| **400** | `"parameter invalid"` | parameters missed | Include required parameter |
| **403** | `Forbidden` | wrong password | input the correct passowrd |
| **500** | `"Internal server error"` | Database or Redis error | Check server logs, retry request |

**Example Responses:**

**Success (200)**:

```json
{
  "status": "success",
  "data": {
    "user": {
      "id": 1
    }
  }
}
```

**Error (400)**:

```json
{
  "status": "error",
  "message": "parameter invalid"
}
```

### `POST /api/auth/logout`

Logs out the authenticated user.

**App Authentication:** Required (see headers above)

**Parameters:**

| Name | Type | Description | Required |
|---|---|---|---|
| `user_id` | String | user id return from login | Yes |
| `device_id` | String | A unique identifier for the user's device. | Yes |

**Example Request:**

```bash
curl -X POST http://localhost:10000/api/auth/logout \
  -H "Content-Type: application/json" \
  -H "X-Timestamp: 1672531200000" \
  -H "X-Signature: a1b2c3d4e5f6..." \
  -d '{"user_id": "1", "device_id" : "iPhone_12_ABC123"}'
```

**Response Error Codes:**

| Status | Error Message | Cause | Solution |
|--------|---------------|-------|----------|
| **400** | `"parameter is required"` | Missing device_id in request body | Include device_id parameter |
| **400** | `"Session validation failed or session not found"` | Device ID mismatch or session doesn't exist | Verify device_id matches login device |
| **401** | `"Session not found or expired"` | Invalid user_id or expired session | Login again with valid credentials |
| **500** | `"Internal server error"` | Database or Redis error | Check server logs, retry request |

**Example Responses:**

**Success (200)**:

```json
{
  "status": "success",
  "message": "Logged out successfully"
}
```

**Error (400)**:

```json
{
  "status": "error",
  "message": "parameter is required"
}
```

**Error (401)**:

```json
{
  "status": "error",
  "message": "Session not found or expired"
}
```

---

## APP : Forum API

Handles forum topics, replies, and community interactions.

### `GET /api/forum/topics`

Retrieves a paginated list of forum topics with filtering and sorting options.

**App Authentication:** Required (see headers above)

**Query Parameters:**

| Name | Type | Description | Required | Default |
|---|---|---|---|---|
| `page` | Integer | Page number (1-based) | No | 1 |
| `limit` | Integer | Items per page (1-50) | No | 20 |
| `category` | String | Filter by category | No | All |
| `sort` | String | Sort order: "newest", "oldest", "popular", "trending" | No | "newest" |
| `search` | String | Search in title and content | No | None |

**Example Request:**

```bash
curl -X GET "http://localhost:10000/api/forum/topics?page=1&limit=20&category=Smart+Home&sort=popular" \
  -H "X-Timestamp: 1672531200000" \
  -H "X-Signature: a1b2c3d4e5f6..."
```

**Response Structure:**

| Field | Type | Description |
|-------|------|-------------|
| `status` | String | Request status ("success" or "error") |
| `data` | Object | Response data container |
| `data.topics` | Array | Array of topic objects |
| `data.pagination` | Object | Pagination information |
| `data.pagination.current_page` | Integer | Current page number |
| `data.pagination.total_pages` | Integer | Total number of pages |
| `data.pagination.total_items` | Integer | Total number of topics |
| `data.pagination.has_next` | Boolean | Whether next page exists |
| `data.pagination.has_previous` | Boolean | Whether previous page exists |

**Topic Object Structure:**

| Field | Type | Description |
|-------|------|-------------|
| `id` | Integer | Topic unique ID |
| `title` | String | Topic title |
| `content` | String | Topic content (truncated for list view) |
| `category` | String | Topic category |
| `author` | Object | Author information |
| `author.id` | Integer | Author user ID |
| `author.name` | String | Author display name |
| `author.avatar` | String | Author avatar URL |
| `reply_count` | Integer | Number of replies |
| `like_count` | Integer | Number of likes |
| `is_liked` | Boolean | Whether current user liked this topic |
| `is_hot` | Boolean | Whether topic is trending |
| `has_images` | Boolean | Whether topic contains images |
| `created_at` | String | ISO timestamp of creation |
| `updated_at` | String | ISO timestamp of last update |

**Example Response:**

```json
{
  "status": "success",
  "data": {
    "topics": [
      {
        "id": 1,
        "title": "How to setup motion sensors?",
        "content": "I'm trying to configure motion sensors in my living room...",
        "category": "Smart Home",
        "author": {
          "id": 123,
          "name": "John Doe",
          "avatar": "https://api.example.com/avatars/123.jpg"
        },
        "reply_count": 15,
        "like_count": 8,
        "is_liked": false,
        "is_hot": true,
        "has_images": true,
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-15T15:45:00Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "total_pages": 5,
      "total_items": 95,
      "has_next": true,
      "has_previous": false
    }
  }
}
```

### `GET /api/forum/topics/:id`

Retrieves detailed information about a specific topic including replies.

**App Authentication:** Required (see headers above)

**Path Parameters:**

| Name | Type | Description | Required |
|---|---|---|---|
| `id` | Integer | Topic ID | Yes |

**Query Parameters:**

| Name | Type | Description | Required | Default |
|---|---|---|---|---|
| `reply_page` | Integer | Reply page number | No | 1 |
| `reply_limit` | Integer | Replies per page (1-50) | No | 20 |

**Example Request:**

```bash
curl -X GET "http://localhost:10000/api/forum/topics/1?reply_page=1&reply_limit=20" \
  -H "X-Timestamp: 1672531200000" \
  -H "X-Signature: a1b2c3d4e5f6..."
```

**Response Structure:**

| Field | Type | Description |
|-------|------|-------------|
| `status` | String | Request status ("success" or "error") |
| `data` | Object | Response data container |
| `data.topic` | Object | Complete topic object |
| `data.replies` | Array | Array of reply objects |
| `data.reply_pagination` | Object | Reply pagination information |

**Reply Object Structure:**

| Field | Type | Description |
|-------|------|-------------|
| `id` | Integer | Reply unique ID |
| `content` | String | Reply content |
| `author` | Object | Author information (same as topic) |
| `like_count` | Integer | Number of likes |
| `is_liked` | Boolean | Whether current user liked this reply |
| `images` | Array | Array of image URLs |
| `created_at` | String | ISO timestamp of creation |
| `updated_at` | String | ISO timestamp of last update |

### `POST /api/forum/topics`

Creates a new forum topic.

**App Authentication:** Required (see headers above)

**Parameters:**

| Name | Type | Description | Required |
|---|---|---|---|
| `user_id` | Integer | Author user ID | Yes |
| `title` | String | Topic title (3-100 characters) | Yes |
| `content` | String | Topic content (10-2000 characters) | Yes |
| `category` | String | Topic category | Yes |
| `images` | Array | Array of image URLs (max 3) | No |

**Example Request:**

```bash
curl -X POST http://localhost:10000/api/forum/topics \
  -H "Content-Type: application/json" \
  -H "X-Timestamp: 1672531200000" \
  -H "X-Signature: a1b2c3d4e5f6..." \
  -d '{
    "user_id": 123,
    "title": "Motion sensor setup help",
    "content": "I need help configuring my new motion sensors...",
    "category": "Smart Home",
    "images": ["https://api.example.com/uploads/image1.jpg"]
  }'
```

**Response Structure:**

| Field | Type | Description |
|-------|------|-------------|
| `status` | String | Request status ("success" or "error") |
| `data` | Object | Response data container |
| `data.topic` | Object | Created topic object |

### `POST /api/forum/topics/:id/replies`

Adds a reply to an existing topic.

**App Authentication:** Required (see headers above)

**Parameters:**

| Name | Type | Description | Required |
|---|---|---|---|
| `user_id` | Integer | Reply author user ID | Yes |
| `content` | String | Reply content (1-1000 characters) | Yes |
| `images` | Array | Array of image URLs (max 2) | No |

### `POST /api/forum/topics/:id/like`

Toggles like status for a topic.

**App Authentication:** Required (see headers above)

**Parameters:**

| Name | Type | Description | Required |
|---|---|---|---|
| `user_id` | Integer | User ID performing the action | Yes |

**Response Structure:**

| Field | Type | Description |
|-------|------|-------------|
| `status` | String | Request status ("success" or "error") |
| `data` | Object | Response data container |
| `data.is_liked` | Boolean | New like status |
| `data.like_count` | Integer | Updated like count |

### `GET /api/forum/search`

Searches topics and replies by keyword.

**App Authentication:** Required (see headers above)

**Query Parameters:**

| Name | Type | Description | Required |
|---|---|---|---|
| `q` | String | Search query (min 2 characters) | Yes |
| `type` | String | Search type: "topics", "replies", "all" | No | "all" |
| `category` | String | Filter by category | No | All |
| `page` | Integer | Page number | No | 1 |
| `limit` | Integer | Results per page (1-50) | No | 20 |

### `GET /api/forum/categories`

Retrieves list of available forum categories.

**App Authentication:** Required (see headers above)

**Response Structure:**

| Field | Type | Description |
|-------|------|-------------|
| `status` | String | Request status ("success" or "error") |
| `data` | Object | Response data container |
| `data.categories` | Array | Array of category objects |

**Category Object Structure:**

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Category identifier |
| `name` | String | Category display name |
| `description` | String | Category description |
| `topic_count` | Integer | Number of topics in category |
| `icon` | String | Category icon name |

### `POST /api/forum/upload`

Uploads images for forum posts and replies.

**App Authentication:** Required (see headers above)

**Parameters:**

| Name | Type | Description | Required |
|---|---|---|---|
| `user_id` | Integer | Uploader user ID | Yes |
| `image` | File | Image file (JPG, PNG, max 5MB) | Yes |
| `type` | String | Upload type: "topic" or "reply" | Yes |

**Response Structure:**

| Field | Type | Description |
|-------|------|-------------|
| `status` | String | Request status ("success" or "error") |
| `data` | Object | Response data container |
| `data.image_url` | String | Uploaded image URL |
| `data.image_id` | String | Image identifier |

### `GET /api/forum/drafts`

Retrieves user's saved drafts.

**App Authentication:** Required (see headers above)

**Query Parameters:**

| Name | Type | Description | Required |
|---|---|---|---|
| `user_id` | Integer | User ID | Yes |

### `POST /api/forum/drafts`

Saves or updates a draft.

**App Authentication:** Required (see headers above)

**Parameters:**

| Name | Type | Description | Required |
|---|---|---|---|
| `user_id` | Integer | Draft owner user ID | Yes |
| `title` | String | Draft title | No |
| `content` | String | Draft content | No |
| `category` | String | Draft category | No |
| `type` | String | Draft type: "topic" or "reply" | Yes |
| `topic_id` | Integer | Parent topic ID (for reply drafts) | No |

**Forum API Error Codes:**

| Status | Error Message | Cause | Solution |
|--------|---------------|-------|----------|
| **400** | `"Invalid parameters"` | Missing required fields or invalid format | Check required parameters |
| **401** | `"User not authenticated"` | Invalid or missing user_id | Ensure user is logged in |
| **403** | `"Permission denied"` | User doesn't own the content being modified | Only authors can edit/delete |
| **404** | `"Topic not found"` | Topic ID doesn't exist | Verify topic ID |
| **413** | `"File too large"` | Image exceeds 5MB limit | Compress image before upload |
| **429** | `"Too many requests"` | Rate limit exceeded | Wait before making more requests |

---

## Error Reference

All API endpoints return standardized error responses with the following format:

```json
{
  "status": "error",
  "message": "Description of the error"
}
```

### HTTP Status Codes

| Status Code | Description | When It Occurs |
|-------------|-------------|----------------|
| **200** | Success | Request completed successfully |
| **400** | Bad Request | Missing required parameters, invalid input format |
| **401** | Unauthorized | Invalid authentication, expired session, missing headers |
| **403** | Forbidden | Access denied (e.g., localhost-only endpoints) |
| **404** | Not Found | Endpoint doesn't exist |
| **429** | Too Many Requests | Rate limit exceeded |
| **500** | Internal Server Error | Server-side error, database connection issues |

### Rate Limiting Errors

| Error Message | Cause | Solution |
|---------------|-------|----------|
| `"Too many requests, please try again later"` | Exceeded rate limit (100 requests per 15 minutes) | Wait before making more requests |
| `"Too many login attempts, please try again later"` | Exceeded auth rate limit (5 attempts per 15 minutes) | Wait before attempting authentication |

### System Errors

| Error Message | Cause | Solution |
|---------------|-------|----------|
| `"Endpoint not found"` | Invalid URL or HTTP method | Check API documentation for correct endpoint |
| `"Access denied. This endpoint is only accessible from localhost."` | Accessing localhost-only endpoint from external IP | Use localhost or 127.0.0.1 for health endpoints |

### Best Practices for Error Handling

1. **Always check status field**: Use `status === "error"` to detect failures
2. **Log error messages**: Store error messages for debugging
3. **Implement retry logic**: For 5xx errors, retry with exponential backoff
4. **Handle rate limits**: Implement proper delays when receiving 429 responses
5. **Validate inputs**: Check required parameters before making requests
6. **Monitor timestamps**: Ensure system clocks are synchronized for auth

---
