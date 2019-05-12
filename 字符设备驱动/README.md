# 字符设备驱动

- uboot的任务：启动内核
- 内核：启动应用程序（应用包括点灯，按键操作等等）
- 应用程序：直接使用open，read，write类进行操作；

## 1 linux框架

![1556957605428](images/linux_struct.png)

应用程序（APP）里面直接通过open，read，write这种标准的接口来操作。但是驱动程序要有对应的操作。在应用接口与驱动程序是通过驱动框架来对应起来的。

## 2 LED驱动程序

目的是让应用程序与驱动程序对应起来。然后通过APP的标准接口就可以实现操作。具体过程如下：

### 2.1 写驱动程序

以led程序来举例。

- 写出驱动程序led_open,led_read,led_write。

- 写出来后如何告诉内核

- 然后内核告诉应用程序。

  - 定义一个file_oprations结构体，然后进行填充

  ![1556958632873](images/add_app_drive.png)

  - 把这个结构告诉内核，通过注册的方式register_chrdev

  ![1556958933483](images/register_chrdev.png)

  - 驱动的入口函数调用register_chrdev，如果是第一个个程序，那么驱动的入口函数可以这样写：

  ![1556959113678](images/drive_first.png)

  这里的major是主设备号

  - 如何告诉内核它的入口函数是这个，需要进行修饰

  ```
  // module_init实现的是定义一个结构体，这个结构体里面有一个函数指针，指向first_drv_init，当我们去安装一个驱动程序的时候，内核就会自动找到这个结构体，然后调用里面的函数
  module_init(first_drv_init)
  ```

  - 最终应用程序如何找到我们注册的驱动程序以及file_oprations中的操作方法：通过设备类型（字符设备）和主设备号，就可以找到我们注册进去file_oprations，这个file_oprations是放在一个数组当中，内核可以通过查找的方式找到。

  驱动程序和应用程序是如何挂钩起来的：

  ![1556961531993](images/drv_app.png)

  - 卸载驱动程序：

![1556961705762](images/uninstall_drv.png)

```
modules_exit(first_drv_exit);
```

### 2.2 驱动程序的编译

首先编译好内核，然后写一个驱动的Makefile，

![1556962634109](images/drv_makefile.png)

第一行表示编译好的单板内核目录。

编译，使用`make`命令，最后生成`first_drv.ko`文件。当使用的时候，把它下载到内存。

### 2.3 查看目前内核支持的设备

通过命令查看目前内核支持的。

![1557417886610](images/cat_dev.png)

第一列是主设备号，对应于chrdev数组里面的下标。

### 2.4 加载驱动

![1557418211485](images/load_dri.png)

通过insmod命令来加载驱动程序。

### 2.5 驱动程序测试

加载完驱动后，写一个测试函数来测试驱动程序是否完成。例如：

![1557418475151](images/test_app.png)

编译测试程序，编译命令如下：

![1557418573202](images/compile_test_app.png)

拷贝到我们制作的跟文件目录下：

![1557418686355](images/copy_test_app_to_root.png)

执行测试程序：

![1557418778675](images/run_test_app.png)

这里显示没有这个设备，不存在这个文件，所以需要创建这个设备节点。

> ## 主设备号与次设备号
>
> 主设备号的作用是帮我们找到哪一个驱动程序，次设备号是给我们设备程序用的，我们想用来做什么就做什么。

## 3 按键驱动之查询方式

使用 查询的方式。步骤如下：

### 3.1 写出框架

- 写file_operation结构体，里面有open、read、write成员，用到哪一个就实现哪一个；

  ```
  static struct file_operations sencod_drv_fops = {
      .owner  =   THIS_MODULE,    /* 这是一个宏，推向编译模块时自动创建的__this_module变量 */
      .open   =   second_drv_open,     
  	.read	=	second_drv_read,	   
  };
  ```

  接着写这个结构体里面的函数：

  ```
  static int second_drv_open(struct inode *inode, struct file *file)
  {
  	return 0;
  }
  
  ssize_t second_drv_read(struct file *file, char __user *buf, size_t size, loff_t *ppos)
  {
  
  }
  ```

