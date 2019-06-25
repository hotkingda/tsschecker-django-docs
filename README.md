# tsschecker-django API Documentation

所有请求内容类型是 `application/x-www-form-urlencoded`

----

## 登录

**POST** 登录非常简单:

```text
POST /admin/login/?next=/admin/ HTTP/1.1
Host: tss.82flex.com
Content-Type: application/x-www-form-urlencoded
cache-control: no-cache

username=root&password=toor
```

----

## /api/token.json 获取 Access Token

此 **GET** 接口需要登录后调用, 获取到的 Token 默认有效期为一周

```text
GET /api/token.json HTTP/1.1
Host: tss.82flex.com
Content-Type: application/x-www-form-urlencoded
cache-control: no-cache
```

### 响应数据

* `token`, string, **Access Token**
* `expired_at`, int, 过期 Unix 时间戳

```json
{
    "token": "ff373e69-5c15-465e-a8ee-5823563bbd39",
    "expire_at": 1561949443
}
```

----

## /api/register/ 注册设备

### 请求参数

* `token`, string, **Access Token**
* `ecid`, string, 设备 ECID, 即 `UniqueChipID`
* `name`, string, 设备名称
* `hw_model`, string, 平台型号, 如 `n90ap`
* `product_type`, string, 产品型号, 如 `iPhone10,3`
* `ios_version`, string, iOS 版本, 如 `11.4`
* `ios_build`, string, iOS 构建号, 如 `15F5061e`. 可省略
* `generator`, string, 随机数种子. 可省略以随机生成

```text
POST /api/register/ HTTP/1.1
Host: tss.82flex.com
Content-Type: application/x-www-form-urlencoded
User-Agent: PostmanRuntime/7.15.0
Accept: */*
Cache-Control: no-cache
cookie: sessionid=w1p02df79lcsnzicmvuw4vmaxpwofe88
accept-encoding: gzip, deflate
content-length: 137
Connection: keep-alive
cache-control: no-cache

token=ff373e69-5c15-465e-a8ee-5823563bbd39&name=ZhengR&hw_model=N841AP&product_type=iPhone11%2C8&ios_version=12.3.1&ecid=7961160882716718
```

### 响应数据

* `status`, int, 状态代码
    - `200`, ok
    - `400`, 请求格式不正确
    - `403`, 没有权限访问
* `msg`, string, 错误描述

```json
{
    "status": 200,
    "msg": "succeed: device '7961160882716718' created"
}
```

----

## /api/sign/ 获取设备固件签名

### 请求参数

* `token`, string, **Access Token**
* `async`, bool, 是否异步获取, 同步请求时为 `false`
* `ecid`, string, **设备 ECID**
* `ios_version`, string, **申请签名的** iOS 版本, 如 `11.4`
* `ios_build`, string, **申请签名的** iOS 构建号, 如 `15F5061e`. 可省略
* `ap_nonce`, string, 固定 AP Nonce. 可省略
* `sep_nonce`, string, 固定 SEP Nonce. 可省略
* `is_ota`, bool, 是否为 OTA 更新, 默认为 `false`
* `should_replace`, bool, 是否替换现有签名, 默认为 `false`

### 异步确认请求参数

* `async`, bool, 是否异步获取, 异步请求时为 `true`
* `job`, string, 异步任务 ID

### 响应数据

* `status`, int, 状态代码
    - `200`, 同步: 签名成功, 异步: 签名异步任务已提交
    - `400`, 请求格式不正确
    - `403`, 没有权限访问
    - `404`, 找不到指定设备, 设备需要先注册
    - `500`, 不可替换现有签名
    - `501`, 该设备在指定 iOS 版本上的签名已被苹果关闭
    - `502`, 签名保存失败, 请联系管理员检查服务器状态
    - `503`, 日志保存失败, 请联系管理员检查文件系统权限
* `msg`, string, 错误描述
* `job`, object, 异步任务信息, 仅当 `async` 为 `true` 时存在
    - `id`, string, 任务 ID
    - `is_failed`, bool, 任务是否失败
    - `is_finished`, bool, 任务是否完成 (完成并不一定意味着成功, 需结合 `is_failed` 判断)
    - `result`, object, 任务执行结果

### 同步请求示例

```text
POST /api/sign/ HTTP/1.1
Host: tss.82flex.com
Content-Type: application/x-www-form-urlencoded
User-Agent: PostmanRuntime/7.15.0
Accept: */*
Cache-Control: no-cache
cookie: sessionid=w1p02df79lcsnzicmvuw4vmaxpwofe88
accept-encoding: gzip, deflate
content-length: 133
Connection: keep-alive
cache-control: no-cache

token=ff373e69-5c15-465e-a8ee-5823563bbd39&ecid=7961160882716718&ios_version=12.3&async=false
```

```json
{
    "status": 200,
    "msg": "succeed: device '7961160882716718' got signed with 12.3 successfully",
    "stdout": "[TSSR] Sending TSS request attempt 1... success\nSaved shsh blobs!\niOS 12.3 16F156 IS signed!\n\niOS 12.3 for device iPhone11,8 IS being signed!\n",
    "stderr": null
}
```

### 异步请求示例

```text
POST /api/sign/ HTTP/1.1
Host: tss.82flex.com
Content-Type: application/x-www-form-urlencoded
User-Agent: PostmanRuntime/7.15.0
Accept: */*
Cache-Control: no-cache
cookie: sessionid=w1p02df79lcsnzicmvuw4vmaxpwofe88
accept-encoding: gzip, deflate
content-length: 92
Connection: keep-alive
cache-control: no-cache

token=ff373e69-5c15-465e-a8ee-5823563bbd39&ecid=7961160882716718&ios_version=12.3&async=true
```

```json
{
    "status": 200,
    "msg": "succeed: task submitted, proceeding...",
    "job": {
        "id": "25c486aa-7c02-4536-a9da-528de41b3c63",
        "result": null
    }
}
```

异步查询响应示例 (已完成):

```text
POST /api/sign/ HTTP/1.1
Host: tss.82flex.com
Content-Type: application/x-www-form-urlencoded
User-Agent: PostmanRuntime/7.15.0
Accept: */*
Cache-Control: no-cache
cookie: sessionid=w1p02df79lcsnzicmvuw4vmaxpwofe88
accept-encoding: gzip, deflate
content-length: 133
Connection: keep-alive
cache-control: no-cache

token=ff373e69-5c15-465e-a8ee-5823563bbd39&ecid=7961160882716718&ios_version=12.3&async=true&job=25c486aa-7c02-4536-a9da-528de41b3c63
```

```json
{
    "status": 201,
    "msg": "",
    "job": {
        "id": "25c486aa-7c02-4536-a9da-528de41b3c63",
        "is_failed": false,
        "is_finished": true,
        "result": {
            "status": 200,
            "msg": "succeed: device '7961160882716718' got signed with 12.3 successfully",
            "stdout": "[TSSR] Sending TSS request attempt 1... success\nSaved shsh blobs!\niOS 12.3 16F156 IS signed!\n\niOS 12.3 for device iPhone11,8 IS being signed!\n",
            "stderr": null
        }
    }
}
```

----

## Postman Collection

[Postman V2.1](https://www.getpostman.com/)

[下载示例 Collection][1]

[1]: /docs/resources/TssService.postman_collection.json "Download Collection"
