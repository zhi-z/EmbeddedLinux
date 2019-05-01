# 7 NOR Flash

## 1 使用UBOOT操作

在操作UBOOT之前，先把uboot程序下载到nor flash上，对于nor flash这部分的区域不要进行擦除和写入操作。

使用UBOOT体验NOR FLASH的操作(开发板设为NOR启动，进入UBOOT)
先使用OpenJTAG烧写UBOOT到NOR FLASH

### 1.2 读数据

读数据:

```
md.b 0 
```

读ID:

```
NOR手册上:
往地址555H写AAH
往地址2AAH写55H
往地址555H写90H
读0地址得到厂家ID: C2H
读1地址得到设备ID: 22DAH或225BH
退出读ID状态: 给任意地址写F0H
```

**注意：** 2440的A1接到NOR的A0，所以2440发出(555h<<1), NOR才能收到555h这个地址
UBOOT怎么操作？

```
往地址AAAH写AAH                      mw.w aaa aa
往地址554写55H                       mw.w 554 55
往地址AAAH写90H                      mw.w aaa 90
读0地址得到厂家ID: C2H               md.w 0 1
读2地址得到设备ID: 22DAH或225BH      md.w 2 1
退出读ID状态:                        mw.w 0 f0
```

### 1.2 NOR规范

NOR有两种规范, jedec, cfi(common flash interface)

#### 1.2.1 读取CFI信息

读取CFL信息测试

```
NOR手册：   
进入CFI模式    往55H写入98H
读数据:        读10H得到0051
               读11H得到0052
               读12H得到0059
               读27H得到容量
```

#### 1.2.2 写数据

例如：在地址0x100000写入0x1234

```
md.w 100000 1     // 得到ffff
mw.w 100000 1234
md.w 100000 1     // 还是ffff
```

总结：直接往nor flash上写数据是不可行的，需要先进行擦除。

擦除：

```
NOR手册：
往地址555H写AAH 
往地址2AAH写55H 
往地址555H写A0H 
往地址PA写PD
```

**注意：**2440的A1接到NOR的A0，所以2440发出(555h<<1), NOR才能收到555h这个地址
UBOOT怎么操作？

测试过程：

```
往地址AAAH写AAH               mw.w aaa aa
往地址554H写55H               mw.w 554 55
往地址AAAH写A0H               mw.w aaa a0
往地址0x100000写1234h         mw.w 100000 1234
```

再次往0x100000写入0x5678

```
因为原来0x100000上的数据不是0xffff，再次烧写失败
往地址AAAH写AAH               
往地址554H写55H               
往地址AAAH写A0H               
往地址0x100000写5678h         mw.w 100000 5678
```

擦除：

```
mw.w aaa aa
mw.w 554 55
mw.w aaa 80

mw.w aaa aa
mw.w 554 55
mw.w 100000 30
```

再烧写：

```
mw.w aaa aa
mw.w 554 55
mw.w aaa a0
mw.w 100000 5678
```

## 2 NOR Flash编程

 测试的主要内容为：扫描nor flash，输出nor flash的块地址，id等，进行读写和擦除。

> 注意事项：
>
> 1.编译程序时加上: -march=armv4，否则在进行写数据的时候回出错，例如
>    volatile unsigned short *p = xxx;
>    *p = val; // 会被拆分成2个strb操作
>
> 要一次性写入16位的数据，它分成一次写入8位，分两次写入。
>
> 2.测试nor时进入CFI等模式时, 如果发生了中断，cpu必定读NOR，
>    那么读不到正确的指令，导致程序崩溃