- 这个file_operation结构体要在入口函数里面注册到内核里面去；

  ```
  static int second_drv_init(void)
  {
  	// 主设备号写入0，让系统自动给我们分配主设备号
  	major = register_chrdev(0, "second_drv", &sencod_drv_fops); 
  	return 0;
  }
  ```

- 写出口函数，作用是通过这个函数把设备卸载

  ```
  static void second_drv_exit(void)
  {
  	unregister_chrdev(major, "second_drv");
  
  	return 0;
  }
  ```

- 修饰入口函数和出口函数

  ```
  module_init(second_drv_init);
  
  module_exit(second_drv_exit);
  ```

到这里已经搭好了基本的驱动程序框架，如果需要更加完善的话，给sysfs提供更多的信息，这些信息是udev，它可以自动创建设备节点。

- 给sysfs提供更多的信息，进一步完善驱动框架

  - 创建一个class
  - 在class下面创建一个设备

  具体实现，先定义两个结构体：

  ```
  static struct class *seconddrv_class;
  static struct class_device	*seconddrv_class_dev;
  ```

  在入口函数里面创建一个类，并在类下面创建一个设备：

  ```
  int major;
  static int second_drv_init(void)
  {
  	major = register_chrdev(0, "second_drv", &sencod_drv_fops);
  
  	seconddrv_class = class_create(THIS_MODULE, "second_drv");
  	seconddrv_class_dev = class_device_create(seconddrv_class, NULL, MKDEV(major, 0), NULL, "buttons"); /* /dev/buttons */
  
  
  	return 0;
  }
  ```

  在出口也要卸载掉：

  ```
  static void second_drv_exit(void)
  {
  	unregister_chrdev(major, "second_drv");
  	class_device_unregister(seconddrv_class_dev);
  	class_destroy(seconddrv_class);
  	return 0;
  }
  ```

- 修改Makefile

```
KERN_DIR = /work/system/linux-2.6.22.6

all:
	make -C $(KERN_DIR) M=`pwd` modules 

clean:
	make -C $(KERN_DIR) M=`pwd` modules clean
	rm -rf modules.order

obj-m	+= second_drv.o

```

到这里一个驱动程序的框架就写完了，接着就可以进行编译，复制到根文件系统。

- 加载

![1557502142066](assets/1557502142066.png)

通过命令查看：button设备已经生成

![1557502206933](assets/1557502206933.png)

### 3.2 硬件的操作 

- 看原理图，确定引脚
- 看2440手册，操作寄存
- 写代码

首先在open里面配置引脚，在read里面返回引脚状态，在入口函数进行地址映射

这三个步骤与写单片机的程序是一样的。

1）在入口函数建立地址映射

```
static int second_drv_init(void)
{
	major = register_chrdev(0, "second_drv", &sencod_drv_fops);

	seconddrv_class = class_create(THIS_MODULE, "second_drv");

	seconddrv_class_dev = class_device_create(seconddrv_class, NULL, MKDEV(major, 0), NULL, "buttons"); /* /dev/buttons */

// 建立地址映射
	gpfcon = (volatile unsigned long *)ioremap(0x56000050, 16);
	gpfdat = gpfcon + 1;

	gpgcon = (volatile unsigned long *)ioremap(0x56000060, 16);
	gpgdat = gpgcon + 1;

	return 0;
}
```

2）在出口解除这些映射关系：

```
static void second_drv_exit(void)
{
	unregister_chrdev(major, "second_drv");
	class_device_unregister(seconddrv_class_dev);
	class_destroy(seconddrv_class);
	// 解除代码映射
	iounmap(gpfcon);
	iounmap(gpgcon);
	return 0;
}
```

3）在open里面配置引脚

