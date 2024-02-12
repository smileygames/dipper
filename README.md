# dipper -DDNS IP Upper-

### CloudFlare対応
### multi DDNS & IPv6 & multi domain対応
#### GoogleDomainsのDDNSサービス終了に伴い処理を削除、まだ使いたい場合はv1.09以前のバージョンをお使いください。

mydns-ip-updateをお使いの場合は、いったんuninstallしてからdipperをインストールすることお勧めします。

[uninstall方法](https://github.com/smileygames/mydns-ip-update)

事前に必要なもの
- [digコマンド](https://github.com/smileygames/dipper/wiki/dig-command-install)
- [bash version4.3以降](https://github.com/smileygames/dipper/wiki/Bash-Install)

## 概要
- このスクリプトは、DDNSへの自動通知を目的としています。
- 使用する環境はAlmaLinuxで、言語はBashです。（Bashが動く環境なら普通に動くとは思います）
- `config`ディレクトリ内の設定ファイルに基づいて動作します。
- MyDNSの時のみ、IPアドレスを定期的に更新、既定値は1日に1回、設定で変更可能。（初回のみ1分後）
- IPアドレスを定期的にチェック。（既定値は3分に1回チェック、設定で変更可能）
- ドメインのアドレスはDNSサーバーから取得し、自分のIPアドレスと違いがあれば更新。
- キャッシュを使わない為、DNSサーバー側のIPが不測の事態で変わった場合もアドレスUPdateが可能。
- ログはsyslogに記載し、システムで一元管理させている。（dipper.sh の名前でログに書きこまれます）
- 管理はsystemdで行っている。（デーモン化）
- メール通知機能の追加。（オプション）コンフィグファイルに追加されているコメントアウトを外して使用。

### 現在下記DDNSサービスに対応しています。
- [MyDNS.JP](https://www.mydns.jp/)
- [CloudFlare](https://www.cloudflare.com/)  【 [インストールの簡単な説明(v1.12用だが基本は同じ)](https://smgjp.com/cloudflare-dipper/) 】

<br>

MyDNSを使用していて固定IPの場合は、confファイルでIPV4_DDNS及びIPV6_DDNSを「off」にしておいてください。（余計な処理をしなくなる）

<br>

## ワンクリックインストールスクリプト
### インストールコマンド
```bash
bash <( curl -fsSL https://github.com/smileygames/dipper/releases/download/v1.15/install.sh )
```

<br>

▼最初に初期設定を行ってください。

(v1.15より設定項目が変更されたので古いユーザーコンフィグはそのまま使わないでください)

installのたびにコンフィグファイルが初期値に戻ってしまうのも面倒なので
ユーザー側でコンフィグファイルを作成してもらい、上書きインストールでも変更しないようにしました。
但し、uninstallコマンドを実行すると消えます。
```bash
sudo cp -v /usr/local/dipper/config/default.conf /usr/local/dipper/config/user.conf
```
```bash
sudo vim /usr/local/dipper/config/user.conf
```
```bash
#Num=1  # Number 1個目のドメイン
#MYDNS_ID[$Num]="mydnsxxxx1"
#MYDNS_PASS[$Num]="Password1"
#MYDNS_DOMAIN[$Num]="example.com,www.example.com"
#MYDNS_IPV4[$Num]=on
#MYDNS_IPV6[$Num]=off
```
をご自分のMyDNSの情報に書き換えて、先頭の#を削除してください。

編集が終わったら権限を変更しておきます。（IDとPASSを管理したファイルの為）
```bash
sudo chmod 600 /usr/local/dipper/config/user.conf
```

<br>

▼次にサービスの起動です。

```bash
sudo systemctl start dipper.service
```
<br>

### アンインストールスクリプト
▼アンインストールコマンド
```bash
bash <( curl -fsSL https://github.com/smileygames/dipper/releases/download/v1.15/uninstall.sh )
```

<br>

### 設定変更時
コンフィグファイルの内容を変更した際は、
サービスを再起動しないと反映されないので注意です。
```bash
sudo systemctl restart dipper.service
```
<br>

### サービスがもし消えてしまった場合の対処法
サービスをdisabledにした場合リンクが消えてしまうので下記で張りなおします。
"--now"をつけることでついでに起動させます。
```bash
sudo systemctl enable /usr/local/dipper/systemd/dipper.service --now
```
<br>

### [メール送信の仕方](https://github.com/smileygames/dipper.wiki.git****)
<br>

### [マニュアルインストール方法](https://github.com/smileygames/dipper/wiki/%E3%83%9E%E3%83%8B%E3%83%A5%E3%82%A2%E3%83%AB%E3%82%A4%E3%83%B3%E3%82%B9%E3%83%88%E3%83%BC%E3%83%AB%E6%96%B9%E6%B3%95)
<br>
