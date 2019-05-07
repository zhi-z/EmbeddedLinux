# 根文件系统

- u-boot:启动内核
- 内核：启动应用程序

应用程序位于根文件系统。本篇主要是如何构建文件系统。

> 挂接根文件系统后，执行应用程序在int_post这个函数。

## 1 内核怎么样启动第一个应用程序

- open(dev/console),打开设备，打印是从这个应用输出的
- sys_dup(0)，sys_dup(0)，这两个是也是指open(dev/console)

他会执行如下应用程序，如果有一个应用程序执行了，那么其他的应用程序就不会执行，如图所示：

![1557233873324](C:\Users\RD007\AppData\Roaming\Typora\typora-user-images\1557233873324.png)

