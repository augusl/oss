
## host :  [https://](https://api.pro.mindu.io/)[api.pro.mindu.io](https://api.pro.mindu.io/)

## 一 .注册设备 api (每次打开app时调用)

url:                  /api/v2/device/register

请求方式:        post

数据提交方式: application/json

请求参数:

|参数名|必填|类型|默认值|说明|
|:----|:----|:----|:----|:----|
|UUID|     是|string|    |    |
|ProductId|     是|nubmer|60001|    |
|Os|     是|string|android|    |
|OsVersion|     是|string|    |系统版本号|
|DeviceModel|    是|string|    |iPhone X  .....|
|AppVersion|    是|string|    |app 版本|
|LangCode|    是| string|en|    |

|Idfa|  否|string|    |    |
|:----|:----|:----|:----|:----|

response : 

```plain
{
    "code": 0,
    "message": "OK",
    "data": []
}
```
说明: code 为 0 响应正常, 其他code 为异常

## 二.付费充值

url : /api/v2/payment/recharge

请求方式 : post

数据提交方式: application/json

请求参数:

|参数名|必填|类型|默认值|说明|
|:----|:----|:----|:----|:----|
|UUID|     是|string|    |    |
|ProductId|     是|nubmer|60001|    |
|Os|     是|string|android|    |
|OsVersion|     是|string|    |系统版本号|
|DeviceModel|    是|string|    |iPhone X  .....|
|AppVersion|    是|string|    |app 版本|
|LangCode|    是| string|en|    |

|Idfa|否|string|    |    |
|:----|:----|:----|:----|:----|
|Amount|是|string|    |充值金额|






