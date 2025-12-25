[bits 64]

section .text:
    global _start

_start:
; Encode to hex from here
; Get kernel32dll base
xor rbx, rbx
mov rbx, gs:[0x60]          ; PEB struct
mov rbx, [rbx+0x18]         ; PEB_LDR_DATA
add rbx, 0x20               ; InMemoryOrderModuleList

; Walk doubly-linked-list
mov rbx, [rbx]              ; nt.dll ->
mov rbx, [rbx]              ; kernelbase.dll ->
mov rbx, [rbx]              ; kernel32.dll

mov rbx, [rbx+0x20]         ; Dllbase
mov r8,  rbx                ; &kernel32.dll

; Get kernel32 export directory
mov ebx, [r8+0x3c]          ; e_lfanew
add rbx, r8                 ; &NT_HEADERS

xor rcx, rcx
add cl, 0x88                ; ExportTable RVA
mov ebx, [rbx+rcx]          ; ExportTable RVA
add rbx, r8                 ; &IMAGE_EXPORT_DIRECTORY(kernel32)
mov r9,  rbx                ; &ExportDirectory

; AddressOfFunctions
xor r10, r10
mov r10d, [r9+0x1c]
add r10, r8

; AddressOfNames
xor r11, r11
mov r11d, [r9+0x20]
add r11, r8

; AddressOfNameOrdinals
xor r12, r12
mov r12d, [r9+0x24]
add r12, r8

; Find LoadLibraryA
xor rcx, rcx
add cl, 12                  ; "LoadLibraryA" length -> 12

xor rax, rax                ; "\0"
push rax
mov rax, 0x41797261         ; "Ayra"
push rax
mov rax, 0x7262694c64616f4c ; "rbiLdaoL"
push rax

mov rbx, rsp                ; &"LoadLibraryA\0"

call winapi_resolver        ; Resolver call
mov  r13, rax               ; &LoadLibraryA


; LoadLibraryA("user32.dll");
xor rax, rax                    ; "\0"
push rax
mov rax, 0x6C6C                 ; "ll"
push rax
mov rax, 0x642e323372657375     ; "d23resu"
push rax

mov rcx, rsp                    ; &"user32dll\0"

sub rsp, 0x28                   ; shadow space
call r13                        ; LoadLibraryA("user32dll")
add rsp, 0x28                   ; shadow space

mov r14, rax                    ; user32.dll base

; Build export pointers for user32
mov r8, r14                 ; &user32dll

mov ebx, [r8+0x3c]          ; e_lfanew
add rbx, r8                 ; &NT_HEADERS(user32)

xor rcx, rcx
add cl, 0x88                ; offset ExportTable RVA
mov ebx, [rbx+rcx]          ; ExportTable RVA
add rbx, r8                 ; &IMAGE_EXPORT_DIRECTORY(user32)
mov r9,  rbx                ; r9 = export dir

xor r10, r10
mov r10d, [r9+0x1c]         ; AddressOfFunctions RVA
add r10, r8                 ; VA

xor r11, r11
mov r11d, [r9+0x20]         ; AddressOfNames RVA
add r11, r8                 ; VA

xor r12, r12
mov r12d, [r9+0x24]         ; AddressOfNameOrdinals RVA
add r12, r8                 ; VA

; Resolve MessageBoxA
xor rcx, rcx
mov cl, 11                  ; "MessageBoxA" length -> 11

xor rax, rax                ; "\0"
push rax
mov rax, 0x41786f           ; "Axo"
push rax
mov rax, 0x426567617373654d ; "BegasseM"
push rax

mov rbx, rsp                ; &"MessageBoxA\0"

call winapi_resolver
mov  r15, rax               ; r15 = &MessageBoxA


; int MessageBoxA(HWND, LPCSTR, LPCSTR, UINT)int MessageBoxA(
;  [in, optional] HWND   hWnd,      -> RCX
;  [in, optional] LPCSTR lpText,    -> RDX
;  [in, optional] LPCSTR lpCaption, -> R8
;  [in]           UINT   uType      -> R9
;);

; Call MessageBoxA
xor rax, rax                    ; "\0"
push rax
mov rax, 0x776f656d             ; "woem"
push rax
mov rax, 0x2064617065746f6e     ; " dapeton"
push rax
mov rdx, rsp                    ; &"notepad meow\0"

xor rax, rax                    ; "\0"
push rax
mov rax, 0x6f6c6c6548           ; "olleH"
push rax
mov r8, rsp                     ; &"Hello\0"

mov r9d, 1                      ; 1 -> MB_OKCANCEL 0x00000001L The message box contains two push buttons: OK and Cancel.
xor rcx, rcx                    ; HWND -> NULL

sub rsp, 0x28                   ; shadowspace
call r15                        ; MessageBoxA(rcx, rdx, r8, r9);
add rsp, 0x28
ret                             ; Done

; Export resolver
winapi_resolver:
    ; R8  = module base
    ; R10 = &AddressOfFunctions
    ; R11 = &AddressOfNames
    ; R12 = &AddressOfNameOrdinals
    ; RBX = function_name
    ; RCX = length
    ; RAX returns function address
    xor rax, rax
    push rcx                ; preserve length

    loop:
        xor rdi, rdi
        mov rcx, [rsp]          ; length
        mov rsi, rbx            ; function_name

        mov edi, [r11+rax*4]    ; name RVA
        add rdi, r8             ; VA
        repe cmpsb
        je resolve

        inc rax
        jmp short loop

    resolve:
        pop rcx                 ; restore length
        mov ax, [r12+rax*2]     ; ordinal
        mov eax, [r10+rax*4]    ; function RVA
        add rax, r8             ; VA
        ret