```
static int second_drv_open(struct inode *inode, struct file *file)
{
	/* 配置GPF0,2为输入引脚 ，直接清零*/
	*gpfcon &= ~((0x3<<(0*2)) | (0x3<<(2*2)));

	/* 配置GPG3,11为输入引脚 */
	*gpgcon &= ~((0x3<<(3*2)) | (0x3<<(11*2)));

	return 0;
}
```

4）读取引脚电平

```
ssize_t second_drv_read(struct file *file, char __user *buf, size_t size, loff_t *ppos)
{
	/* 返回4个引脚的电平 */
	unsigned char key_vals[4];
	int regval;

	if (size != sizeof(key_vals))
		return -EINVAL;

	/* 读GPF0,2 */
	regval = *gpfdat;
	key_vals[0] = (regval & (1<<0)) ? 1 : 0;
	key_vals[1] = (regval & (1<<2)) ? 1 : 0;
	

	/* 读GPG3,11 */
	regval = *gpgdat;
	key_vals[2] = (regval & (1<<3)) ? 1 : 0;
	key_vals[3] = (regval & (1<<11)) ? 1 : 0;
	// 使用这个函数把数据返回给用户
	copy_to_user(buf, key_vals, sizeof(key_vals));
	
	return sizeof(key_vals);
}
```

带这里就写完了驱动程序，使用make进行编译。

5）写测试程序

```

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>

/* seconddrvtest 
  */
int main(int argc, char **argv)
{
	int fd;
	unsigned char key_vals[4];
	int cnt = 0;
	
	fd = open("/dev/buttons", O_RDWR);
	if (fd < 0)
	{
		printf("can't open!\n");
	}

	while (1)
	{
		read(fd, key_vals, sizeof(key_vals));
		if (!key_vals[0] || !key_vals[1] || !key_vals[2] || !key_vals[3])
		{
			printf("%04d key pressed: %d %d %d %d\n", cnt++, key_vals[0], key_vals[1], key_vals[2], key_vals[3]);
		}
	}
	
	return 0;
}
```

编译测试程序：

![1557584669095](assets/1557584669095.png)

复制到根文件系统：

![1557584716804](assets/1557584716804.png)

6）卸载旧的驱动，挂载新的驱动

![1557584789888](assets/1557584789888.png)

7）执行

![1557584848898](assets/1557584848898.png)



**物理地址与虚拟地址：**虚拟地址等于ioremap(物理地址，长度)

## 4 linux中断

使用查询方式会很耗CPU的资源，因为不知道什么时候会按下，CPU会一直查询。所以使用中断的方式。

### 4.1 linux中断异常结构

![1557586252211](assets/1557586252211.png)

1）单片机中断与linux中断的区别

在单片机中对于中断的发生，都要判断是哪一个发生的，然后再调用相应的函数，但是在linux中，所有的中断都会调用asm_do_irq函数。

![1557586419679](assets/1557586419679.png)

### 4.2 linux中断体系架构

![1557588176395](assets/1557588176395.png)

### 4.2 注册

- request_irq（注册中断）：如果要注册中断程序的话使用request_irq，会传入中断号、处理函数、flags（上升沿或者下降沿等）、名字、dev_id这些参数，然后会分配一个IRQ action结构，接着把这个结构放进irq_desc这个数组中的action链表中，然后使能设置引脚，使能中断。
- free_irq(irq,dev_id):
  - 把注册到链表的结果拖出来，然后禁止中断

## 5 按键驱动之中断方式

首先要写出框架，然后对硬件进行操作，实现的代码如下：

file_operations结构：

```
static struct file_operations sencod_drv_fops = {
    .owner   =  THIS_MODULE,    /* 这是一个宏，推向编译模块时自动创建的__this_module变量 */
    .open    =  third_drv_open,     
	.read	 =	third_drv_read,	   
	.release =  third_drv_close,	   
};
```

open：

