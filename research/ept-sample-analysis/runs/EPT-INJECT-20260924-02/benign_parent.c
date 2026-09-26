#include <windows.h>
int main(void) {
    STARTUPINFOA si = {0};
    PROCESS_INFORMATION pi = {0};
    si.cb = sizeof(si);
    char command[] = "C:\\Windows\\System32\\cmd.exe /c exit 0";
    if (!CreateProcessA(NULL, command, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi)) return 2;
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
    return 0;
}
