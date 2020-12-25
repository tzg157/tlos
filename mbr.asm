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
	
	movb $0x0, %bh
	movw $0x0, %dx
	call set_currsor
	call clean_screen
	
	call set_bgcolor

    call print
	
loop:
    jmp loop

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
	
msg:
    .ascii "Hello, TLOS!"
    .org 510
    .word 0xAA55
	