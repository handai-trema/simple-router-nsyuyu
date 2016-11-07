# 第五回レポート課題(11/2出題，11/8解答)
## 課題内容(ルータのCLIを作ろう)
以下のコマンド操作を実行できる，ルータのコマンドラインインタフェース(CLI)を作成せよ．

* ルーティングテーブルの表示
* ルーティングテーブルエントリの追加と削除
* ルータのインタフェース一覧の表示

コントローラを操作するコマンドの作り方は，第三回パッチパネルで作った
patch_panelコマンドを参考にすること．

## 解答
CLIを作成するにあたって，simple_routerプロセスを動作させるプログラムを新たに作成し(simple_router)，
interface.rb，routing_table.rb，simple_router.rbに対して，プログラムの追加・修正を行った．

それぞれの機能の仕様，実装方法，動作確認について，以下に記す．
なお，動作確認については，それぞれの機能毎ではなく，全てまとめて行った．

### ルーティングテーブルの表示
#### 仕様
ルーティングテーブルを表示するコマンドの仕様を以下に示す．
```
#入力
./bin/simple_router show_rt
#出力
---------- show routing table ----------
     destination        next_hop
宛先アドレス/ネットマスク長  次の転送先


#出力例
---------- show routing table ----------
     destination        next_hop
       0.0.0.0/0     192.168.1.2
```

#### 実装
ルーティングテーブルの表示機能の実現にあたって，SimpleRouterクラスにshow_routing_table関数を，
RoutingTableクラスにshow_table関数を実装した．

show_routing_table関数のソースコードを以下に示す．
```ruby
21  def show_routing_table()
22    @routing_table.show_table()
23  end
```
show_routing_table関数は，simple_routerプロセスから呼び出される．
この関数では，RoutingTableクラスのインスタンスメソッドとして実装した
show_table関数を呼び出している．
なお，RoutingTableクラスのインスタンスは，SimpleRouterクラスの
インスタンス変数である@routing_tableに格納されている

次に，show_table関数のソースコードを以下に示す．
```ruby
45  def show_table()
46    print("---------- show routing table ----------\n")
47    print("destination".rjust(16))
48    print("next_hop".rjust(16))
49    print("\n")
50    @db.each_index do |netmask_length|
51      @db[netmask_length].each do |prefix,next_hop|
52        prefix_addr = IPv4Address.new(prefix).to_s
53        print("#{prefix_addr}/#{netmask_length}".rjust(16))
54        print("#{next_hop}".rjust(16))
55        print("\n\n")
56      end
57    end
58  end
```
show_table関数では，ルーティングテーブルの表示に関する処理を行っており，
エントリの情報が格納されているインスタンス変数@dbからエントリの情報
(宛先アドレス，ネットマスク長，次の転送先アドレス)を取り出し，仕様に従ったフォーマット
で取得したエントリの情報を表示している(50〜57行目)．

### ルーティングテーブルエントリの追加(更新)
#### 仕様
ルーティングテーブルエントリの追加を行うコマンドの仕様を以下に示す．
```
#入力
./bin/simple_router add 宛先アドレス ネットマスク長 次の転送先アドレス
#出力
##追加に成功した場合
success add entry
##既に同じ宛先アドレス，ネットマスク長を持つエントリが登録されている場合
success update entry

#入力例
./bin/simple_router add 192.168.1.5 24 192.168.1.2
./bin/simple_router add 192.168.1.5 24 192.168.1.3
#出力例
success add entry
success update entry
```

#### 実装
ルーティングテーブルエントリの追加(更新)機能の実現にあたって，
SimpleRouterクラスにadd_entry関数を，
RoutingTableクラスにadd関数を実装した．

add_entry関数のソースコードを以下に示す．
```ruby
29  def add_entry(dest,mask,hop)
30    entry = {destination: dest, netmask_length: mask.to_i, next_hop: hop}
31    @routing_table.add(entry)
32  end
```
add_entry関数は，simple_routerプロセスから呼び出される．
この関数では，simple_routerプロセスから渡される引数の情報(宛先アドレス，ネットマスク長，次の転送先アドレス)を
ハッシュ形式でまとめ(30行目)，RoutingTableクラスのインスタンスメソッドとして実装したadd関数を呼び出している(31行目)．

