.set IRQ_BASE, 0x20

.section .text

.extern handle_interrupt

# bindings for

.extern ignore_irq
.global ignore_irq

.macro HandleExeception num
.global handle_exception\num\()
handle_exception\num\():
  movb $\num, (interruptnumber)
  jmp int_bottom
.endm

.macro HandleInterruptRequest num
.global handle_irq\num\()
handle_irq\num\():
  movb $\num + IRQ_BASE, (interruptnumber)
  jmp int_bottom
.endm

HandleInterruptRequest 0x00
HandleInterruptRequest 0x01

int_bottom:

  pusha
  pushl %ds
  pushl %es
  pushl %fs
  pushl %gs

  pushl %esp
  push (interruptnumber)
  call handle_interrupt
  # addl $5, %esp
  movl %eax, %esp  # ok for now because handle_interrupt returns the esp value

  popl %gs
  popl %fs
  popl %fs
  popl %es
  popl %ds
  popa

ignore_irq:
  # return out from the interrupt
  iret

.data
  interruptnumber: .byte 0