```
static int third_drv_open(struct inode *inode, struct file *file)
{
	/* 配置GPF0,2为输入引脚 */
	/* 配置GPG3,11为输入引脚 */
	request_irq(IRQ_EINT0,  buttons_irq, IRQT_BOTHEDGE, "S2", &pins_desc[0]);
	request_irq(IRQ_EINT2,  buttons_irq, IRQT_BOTHEDGE, "S3", &pins_desc[1]);
	request_irq(IRQ_EINT11, buttons_irq, IRQT_BOTHEDGE, "S4", &pins_desc[2]);
	request_irq(IRQ_EINT19, buttons_irq, IRQT_BOTHEDGE, "S5", &pins_desc[3]);	

	return 0;
}
```

释放中断：

```
int third_drv_close(struct inode *inode, struct file *file)
{
	free_irq(IRQ_EINT0, &pins_desc[0]);
	free_irq(IRQ_EINT2, &pins_desc[1]);
	free_irq(IRQ_EINT11, &pins_desc[2]);
	free_irq(IRQ_EINT19, &pins_desc[3]);
	return 0;
}
```

写中断处理函数：

```
/* 中断事件标志, 中断服务程序将它置1，third_drv_read将它清0 */
static volatile int ev_press = 0;


struct pin_desc{
	unsigned int pin;
	unsigned int key_val;
};


/* 键值: 按下时, 0x01, 0x02, 0x03, 0x04 */
/* 键值: 松开时, 0x81, 0x82, 0x83, 0x84 */
static unsigned char key_val;

struct pin_desc pins_desc[4] = {
	{S3C2410_GPF0, 0x01},
	{S3C2410_GPF2, 0x02},
	{S3C2410_GPG3, 0x03},
	{S3C2410_GPG11, 0x04},
};


/*
  * 确定按键值
  */
static irqreturn_t buttons_irq(int irq, void *dev_id)
{
	struct pin_desc * pindesc = (struct pin_desc *)dev_id;
	unsigned int pinval;
	
	pinval = s3c2410_gpio_getpin(pindesc->pin);

	if (pinval)
	{
		/* 松开 */
		key_val = 0x80 | pindesc->key_val;
	}
	else
	{
		/* 按下 */
		key_val = pindesc->key_val;
	}

    ev_press = 1;                  /* 表示中断发生了 */
    wake_up_interruptible(&button_waitq);   /* 唤醒休眠的进程 */

	
	return IRQ_RETVAL(IRQ_HANDLED);
}
```

读操作：这里设置了休眠，如果没有按键按下的话，就进入休眠，这样能够降低CPU的使用率

```
ssize_t third_drv_read(struct file *file, char __user *buf, size_t size, loff_t *ppos)
{
	if (size != 1)
		return -EINVAL;

	/* 如果没有按键动作, 休眠 */
	wait_event_interruptible(button_waitq, ev_press);

	/* 如果有按键动作, 返回键值 */
	copy_to_user(buf, &key_val, 1);
	ev_press = 0;
	
	return 1;
}

```

写测试程序：

```

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>

/* thirddrvtest 
  */
int main(int argc, char **argv)
{
	int fd;
	unsigned char key_val;
	
	fd = open("/dev/buttons", O_RDWR);
	if (fd < 0)
	{
		printf("can't open!\n");
	}

	while (1)
	{
		//read(fd, &key_val, 1);
		//printf("key_val = 0x%x\n", key_val);
		sleep(5);
	}
	
	return 0;
}
```

编译，并复制到根目录下：

![1557595388234](assets/1557595388234.png)

装载驱动程序：

![1557595446486](assets/1557595446486.png)

运行驱动程序：

![1557595538574](assets/1557595538574.png)

查看驱动状态：

![1557595571968](assets/1557595571968.png)

查看开启的中断：

![1557595609495](assets/1557595609495.png)

最后运行测试程序。

## 6 poll机制之按键驱动程序

一定的时间内进行查询。

在一定时间内如果不做任何操作也要返回数据。例如，对于按键操作，当有按键触发的时候，有数据返回，但如果想在一定的时间内，不按下也有数据返回，那么使用poll机制，然后就可以在一定的时间内进行查询。

[代码实现](forth_drv/forth_drv.c).