次に，add関数のソースコードを以下に示す．
```ruby
12  def add(options)
13    netmask_length = options.fetch(:netmask_length)
14    prefix = IPv4Address.new(options.fetch(:destination)).mask(netmask_length)
15    entry = @db[netmask_length][prefix.to_i]
16    @db[netmask_length][prefix.to_i] = IPv4Address.new(options.fetch(:next_hop))
17    if entry then
18      print("success update entry\n")
19    else
20      print("success add entry\n")
21    end
22  end
```
add関数では，ルーティングテーブルの情報を保持しているインスタンス変数@dbに，新たな
エントリの情報を追加する処理を行っている．
まず，宛先アドレス，ネットマスク長を取得し(13行目，14行目)，@dbに既に同じエントリが
登録されているかを調べ(15行目)，@dbに新たなエントリの情報を書き込む(16行目)．
なお，@dbでは，ネットマスク長の情報はハッシュのキー値として，宛先アドレスは配列の添字として，
次の転送先アドレスはハッシュの要素となる配列の要素として，エントリの情報を保存している．
既に同じ宛先アドレス，ネットマスク長のエントリが登録されている場合，この操作をエントリの
更新とみなし，"success update entry"といったメッセージを出力する(17，18行目)．
同じエントリが登録されていない場合は，"success add entry"といった，エントリの追加に
成功したことを知らせる旨のメッセージを出力する．


### ルーティングテーブルエントリの削除
#### 仕様
ルーティングテーブルエントリの削除を行うコマンドの仕様を以下に示す．
```
#入力
./bin/simple_router delete 宛先アドレス ネットマスク長
#出力
##削除に成功した場合
success delete entry
##削除したいエントリが見つからなかった場合
error: not found entry

#入力例
./bin/simple_router add 192.168.1.5 24
#出力例
success delete entry
```

#### 実装
ルーティングテーブルエントリの削除機能の実現にあたって，
SimpleRouterクラスにdelete_entry関数を，
RoutingTableクラスにdelete関数を実装した．

delete_entry関数のソースコードを以下に示す．
```ruby
34 def delete_entry(dest,mask)
35   entry = {destination: dest, netmask_length: mask.to_i}
36   @routing_table.delete(entry)
37 end
```
delete_entry関数は，simple_routerプロセスから呼び出される．
この関数では，simple_routerプロセスから渡される引数の情報(宛先アドレス，ネットマスク長，次の転送先アドレス)を
ハッシュ形式でまとめ(35行目)，RoutingTableクラスのインスタンスメソッドとして実装したdelete関数を呼び出している(36行目)．

次に，delete関数のソースコードを以下に示す．
```ruby
33 def delete(options)
34   netmask_length = options.fetch(:netmask_length)
35   prefix = IPv4Address.new(options.fetch(:destination)).mask(netmask_length)
36   entry = @db[netmask_length][prefix.to_i]
37   if entry then
38     @db[netmask_length].delete(prefix.to_i)
39     print("success delete entry\n")
40   else
41     print("error: not found entry")
42   end
43 end
```
delete関数では，@dbからエントリを削除する処理を行っている．
ネットマスク長，宛先アドレスを取得し，同じエントリが登録されているか調べる(34行目〜36行目)．
エントリが登録されていれば，エントリの削除を行い，削除が成功した旨を伝えるメッセージを
出力する(37〜39行目)．指定したエントリが存在しない場合は，エラーメッセージを表示する(41行目)．

### ルータのインタフェース一覧の表示
#### 仕様
ルーティングテーブルを表示するコマンドの仕様を以下に示す．
```
#入力
./bin/simple_router show_if
#出力
---------- show interfaces ----------
 port_number       mac_address      ip_address
  ポート番号         macアドレス       ipアドレス



#出力例
---------- show interfaces ----------
 port_number       mac_address      ip_address
           1 01:01:01:01:01:01  192.168.1.1/24
           2 02:02:02:02:02:02  192.168.2.1/24
```

#### 実装
ルーティングテーブルの表示機能の実現にあたって，SimpleRouterクラスにshow_interfaces関数を，
Interfaceクラスにshow_interfaces関数，show関数を実装した．

show_interfaces関数のソースコードを以下に示す．
```ruby
25 def show_interfaces()
26   Interface.show_interfaces
27 end
```
show_interfaces関数は，simple_routerプロセスから呼び出される．
この関数では，Interfacesクラスのクラスメソッドとして実装した
show_interfaces関数を呼び出している．

