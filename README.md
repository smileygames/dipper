# dipper - DDNS IP Updater

dipper は **Bash で実装された DDNS クライアント**です。  
単に IP を更新するだけでなく、  
**DDNS サーバーに不要な負荷をかけないこと**を最重要視して設計されています。

長期間動かしても壊れにくく、  
あとから「なぜこう設計したのか」を思い出せることを目的としたツールです。

※ 現在は安定運用中のため、メンテナンス頻度は低めです。

---

## 特徴

- DDNS サーバーへの **不要なアクセスを極力避ける設計**
- cron / systemd timer を使わない **疑似スケジューラ方式**
- 状態をメモリではなく **ファイル（cache）で管理**
- IPv4 / IPv6 対応
- マルチドメイン対応
- メール通知機能有り（オプション）
- systemd サービスとして常駐動作
- 実機デバッグを前提とした運用設計

---

## 対応 DDNS サービス
・作者も現在使用中
- [MyDNS.JP](https://www.mydns.jp/)
- [Cloudflare](https://www.cloudflare.com/)　※参考記事（v1.16 向けだが基本は同じ）https://smgjp.com/cloudflaredipper_ddns_dipper/

・それ以外（今後対応することがあるかも？）
---

## 動作環境・前提条件

- Linux
- systemd（systemctl）
- /proc が利用可能
- Bash 4.3 以降

### install.sh 実行時に自動インストールされるコマンド
- curl
- tar
- dig
- jq

---

## クイックスタート（インストール）

以下のワンライナーでインストールできます。

```bash
bash <( curl -fsSL https://github.com/smileygames/dipper/releases/download/v2.0/install.sh )
```
補足
- systemd サービスとして登録されます
- SELinux 有効環境では restorecon を考慮したインストールを行います
- /usr/local/dipper にインストールされます

### 初期設定
インストール後、最初に設定ファイルを作成してください。

```bash
sudo cp -v /usr/local/dipper/config/default.conf /usr/local/dipper/config/user.conf
sudo vim /usr/local/dipper/config/user.conf
```
設定例（MyDNS）
```bash
#Num=1  # Number 1個目のドメイン
#MYDNS_ID[$Num]="mydnsxxxx1"
#MYDNS_PASS[$Num]="Password1"
#MYDNS_DOMAIN[$Num]="example.com,www.example.com"
#MYDNS_IPV4[$Num]=on
#MYDNS_IPV6[$Num]=off
```
自分の MyDNS 情報に書き換え、先頭の # を外してください。

設定ファイルの権限変更（重要）
```bash
sudo chmod 600 /usr/local/dipper/config/user.conf
```

サービス起動
```bash
sudo systemctl start dipper.service
```

### 設定変更時
設定ファイルを変更した場合は、サービス再起動が必要です。

```bash
sudo systemctl restart dipper.service
```

### systemd について
- dipper は systemd サービスとしての利用を前提としています。
- cron 等での実行も理論上は可能ですが、
本プロジェクトでは 動作検証およびサポートは行っていません。

### 固定 IP を使用している場合（MyDNS）
固定 IP の場合は、不要な更新を避けるため
以下を off にしてください。

```bash
IPV4_DDNS=off
IPV6_DDNS=off
```

### メール通知（オプション）
IPアドレス変更やエラー時のメール通知機能があります。
設定方法は以下を参照してください。

https://github.com/smileygames/dipper/wiki/メール送信の仕方

### アンインストール
```bash
sudo bash /usr/local/dipper/uninstall.sh
```
※ uninstall を実行すると設定ファイルも削除されます。

### 設計思想
dipper の設計背景・思想については Wiki にまとめています。

設計思想（全文）
https://github.com/smileygames/dipper/wiki/設計思想

この設計思想は、自分なりの理想を詰め込んだものです。
dipper は、作者自身が納得して長く使い続けるための選択の集合です。
