section .text
global _start
default rel

_start:
    lea rdi, msg_header
    call print_str

    lea rdi, msg_sec_system
    call print_str

    lea rdi, msg_hostname
    call print_str
    lea rdi, path_hostname
    call print_file

    lea rdi, msg_version
    call print_str
    lea rdi, path_version
    call print_file

    lea rdi, msg_sec_dmi
    call print_str

    lea rdi, msg_vendor
    call print_str
    lea rdi, path_vendor
    call print_file

    lea rdi, msg_product
    call print_str
    lea rdi, path_product
    call print_file

    lea rdi, msg_serial
    call print_str
    lea rdi, path_serial
    call print_file

    lea rdi, msg_board
    call print_str
    lea rdi, path_board
    call print_file

    lea rdi, msg_bios_vendor
    call print_str
    lea rdi, path_bios_vendor
    call print_file

    lea rdi, msg_bios_version
    call print_str
    lea rdi, path_bios_version
    call print_file

    lea rdi, msg_bios_date
    call print_str
    lea rdi, path_bios_date
    call print_file

    lea rdi, sysinfo_buf
    mov rax, 99
    syscall

    test rax, rax
    js .exit_error

    lea rdi, msg_sec_metrics
    call print_str

    lea rdi, msg_uptime
    call print_str

    mov rax, [sysinfo_buf]
    call print_ulong

    lea rdi, msg_sec_suffix
    call print_str

    lea rdi, msg_procs
    call print_str

    movzx rax, word [sysinfo_buf + 80]
    call print_ulong

    lea rdi, msg_nl
    call print_str

    mov rax, [sysinfo_buf + 32]
    mov ebx, [sysinfo_buf + 104]
    mul rbx

    mov rcx, 1048576
    div rcx

    push rax

    lea rdi, msg_ram_total
    call print_str

    pop rax
    call print_ulong

    lea rdi, msg_mb
    call print_str

    mov rax, [sysinfo_buf + 40]
    mov ebx, [sysinfo_buf + 104]
    mul rbx

    mov rcx, 1048576
    div rcx

    push rax

    lea rdi, msg_ram_free
    call print_str

    pop rax
    call print_ulong

    lea rdi, msg_mb
    call print_str

    lea rdi, msg_sec_cpu
    call print_str

    lea rdi, path_cpuinfo
    call print_cpu_first

    lea rdi, msg_footer
    call print_str

    mov rax, 60
    xor rdi, rdi
    syscall

.exit_error:
    mov rax, 60
    mov rdi, 1
    syscall


; --------------------------------------------------
; print_str
; Null-terminated string yazdırır.
; Kısmi write işlemlerini destekler.
; --------------------------------------------------

print_str:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi

    mov rsi, rdi

.len_loop:
    cmp byte [rsi], 0
    je .len_done

    inc rsi
    jmp .len_loop

.len_done:
    sub rsi, rdi
    mov rdx, rsi
    mov rsi, rdi

    mov rbx, rdx
    test rbx, rbx
    jz .done

.write_loop:
    mov rax, 1
    mov rdi, 1
    mov rdx, rbx
    syscall

    test rax, rax
    jle .done

    add rsi, rax
    sub rbx, rax

    jnz .write_loop

.done:
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret


; --------------------------------------------------
; print_file
; Dosyayı açar, içeriğini okur ve satır sonunu
; kaldırarak yazdırır.
; --------------------------------------------------

print_file:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi

    mov rax, 2
    xor rsi, rsi
    syscall

    test rax, rax
    js .file_done

    mov rbx, rax

    xor rax, rax
    mov rdi, rbx
    lea rsi, [file_buf]
    mov rdx, 1023
    syscall

    test rax, rax
    jle .file_close

    mov rcx, rax
    mov byte [file_buf + rcx], 0

    lea rdi, [file_buf]

.trim_loop:
    cmp byte [rdi], 0
    je .trim_done

    cmp byte [rdi], 10
    je .trim_cut

    cmp byte [rdi], 13
    je .trim_cut

    inc rdi
    jmp .trim_loop

.trim_cut:
    mov byte [rdi], 0

.trim_done:
    lea rdi, [file_buf]
    call print_str

    lea rdi, [msg_nl]
    call print_str

.file_close:
    mov rax, 3
    mov rdi, rbx
    syscall

.file_done:
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret


; --------------------------------------------------
; print_cpu_first
; /proc/cpuinfo dosyasından ilk işlemci kaydını
; yazdırır. İkinci "processor" kaydında durur.
; --------------------------------------------------

print_cpu_first:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push r8
    push r9
    push r10

    mov rax, 2
    xor rsi, rsi
    syscall

    test rax, rax
    js .cpu_done

    mov rbx, rax

    ; Dosyadan ilk parçayı oku.
    xor rax, rax
    mov rdi, rbx
    lea rsi, [large_buf]
    mov rdx, 8191
    syscall

    test rax, rax
    jle .cpu_close

    mov r8, rax
    xor r9, r9

    ; İlk satırdan sonraki satırlarda
    ; "processor" başlangıcını ara.
