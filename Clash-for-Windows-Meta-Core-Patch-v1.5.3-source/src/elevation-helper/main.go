// cfw-elevate is a small Windows-only UAC launcher used by Clash for Windows Meta Core Patch.
// It accepts only a generated runner.ps1 located in the current user's temp
// directory under a cfw-elevate-* folder, invokes Windows PowerShell through
// the native ShellExecuteExW "runas" verb, waits for completion, and returns
// the exact child exit code.
package main

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
	"time"
	"unsafe"
)

const (
	seeMaskNoCloseProcess = 0x00000040
	seeMaskFlagNoUI       = 0x00000400
	swHide                = 0
	waitObject0           = 0x00000000
	infinite              = 0xFFFFFFFF
	tokenQuery            = 0x0008
	tokenElevation        = 20
	createNoWindow        = 0x08000000
	errorCancelled        = 1223
)

type shellExecuteInfo struct {
	cbSize       uint32
	fMask        uint32
	hwnd         uintptr
	lpVerb       *uint16
	lpFile       *uint16
	lpParameters *uint16
	lpDirectory  *uint16
	nShow        int32
	hInstApp     uintptr
	lpIDList     uintptr
	lpClass      *uint16
	hkeyClass    uintptr
	dwHotKey     uint32
	hMonitor     uintptr
	hProcess     syscall.Handle
}

var (
	shell32                 = syscall.NewLazyDLL("shell32.dll")
	procShellExecuteExW     = shell32.NewProc("ShellExecuteExW")
	kernel32                = syscall.NewLazyDLL("kernel32.dll")
	procWaitForSingleObject = kernel32.NewProc("WaitForSingleObject")
	procGetExitCodeProcess  = kernel32.NewProc("GetExitCodeProcess")
	procCloseHandle         = kernel32.NewProc("CloseHandle")
	procGetCurrentProcess   = kernel32.NewProc("GetCurrentProcess")
	advapi32                = syscall.NewLazyDLL("advapi32.dll")
	procOpenProcessToken    = advapi32.NewProc("OpenProcessToken")
	procGetTokenInformation = advapi32.NewProc("GetTokenInformation")
)

func main() {
	script, logPath, err := parseArgs(os.Args[1:])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(2)
	}
	logLine(logPath, "START script="+script)

	if err := validateScript(script); err != nil {
		logLine(logPath, "REJECT "+err.Error())
		fmt.Fprintln(os.Stderr, err)
		os.Exit(3)
	}

	var code uint32
	if isElevated() {
		code, err = runDirect(script)
	} else {
		code, err = runElevated(script)
	}
	if err != nil {
		var errno syscall.Errno
		if errors.As(err, &errno) && uint32(errno) == errorCancelled {
			logLine(logPath, "CANCELLED")
			fmt.Fprintln(os.Stderr, "The UAC request was cancelled.")
			os.Exit(errorCancelled)
		}
		logLine(logPath, "ERROR "+err.Error())
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	logLine(logPath, fmt.Sprintf("EXIT code=%d", code))
	os.Exit(int(code))
}

func parseArgs(args []string) (script, logPath string, err error) {
	for i := 0; i < len(args); i++ {
		switch args[i] {
		case "--script":
			if i+1 >= len(args) {
				return "", "", fmt.Errorf("--script requires a value")
			}
			i++
			script = args[i]
		case "--log":
			if i+1 >= len(args) {
				return "", "", fmt.Errorf("--log requires a value")
			}
			i++
			logPath = args[i]
		default:
			return "", "", fmt.Errorf("unknown argument: %s", args[i])
		}
	}
	if strings.TrimSpace(script) == "" {
		return "", "", fmt.Errorf("--script is required")
	}
	abs, err := filepath.Abs(script)
	if err != nil {
		return "", "", err
	}
	script = abs
	if strings.TrimSpace(logPath) == "" {
		home, _ := os.UserHomeDir()
		logPath = filepath.Join(home, ".config", "clash", "cfw-elevation.log")
	}
	return script, logPath, nil
}

func validateScript(script string) error {
	info, err := os.Stat(script)
	if err != nil {
		return fmt.Errorf("runner script is unavailable: %w", err)
	}
	if info.IsDir() || !strings.EqualFold(filepath.Ext(script), ".ps1") {
		return fmt.Errorf("runner must be a .ps1 file")
	}

	tempAbs, err := filepath.Abs(os.TempDir())
	if err != nil {
		return err
	}
	scriptAbs, err := filepath.Abs(script)
	if err != nil {
		return err
	}
	rel, err := filepath.Rel(tempAbs, scriptAbs)
	if err != nil || rel == "." || strings.HasPrefix(rel, ".."+string(os.PathSeparator)) || rel == ".." {
		return fmt.Errorf("runner is outside the current user's temp directory")
	}
	first := strings.Split(rel, string(os.PathSeparator))[0]
	if !strings.HasPrefix(strings.ToLower(first), "cfw-elevate-") {
		return fmt.Errorf("runner directory is not a CFW elevation workspace")
	}
	return nil
}

