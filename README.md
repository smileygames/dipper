# dipper -DDNS IP Upper-

### CloudFlare対応
### multi DDNS & IPv6 & multi domain対応
#### GoogleDomainのDDNSサービス終了に伴い処理を削除、まだ使いたい場合はv1.09以前のバージョンをお使いください。

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
- IPアドレスを定期的にチェックし変更があれば更新。（既定値は3分に1回チェック、設定で変更可能）
- キャッシュを使わない為、DNSサーバー側のIPが不測の事態で変わった場合もアドレスUPdateが可能。
- ログはsyslogに記載し、システムで一元管理させている。（ip_update.sh の名前でログに書きこまれます）

### 現在下記DDNSサービスに対応しています。
- [MyDNS.JP](https://www.mydns.jp/)
- [CloudFlare](https://www.cloudflare.com/)  【 [インストールの簡単な説明](https://smgjp.com/cloudflare-dipper/) 】

<br>

MyDNSを使用していて固定IPの場合は、confファイルでIPV4_DDNS及びIPV6_DDNSを「off」にしておいてください。（余計な処理をしなくなる）

<br>

## ワンクリックインストールスクリプト
### インストールコマンド
```bash
bash <( curl -fsSL https://github.com/smileygames/dipper/releases/download/v1.10/install.sh )
```

<br>

▼最初に初期設定を行ってください。

(v1.05より設定項目が追加されたので古いユーザーコンフィグはそのまま使わないでください)

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
#Num=1
#MYDNS_ID[$Num]=""
#MYDNS_PASS[$Num]=""
#MYDNS_DOMAIN[$Num]=""
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
bash <( curl -fsSL https://github.com/smileygames/dipper/releases/download/v1.10/uninstall.sh )
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

## マニュアルインストール方法

### ダウンロード及び権限の変更

```bash
Ver="1.10"
wget https://github.com/smileygames/dipper/archive/refs/tags/v${Ver}.tar.gz -O - | sudo tar zxvf - -C ./
sudo mv -fv dipper-${Ver} dipper
sudo cp -rv dipper /usr/local/
sudo rm -rf dipper
sudo chmod -R 755 /usr/local/dipper/bin
```

▼最初に初期設定を行ってください。

ユーザー側でコンフィグファイルを作成してもらい、上書きインストールでも変更しないようにしました。
但し、uninstallコマンドを実行すると消えます。
```bash
sudo cp -v /usr/local/dipper/config/default.conf /usr/local/dipper/config/user.conf
```
```bash
sudo vim /usr/local/dipper/config/user.conf
```
```bash
Num=1
MYDNS_ID[$Num]=""
MYDNS_PASS[$Num]=""
MYDNS_DOMAIN[$Num]=""
MYDNS_IPV4[$Num]=on
MYDNS_IPV6[$Num]=off
```
をご自分のMyDNSの情報に書き換えて、先頭の#を削除してください。

編集が終わったら権限を変更しておきます。（IDとPASSを管理したファイルの為）
```bash
sudo chmod 600 /usr/local/dipper/config/user.conf
```

<br>

### サービスを読み込ませて起動させる
```bash
sudo systemctl enable /usr/local/dipper/systemd/dipper.service --now
```
<br>

## スクリプト構成

自分なりの解釈のオブジェクト指向もどきで作り直しました。

言語はシェルスクリプトです。

![dipper：スクリプト構成図 のコピー](https://github.com/smileygames/dipper/assets/134200591/c8a209d2-296e-410b-90b7-6589eb494e63)