.scan_loop:
    lea r10, [large_buf]
    add r10, r9

    cmp r9, r8
    jae .cpu_write_all

    cmp byte [r10], 10
    jne .scan_next

    ; Sonraki satır "processor" ile başlıyor mu?
    lea rcx, [r10 + 1]

    cmp byte [rcx], 'p'
    jne .scan_next

    cmp byte [rcx + 1], 'r'
    jne .scan_next

    cmp byte [rcx + 2], 'o'
    jne .scan_next

    cmp byte [rcx + 3], 'c'
    jne .scan_next

    cmp byte [rcx + 4], 'e'
    jne .scan_next

    cmp byte [rcx + 5], 's'
    jne .scan_next

    cmp byte [rcx + 6], 's'
    jne .scan_next

    cmp byte [rcx + 7], 'o'
    jne .scan_next

    cmp byte [rcx + 8], 'r'
    jne .scan_next

    ; Önceki satırın sonundaki newline dahil
    ; ilk işlemci kaydını yazdır.
    lea rsi, [large_buf]
    mov rdx, r9
    inc rdx

    jmp .cpu_write

.scan_next:
    inc r9
    jmp .scan_loop

.cpu_write_all:
    lea rsi, [large_buf]
    mov rdx, r8

.cpu_write:
    ; Kısmi write işlemlerini destekle.
    mov r10, rdx

.write_loop:
    test r10, r10
    jz .cpu_close

    mov rax, 1
    mov rdi, 1
    mov rdx, r10
    syscall

    test rax, rax
    jle .cpu_close

    add rsi, rax
    sub r10, rax

    jmp .write_loop

.cpu_close:
    mov rax, 3
    mov rdi, rbx
    syscall

.cpu_done:
    pop r10
    pop r9
    pop r8
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret


; --------------------------------------------------
; print_ulong
; Unsigned 64-bit tam sayı yazdırır.
; --------------------------------------------------

print_ulong:
    push rax
    push rbx
    push rcx
    push rdx
    push rdi

    mov rbx, 10
    lea rdi, [num_buf + 31]
    mov byte [rdi], 0

.convert_loop:
    xor rdx, rdx
    div rbx

    add dl, '0'
    dec rdi
    mov [rdi], dl

    test rax, rax
    jnz .convert_loop

    call print_str

    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret


section .data

    path_hostname       db "/proc/sys/kernel/hostname", 0
    path_version        db "/proc/version", 0

    path_vendor         db "/sys/class/dmi/id/sys_vendor", 0
    path_product        db "/sys/class/dmi/id/product_name", 0
    path_serial         db "/sys/class/dmi/id/product_serial", 0
    path_board          db "/sys/class/dmi/id/board_name", 0

    path_bios_vendor    db "/sys/class/dmi/id/bios_vendor", 0
    path_bios_version   db "/sys/class/dmi/id/bios_version", 0
    path_bios_date      db "/sys/class/dmi/id/bios_date", 0

    path_cpuinfo        db "/proc/cpuinfo", 0

    msg_header:
        db "======================================================================", 10
        db "             PURE ASSEMBLY HARDWARE & FIRMWARE DUMPER                 ", 10
        db "======================================================================", 10, 0

    msg_sec_system      db "[+] SYSTEM & KERNEL IDENTITY", 10, 0
    msg_hostname        db "    -> Hostname     : ", 0
    msg_version         db "    -> Kernel Ver   : ", 0

    msg_sec_dmi         db 10, "[+] HARDWARE, FIRMWARE & BIOS (DMI)", 10, 0

    msg_vendor          db "    -> Manufacturer : ", 0
    msg_product         db "    -> Product Name : ", 0
    msg_serial          db "    -> Serial Number: ", 0
    msg_board           db "    -> Motherboard  : ", 0

    msg_bios_vendor     db "    -> BIOS Vendor  : ", 0
    msg_bios_version    db "    -> BIOS Version : ", 0
    msg_bios_date       db "    -> BIOS Date    : ", 0

    msg_sec_metrics     db 10, "[+] SYSTEM METRICS & TOPOLOGY", 10, 0

    msg_uptime          db "    -> Uptime       : ", 0
    msg_sec_suffix      db " seconds", 10, 0
    msg_procs           db "    -> Active Tasks : ", 0

    msg_ram_total       db "    -> RAM Total    : ", 0
    msg_ram_free        db "    -> RAM Free     : ", 0
    msg_mb              db " MB", 10, 0

    msg_sec_cpu         db 10, "[+] PROCESSOR (CPU) HARDWARE SPECS", 10, 0

    msg_footer          db 10, "======================================================================", 10, 0
    msg_nl              db 10, 0


section .bss

    sysinfo_buf         resb 112
    file_buf            resb 1024
    large_buf           resb 8192
    num_buf             resb 32