func powershellPath() string {
	root := os.Getenv("SystemRoot")
	if root == "" {
		root = `C:\Windows`
	}
	candidate := filepath.Join(root, "System32", "WindowsPowerShell", "v1.0", "powershell.exe")
	if _, err := os.Stat(candidate); err == nil {
		return candidate
	}
	if found, err := exec.LookPath("powershell.exe"); err == nil {
		return found
	}
	return candidate
}

func runDirect(script string) (uint32, error) {
	powershell := powershellPath()
	cmd := exec.Command(powershell, "-NoLogo", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File", script)
	cmd.Dir = filepath.Dir(script)
	cmd.Stdin = nil
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true, CreationFlags: createNoWindow}
	err := cmd.Run()
	if err == nil {
		return 0, nil
	}
	var exitErr *exec.ExitError
	if errors.As(err, &exitErr) {
		return uint32(exitErr.ExitCode()), nil
	}
	return 0, err
}

func runElevated(script string) (uint32, error) {
	powershell := powershellPath()
	verb, _ := syscall.UTF16PtrFromString("runas")
	file, _ := syscall.UTF16PtrFromString(powershell)
	params, _ := syscall.UTF16PtrFromString(`-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "` + strings.ReplaceAll(script, `"`, `\"`) + `"`)
	dir, _ := syscall.UTF16PtrFromString(filepath.Dir(script))

	sei := shellExecuteInfo{
		fMask:        seeMaskNoCloseProcess | seeMaskFlagNoUI,
		lpVerb:       verb,
		lpFile:       file,
		lpParameters: params,
		lpDirectory:  dir,
		nShow:        swHide,
	}
	sei.cbSize = uint32(unsafe.Sizeof(sei))
	r1, _, callErr := procShellExecuteExW.Call(uintptr(unsafe.Pointer(&sei)))
	if r1 == 0 {
		if callErr != syscall.Errno(0) {
			return 0, callErr
		}
		return 0, fmt.Errorf("ShellExecuteExW failed")
	}
	if sei.hProcess == 0 {
		return 0, fmt.Errorf("elevated process handle was not returned")
	}
	defer procCloseHandle.Call(uintptr(sei.hProcess))

	wait, _, waitErr := procWaitForSingleObject.Call(uintptr(sei.hProcess), infinite)
	if uint32(wait) != waitObject0 {
		if waitErr != syscall.Errno(0) {
			return 0, waitErr
		}
		return 0, fmt.Errorf("waiting for elevated process failed: 0x%x", wait)
	}
	var exitCode uint32
	ok, _, codeErr := procGetExitCodeProcess.Call(uintptr(sei.hProcess), uintptr(unsafe.Pointer(&exitCode)))
	if ok == 0 {
		if codeErr != syscall.Errno(0) {
			return 0, codeErr
		}
		return 0, fmt.Errorf("GetExitCodeProcess failed")
	}
	return exitCode, nil
}

func isElevated() bool {
	current, _, _ := procGetCurrentProcess.Call()
	var token syscall.Handle
	ok, _, _ := procOpenProcessToken.Call(current, tokenQuery, uintptr(unsafe.Pointer(&token)))
	if ok == 0 || token == 0 {
		return false
	}
	defer procCloseHandle.Call(uintptr(token))

	var elevated uint32
	var returned uint32
	ok, _, _ = procGetTokenInformation.Call(
		uintptr(token),
		tokenElevation,
		uintptr(unsafe.Pointer(&elevated)),
		unsafe.Sizeof(elevated),
		uintptr(unsafe.Pointer(&returned)),
	)
	return ok != 0 && elevated != 0
}

func logLine(path, message string) {
	if strings.TrimSpace(path) == "" {
		return
	}
	_ = os.MkdirAll(filepath.Dir(path), 0o755)
	f, err := os.OpenFile(path, os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0o600)
	if err != nil {
		return
	}
	defer f.Close()
	_, _ = fmt.Fprintf(f, "[%s] native-helper %s\r\n", time.Now().Format(time.RFC3339), message)
}
