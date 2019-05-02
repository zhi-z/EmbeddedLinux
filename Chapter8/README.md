# 8 Nand Flash

## 1 基础问答

```
问1. 原理图上NAND FLASH和S3C2440之间只有数据线，
     怎么传输地址？
答1．在DATA0～DATA7上既传输数据，又传输地址
     当ALE为高电平时传输的是地址，
```

```
问2. 从NAND FLASH芯片手册可知，要操作NAND FLASH需要先发出命令
     怎么传入命令？
答2．在DATA0～DATA7上既传输数据，又传输地址，也传输命令
     当ALE为高电平时传输的是地址，
     当CLE为高电平时传输的是命令
     当ALE和CLE都为低电平时传输的是数据
```

```
问3. 数据线既接到NAND FLASH，也接到NOR FLASH，还接到SDRAM、DM9000等等
     那么怎么避免干扰？
答3. 这些设备，要访问之必须"选中"，
     没有选中的芯片不会工作，相当于没接一样
```

```
问4. 假设烧写NAND FLASH，把命令、地址、数据发给它之后，
     NAND FLASH肯定不可能瞬间完成烧写的，
     怎么判断烧写完成？
答4. 通过状态引脚RnB来判断：它为高电平表示就绪，它为低电平表示正忙
```

```
问5. 怎么操作NAND FLASH呢？
答5. 根据NAND FLASH的芯片手册，一般的过程是：
     发出命令
     发出地址
     发出数据/读数据
```

## 2 nand flash操作过程

```
          NAND FLASH                      S3C2440
发命令    选中芯片                   
          CLE设为高电平                   NFCMMD=命令值     
          在DATA0~DATA7上输出命令值
          发出一个写脉冲
            
发地址    选中芯片                        NFADDR=地址值
          ALE设为高电平
          在DATA0~DATA7上输出地址值
          发出一个写脉冲

发数据    选中芯片                        NFDATA=数据值
          ALE,CLE设为低电平
          在DATA0~DATA7上输出数据值
          发出一个写脉冲

读数据    选中芯片                        val=NFDATA
          发出读脉冲
          读DATA0~DATA7的数据
```

## 3 用UBOOT来操作NAND FLASH

- 读ID

```
                               S3C2440                 u-boot 
选中                           NFCONT的bit1设为0   md.l 0x4E000004 1; mw.l 0x4E000004  1
发出命令0x90                   NFCMMD=0x90         mw.b 0x4E000008 0x90 
发出地址0x00                   NFADDR=0x00         mw.b 0x4E00000C 0x00
读数据得到0xEC                 val=NFDATA          md.b 0x4E000010 1
读数据得到device code          val=NFDATA          md.b 0x4E000010 1
          0xda
退出读ID的状态                 NFCMMD=0xff         mw.b 0x4E000008 0xff
```

- 读内容: 读0地址的数据

```
使用UBOOT命令:
nand dump 0
Page 00000000 dump:
        17 00 00 ea 14 f0 9f e5  14 f0 9f e5 14 f0 9f e5
```

```
                               S3C2440                 u-boot 
选中                           NFCONT的bit1设为0   md.l 0x4E000004 1; mw.l 0x4E000004  1
发出命令0x00                   NFCMMD=0x00         mw.b 0x4E000008 0x00 
发出地址0x00                   NFADDR=0x00         mw.b 0x4E00000C 0x00
发出地址0x00                   NFADDR=0x00         mw.b 0x4E00000C 0x00
发出地址0x00                   NFADDR=0x00         mw.b 0x4E00000C 0x00
发出地址0x00                   NFADDR=0x00         mw.b 0x4E00000C 0x00
发出地址0x00                   NFADDR=0x00         mw.b 0x4E00000C 0x00
发出命令0x30                   NFCMMD=0x30         mw.b 0x4E000008 0x30 
读数据得到0x17                 val=NFDATA          md.b 0x4E000010 1
读数据得到0x00                 val=NFDATA          md.b 0x4E000010 1
读数据得到0x00                 val=NFDATA          md.b 0x4E000010 1
读数据得到0xea                 val=NFDATA          md.b 0x4E000010 1
退出读状态                     NFCMMD=0xff         mw.b 0x4E000008 0xff
```

## 4 地址问题

```
CPU大爷: 小nand啊，你的性能比不上小nor啊，听说你有位反转的毛病
Nand   : 是的，大爷，位反转是我天生的毛病，时有时无
CPU大爷: 靠，你说你价格便宜容量大，这不是害我嘛
Nand   : 没事，我有偏方，用OOB就可以解决这问题
CPU大爷: 得得得，你那偏方是什么也别告诉我，我只管能读写正确的数据
Nand   : 是的，大爷，我这OOB偏方也就我自个私下使用。
         您就像使用nor一样使唤我就可以了
```

