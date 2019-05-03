# 内核配置裁剪及启动流程

## 1 配置过程

方法：

- make menuconfig：使用默认的配置，从头到尾直接配置
- 使用默认的配置，在arch/arm/configs目录下，找到相似的配置文件，然后执行

```
make xxx_config
make menu_config // 会出现一个菜单，然后就可以通过这个菜单来设置配置项
```

- 使用厂家的配置文件

```
make xxx_config  // 厂家的配置文件
make menu_config // 会出现一个菜单，然后就可以通过这个菜单来设置配置项
```

所有的配置文件都会生成一个`.config`文件，后面会对这个文件进行分析。

## 2 编译

直接使用make就可以，如果想生成UImage(头部真正的内核)，如果想编译内核给u-boot用，那么直接编译UImage即可。

命令：

```
make uImage
```

## 3 config分析

使用DM9000来进行举例。

对于config_dm9000的来源：

- C语言:config_dm9000(宏)
- Makefile：drivers/net/makefile
- include/config/auto.config
- include/linux/autoconf.h

分析：config_dm9000的宏来源于include/linux/autoconf.h，autoconf.h是自动生成的

在使用命令`make uImage`编译内核的时候，`.config`会自动创建`autoconf.h`，并且生成`auto.config`。`autoconf.h`是被源代码调用的，`auto.config`是被顶层Makefile包含的

## 4 分析Makefile

在分析uboot的时候，从Makefile中已经得到的信息为：第一个启动文件、链接脚本（这个内核应该放在那里，里面的东西是怎么排布的）。

Linux中Makefile的分类：

![1556898356853](images/linux_makefile.png)

> 子目录Makefile分析
>
> **应用：**子目录下的Makefile：如果有a.c和b.c要想编内核或者制作成一个模块，在Linux中应该怎么做?
>
> 1.编译进内核：obj-y+ = a.o b.o
>
> 2.如果要组合成一个模块：obj-m+=ab.o
>
> ​					 ab-objs :=a.o b.o
>
> 当我们编译的时候，a.c和b.c分别生成a.o和b.o,这两个文件会被编译成ab.ko这样一个模块。

### 4.1 顶层Makefile：

> 在我们使用`make uImage`的时候，这个目标在顶层Makefile是没有的，它在`arch/arm/Makefile`里面，所以这个`Makefile`会被包含到顶层`Makefile`中，所以顶层`Makefile`会使用`include`把该`Makefile`包含进来。

在使用make uImage的时候，依赖关系：

- uImage依赖于vmlinux
- vmlinux依赖于...

对于依赖关系的分析，从上往下，一个一个的替换掉，就可以知道这些依赖的关系。

对于Makefile里面的依赖台庞大，可以通过编译生成的日志来分析。

通过对编译生成的日志，我们可以得到内核的**第一个文件和链接脚本**：

- 第一个文件：arch/arm/kernel/head.S
- 链接脚本：arch/arm/kernel/vmlinux.lds

> 链接的顺序，与编译生成的.o文件的顺序是一致的。
>
> 而代码段、数据段等存放的位置由链接脚本决定。