**三种按键驱动方式的对比：**

- 查询：耗资源
- 中断：read会一直等待
- poll：指定的时间进行查询，若干没有按下按键也会返回超时消息。

## 7 异步通知

以上的方法都是应用程序去读取按键值，而异步通知是反过来的。比如按键驱动程序，当有按下后驱动程序才去提醒应用程序，然后应用程序才去读取键值，这个叫异步通知。这个是使用信号机制实现的。

### 7.1 信号处理函数使用

信号机制使用应用程序，代码实现如下：这里只是简单的测试。

![1557649668392](assets/1557649668392.png)

编译后复制到根文件系统，然后执行，测试命令：

![1557649750778](assets/1557649750778.png)

当收到信号的时候就会调用信号函数。

### 7.2 信号处理函数要点

![1557649847666](assets/1557649847666.png)

### 7.3 驱动程序编写

目标：按下按键时候，驱动程序通知应用程序。

- 应用程序要注册信号函数
- 谁发，驱动程序法；
- 发给应用程序，应用程序要告诉驱动pid
- 怎么发？使用kill_fasync，比如按键程序在中断中调用这个函数

```
为了使设备支持异步通知机制，驱动程序中涉及以下3项工作：
1. 支持F_SETOWN命令，能在这个控制命令处理中设置filp->f_owner为对应进程ID。
   不过此项工作已由内核完成，设备驱动无须处理。
2. 支持F_SETFL命令的处理，每当FASYNC标志改变时，驱动程序中的fasync()函数将得以执行。
   驱动中应该实现fasync()函数。
   
3. 在设备资源可获得时，调用kill_fasync()函数激发相应的信号


应用程序：
fcntl(fd, F_SETOWN, getpid());  // 告诉内核，发给谁

Oflags = fcntl(fd, F_GETFL);   
fcntl(fd, F_SETFL, Oflags | FASYNC);  // 改变fasync标记，最终会调用到驱动的faync > fasync_helper：初始化/释放fasync_struct

```

代码实现：[fifth_drv](fifth_drv/fifth_drv.c)

## 8 同步、互斥、阻塞 

### 8.1 基础

```
1. 原子操作
原子操作指的是在执行过程中不会被别的代码路径所中断的操作。
常用原子操作函数举例：
atomic_t v = ATOMIC_INIT(0);     //定义原子变量v并初始化为0
atomic_read(atomic_t *v);        //返回原子变量的值
void atomic_inc(atomic_t *v);    //原子变量增加1
void atomic_dec(atomic_t *v);    //原子变量减少1
int atomic_dec_and_test(atomic_t *v); //自减操作后测试其是否为0，为0则返回true，否则返回false。

2. 信号量
信号量（semaphore）是用于保护临界区的一种常用方法，只有得到信号量的进程才能执行临界区代码。
当获取不到信号量时，进程进入休眠等待状态。

定义信号量
struct semaphore sem;
初始化信号量
void sema_init (struct semaphore *sem, int val);
void init_MUTEX(struct semaphore *sem);//初始化为0

static DECLARE_MUTEX(button_lock);     //定义互斥锁

获得信号量
void down(struct semaphore * sem);
int down_interruptible(struct semaphore * sem); 
int down_trylock(struct semaphore * sem);
释放信号量
void up(struct semaphore * sem);

3. 阻塞
阻塞操作    
是指在执行设备操作时若不能获得资源则挂起进程，直到满足可操作的条件后再进行操作。
被挂起的进程进入休眠状态，被从调度器的运行队列移走，直到等待的条件被满足。

非阻塞操作  
进程在不能进行设备操作时并不挂起，它或者放弃，或者不停地查询，直至可以进行操作为止。

fd = open("...", O_RDWR | O_NONBLOCK); 

```

### 8.2 代码实现 

1. 原子操作：[sixth_drv](sixth_drv/sixth_drv.c)，同一时刻只能有一个应用程序操作；
2. 信号量：
3. 阻塞和非阻塞：

