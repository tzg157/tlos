.code16
.section .text
.globl _start
_start:
	cli
	xorw %ax, %ax			# setup stack and segments
	movw %ax, %ds
	movw %ax, %es
	movw %ax, %ss
	movw $0x7c00, %sp
	sti

    movw %cs, %ax
    movw %ax, %ds
    movw %ax, %es
	
	movb	$0x86,	%ah   #延时
	movw	$0x001e,	%cx
	movw	$0x8480,	%dx
	int	$0x15
	
	movb $0x0, %bh
	movw $0x0, %dx
	call set_currsor
	call clean_screen
	
	call set_bgcolor

    call print
	
	
	
	jmp  enable_a20.1		# 使能a20
	

	

### 实模式下，基于BIOS中断在屏幕显示字符
set_bgcolor:
	movw $0x07d0, %cx	# 打印次数
	movb $00,	%bh		# 页码，从0打印
	movb $0x3f,	%bl		# 颜色 高四位前景色，低四位背景色
	movb $0x20,	%al		# 打印的字符。ascii码 0x20 空格
	movb $0x09, %ah
	int	$0x10
	ret
	
set_currsor:
	movb $0x02,  %ah
	int $0x10
	ret

print:
    movw $msg, %ax
    movw %ax, %bp
    movw $0xc, %cx
    #movw $0x1301, %ax
	
	#movw $0xc, %bx
	movb $0x0, %bh
	movb $0x3a, %bl
	movb $0x0a, %dh	# 行
    movb $0x23, %dl	# 列
	
	movb $0x1, %al	# 写模式开关
	
	movb $0x13, %ah
    int $0x10
    ret

clean_screen:               
    movb    $0x06,  %ah     #  
    movb    $0,     %al     # 
    movb    $0,     %ch     # 
    movb    $0,     %cl     #    
    movb    $24,    %dh     # 
    movb    $79,    %dl     # 
    movb    $0x07,  %bh     #  
    int     $0x10  
    ret 


### 通过键盘控制器的0x64及0x60端口使能 实模式到保护模式的转换
### 还能通过南桥0x92端口判断
enable_a20:

	inb	$0x92, %al		## 进入南桥芯片
	orb	$0x2, %al			## 打开南桥芯片的第2位(A20控制位)
	outb %al, $0x92 		## 将改动过的配置送回南桥芯片
	jmp preswitch
	
	### 0x64端口
enable_a20.1:	
	inb	$0x64,	%al
	testb	$0x2,	%al
	jnz	enable_a20.1
	movb	$0xd1,	%al			# write command
	outb	%al,	$0x64
	
enable_a20.2:
	inb	$0x64,	%al
	testb	$0x2,	%al
	jnz	enable_a20.2
	movb	$0xdf,	%al			# write command
	outb	%al,	$0x60
	#jmp preswitch
	
### load gdt
preswitch:
	#cli
	#lgdt	gdt_pointer   #加载GDT表
	#movl	%cr0,	%eax
	#orl	$1,	%eax          
	#movl	%eax,	%cr0  #打开保护模式
	#ljmp	$0b1000,	$init_prot  #跳转到保护模式运行
	cli
	lgdt    gdt_ptr
	movl    %cr0, %eax
	orl     $0x1, %eax
	movl    %eax, %cr0

	ljmp $0x8, $protect_mode	# ljmp将清空cs中的值，避免实模式切换至保护模式时，发生一些错误
							# 代码段段选子为 00001 000,偏移量为保护模式代码段地址
							# 此后将工作至保护模式下
							
							
### 32位保护模式 基于段选子寻址
### TODO 基于页寻址
.code32
protect_mode:
	movw    $0x10, %ax    # 数据段索引在gdt中索引下标为2，Our data segment selector
	movw    %ax, %ds                # -> DS: Data Segment
	movw    %ax, %es                # -> ES: Extra Segment
	movw    %ax, %ss                # -> SS: Stack Segment
	movw    $0, %ax                 # Zero segments not ready for use
	movw    %ax, %fs                # -> FS
	movw    %ax, %gs                # -> GS
	
	call p_clean

_over:
	jmp	_over

### 保护模式下打印字符串


### 保护模式清屏
p_clean:
	xorl	%ecx,	%ecx
	movl	$0xb8000,	%ebx
p_clearchar:
	movb	$0x20,	%dl
	movb	$0x9f,	%dh	
	movl	$0x0f200f20,	(%ebx,%ecx,4)
	incl	%ecx
	cmpl	$1000,	%ecx
	jl	p_clearchar
	ret
	
msg:
    .ascii "Hello, TLOS!"
	
p_msg:
	.ascii "entry protect mode!"

gdt:
	.long 0, 0
	
	#code segament
	.word 0xffff	#(0-15)limit
	.word 0x0		#(16-31)base
	.byte 0x0		#(32-39)base
	.byte 0x9a		#(40-47)access byte
	.byte 0xcf		#低位(48-51)limit，高位(52-55)flags
	.byte 0x0		#(56-63)base
	
	#data segament
	.word 0xffff	#(0-15)limit
	.word 0x0		#(16-31)base
	.byte 0x0		#(32-39)base
	.byte 0x92		#(40-47)access byte
	.byte 0xcf		#低位(48-51)limit，高位(52-55)flags
	.byte 0x0		#(56-63)base

gdt_ptr:
	.word . - gdt - 1
	.long gdt
	
	.fill 0x1fe - (. - _start),1,0
	.word 0xaa55
	