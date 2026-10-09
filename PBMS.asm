section .text
global _start

_start:
    NOP
    NOP
    NOP
    NOP

    MOV ECX, ESP        

    RDTSC
    MOV ESI, EAX

    MOV [ECX], EAX      

    RDTSC

    SUB EAX, ESI
    MOV EBX, EAX
