# watanabe-test-terraform

## 動作にはルートディレクトリに下記tfファイルを作成する必要があります

### variables.tf  
default内を書き換え

```
variable "userNumber" {
    type= string
    default= "xxxxxxxx"
    description = "ユーザーのID、userのarn内にある数字、IAMから確認できる"
}

variable "forwardKey" {
    type= string
    default= "xxxxx"
    description = "cloudFront経由かどうか確認するKey、任意の文字列で良い"   
}
```