次に，show_interfaces関数のソースコードを以下に示す．
```ruby
30 def self.show_interfaces()
31   print("---------- show interfaces ----------\n")
32   print("port_number".center(12))
33   print("mac_address".center(18))
34   print("ip_address".center(16))
35   print("\n")
36   self.all.each do |interface|
37     interface.show()
38   end
39 end
```
show_interfaces関数では，クラス変数allから各インターフェースのインスタンスを
取得し，Interfaceクラスのインタンスメソッドとして実装したshow関数を呼び出し，
インターフェースの情報を表示する(36行目〜38行目)．

最後に，show関数のソースコードを以下に示す．
```ruby
63 def show
64   print("#{@port_number}".rjust(12))
65   print("#{@mac_address}".rjust(18))
66   print("#{@ip_address}/#{@netmask_length}".rjust(16))
67   print("\n")
68 end
```
インスタンスの情報は，各インターフェースのインスタンスのインスタンス変数に保存されている．
show関数では，インスタンス変数の中身を表示する処理を行っている．

### 動作確認
動作確認の際に使用した設定ファイルを以下に示す．
```
vswitch('0x1') { dpid 0x1 }
netns('host1') {
  ip '192.168.1.2'
  netmask '255.255.255.0'
  route net: '0.0.0.0', gateway: '192.168.1.1'
}
netns('host2') {
  ip '192.168.2.2'
  netmask '255.255.255.0'
  route net: '0.0.0.0', gateway: '192.168.2.1'
}
link '0x1', 'host1'
link '0x1', 'host2'
```
また，ルータの設定ファイルを以下に示す．
```
module Configuration
  INTERFACES = [
    {
      port: 1,
      mac_address: '01:01:01:01:01:01',
      ip_address: '192.168.1.1',
      netmask_length: 24
    },
    {
      port: 2,
      mac_address: '02:02:02:02:02:02',
      ip_address: '192.168.2.1',
      netmask_length: 24
    }
  ]

  ROUTES = [
    {
      destination: '0.0.0.0',
      netmask_length: 0,
      next_hop: '192.168.1.2'
    }
  ]
end
```

動作確認は以下の手順で行った．
1. show_rtコマンドでルーティングテーブルを表示する．
2. show_ifコマンドでインターフェースの一覧を表示する．
3. addコマンドでエントリの追加を行う．
4. addコマンドでエントリの更新を行う．
5. show_rtコマンドでルーティングテーブルを表示し，エントリが追加されているか確認を行う．
6. deleteコマンドでエントリの削除を行う．
7. show_rtコマンドでルーティングテーブルを表示し，エントリが削除されているか確認を行う．
8. deleteコマンドで，存在しないエントリを指定し，エラーメッセージが表示されるか確認を行う．

実行結果を以下に示す．
```
$ ./bin/simple_router show_rt #手順1
#出力
---------- show routing table ----------
     destination        next_hop
       0.0.0.0/0     192.168.1.2

$ ./bin/simple_router show_if #手順2
#出力
---------- show interfaces ----------
 port_number       mac_address      ip_address
           1 01:01:01:01:01:01  192.168.1.1/24
           2 02:02:02:02:02:02  192.168.2.1/24

$ ./bin/simple_router add 192.168.1.5 24 192.168.1.2 #手順3
#出力
success add entry

$ ./bin/simple_router add 192.168.1.5 24 192.168.1.3 #手順4
#出力
success update entry

$ ./bin/simple_router show_rt #手順5
#出力
---------- show routing table ----------
     destination        next_hop
       0.0.0.0/0     192.168.1.2

  192.168.1.0/24     192.168.1.3

$ ./bin/simple_router delete 192.168.1.5 24 #手順6
#出力
success delete entry

$ ./bin/simple_router show_rt #手順7
#出力
---------- show routing table ----------
     destination        next_hop
       0.0.0.0/0     192.168.1.2

$ ./bin/simple_router delete 192.168.1.5 24 #手順8
#出力
error: not found entry
```
手順1，2の結果から，ルーティングテーブルの表示機能，インターフェースの一覧表示機能を実現できたことが
確認できた．
エントリの追加機能については，手順5の結果において，エントリがルーティングテーブルに正しく追加されたことがわかり，
追加機能を実現できたことが確認できた．
また，削除機能については，手順7の結果において，エントリがルーティングテーブルから削除されたことがわかり，
削除機能を実現できたことが確認できた．