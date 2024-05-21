# FreeOTP 翻譯替換文件

## 檔案

- 替換文字程序：
replace_en_to_tw.py、replace_tw_to_en.py
- 翻譯檔：
freeotp-ios.pot、zh_TW.po

## 使用方式

- 將英文替換成繁體中文
```
python replace_en_to_tw.py
```
程式會讀取「zh_TW.po」的"msgid"與"msgstr"，並替換對應檔案中的文本，

每次都會產生一個「zh_TW.po.bak」，建議.bak要上git保存，方便之後要替換回來。

- 將繁體中文替換成英文
```
python replace_tw_to_en.py
```
要執行這個檔案，請先確保有「zh_TW.po.bak」檔案，而且要是上次保存的檔案，

如果先執行「replace_en_to_tw.py」會覆蓋掉原本的.bak檔案，就需要用git先退回變更了。

## 建議流程

如果是第一次替換，則直接執行「replace_en_to_tw.py」即可。


如果是第二次之後的替換，則建議先執行「replace_tw_to_en.py」還原成英文，

然後再執行「replace_en_to_tw.py」將新翻譯替換上去。
