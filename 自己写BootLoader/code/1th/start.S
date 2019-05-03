
#define S3C2440_MPLL_200MHZ     ((0x5c<<12)|(0x01<<4)|(0x02))
#define MEM_CTL_BASE    0x48000000

.text
.global _start
_start:

/* 1. 关看门狗 */
	ldr r0, =0x53000000    // 这个是一条为伪汇编指令，使r0指向地址0x53000000
	mov r1, #0			   // r1 = 0，如果只比较简单可以直接使用mov指令
	str r1, [r0]           // 把r1上的值，存到r0所指地址

/* 2. 设置时钟 */
	ldr r0, =0x4c000014		// r0指向地址0x4c000014
	mov r1, #0x03;            // FCLK:HCLK:PCLK=1:2:4, HDIVN=1,PDIVN=1,r1 = 0x03
	str r1, [r0]     		// 把r1的值存到r0所指向的地址

	/* 如果HDIVN非0，CPU的总线模式应该从“fast bus mode”变为“asynchronous bus mode” */
	mrc	p15, 0, r1, c1, c0, 0		/* 读出控制寄存器 */ 
	orr	r1, r1, #0xc0000000			/* 设置为“asynchronous bus mode” */
	mcr	p15, 0, r1, c1, c0, 0		/* 写入控制寄存器 */

	/* MPLLCON = S3C2440_MPLL_200MHZ */
	ldr r0, =0x4c000004          // r0 指向地址0x4c000004
	ldr r1, =S3C2440_MPLL_200MHZ
	str r1, [r0]                 // 把r1这个值存放到r0所指的位置

/* 3. 初始化SDRAM */
	ldr r0, =MEM_CTL_BASE		// 使r0指向基地址
	adr r1, sdram_config     /* sdram_config的当前地址 */
	add r3, r0, #(13*4)			// 为了循环做判断，使r3= r0 + 13*4
1:
	ldr r2, [r1], #4		// 从r1的地方读到一个值。保存到r2,并且让r1+4
	str r2, [r0], #4     	// 把r2的值存到r0所指的地址，然后让r0+4
	cmp r0, r3              // 判断r0是否读完
	bne 1b					// 如果不行等的话，跳回前面的1标号，b表示后面

/* 4. 重定位 : 把bootloader本身的代码从flash复制到它的链接地址去 */
	ldr sp, =0x34000000		// 要使用C语言之前要先设置栈，把它指定到一块没有使用的内存即可

	bl nand_init		// 初始化nand

	mov r0, #0	// 第一个参数，nor或者nand的0地址的代码复制到连接地址里面，所以第一个参数是0
	ldr r1, =_start	// 第二个参数，目的=链接地址
	ldr r2, =__bss_start	// 第三个参数，长度，需要看连接脚本，__bss_start为结束地址，不包含bss段
	sub r2, r2, r1		// r2 = r2 -r1,长度
	
	bl copy_code_to_sdram
	bl clear_bss		// 给bss段清0
	
/* 5. 执行main */
	ldr lr, =halt		// 设置返回地址，lr寄存器是保存函数返回地址的
	ldr pc, =main		// 跳转到main函数执行，也可以使用bl main，但是这个
						// 指令是相对的跳转,如果是使用ldr pc,=main的话，它
						// 就会跳转到SDRAM中取执行，
	// 假设main函数有返回的话，就会在这里死循环，以防程序乱跑		
halt:
	b halt

sdram_config:
	.long 0x22011110	 //BWSCON
	.long 0x00000700	 //BANKCON0
	.long 0x00000700	 //BANKCON1
	.long 0x00000700	 //BANKCON2
	.long 0x00000700	 //BANKCON3  
	.long 0x00000700	 //BANKCON4
	.long 0x00000700	 //BANKCON5
	.long 0x00018005	 //BANKCON6
	.long 0x00018005	 //BANKCON7
	.long 0x008C04F4	 // REFRESH
	.long 0x000000B1	 //BANKSIZE
	.long 0x00000030	 //MRSRB6
	.long 0x00000030	 //MRSRB7

