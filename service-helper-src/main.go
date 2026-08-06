// CFW-Mihomo privileged core service.
// It exposes only a minimal loopback API compatible with Clash for Windows.
// Privileged actions require a per-install token and always launch the protected,
// SHA-256-pinned Mihomo executable configured by the elevated installer.
package main

import (
	"crypto/sha256"
	"crypto/subtle"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"syscall"
	"time"
)

const (
	serviceVersion = "1.4.0"
	listenAddress  = "127.0.0.1:53000"
	tokenHeader    = "X-CFW-Mihomo-Token"
	maxBodyBytes   = 64 * 1024
)

type serviceConfig struct {
	TokenSHA256         string `json:"tokenSha256"`
	RequestedCorePath   string `json:"requestedCorePath"`
	ProtectedCorePath   string `json:"protectedCorePath"`
	ProtectedCoreSHA256 string `json:"protectedCoreSha256"`
	AllowedWorkingDir   string `json:"allowedWorkingDirectory"`
	PIDFile             string `json:"pidFile"`
}

type startRequest struct {
	Path   string `json:"path"`
	CWD    string `json:"cwd"`
	Silent bool   `json:"silent"`
}

type coreManager struct {
	mu      sync.Mutex
	cfg     serviceConfig
	cmd     *exec.Cmd
	pid     int
	logFile *os.File
}

func main() {
	cfg, err := loadConfig()
	if err != nil {
		log.Fatalf("load service config: %v", err)
	}
	if err := validateConfig(cfg); err != nil {
		log.Fatalf("invalid service config: %v", err)
	}

	manager := &coreManager{cfg: cfg}
	mux := http.NewServeMux()
	mux.HandleFunc("/ping", manager.handlePing)
	mux.HandleFunc("/start", manager.requireAuth(manager.handleStart))
	mux.HandleFunc("/stop", manager.requireAuth(manager.handleStop))
	mux.HandleFunc("/status", manager.requireAuth(manager.handleStatus))

	listener, err := net.Listen("tcp4", listenAddress)
	if err != nil {
		log.Fatalf("listen on %s: %v", listenAddress, err)
	}
	server := &http.Server{
		Handler:           securityHeaders(mux),
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      15 * time.Second,
		IdleTimeout:       30 * time.Second,
	}
	log.Printf("CFW-Mihomo service %s listening on %s", serviceVersion, listenAddress)
	if err := server.Serve(listener); err != nil && !errors.Is(err, http.ErrServerClosed) {
		log.Fatalf("serve: %v", err)
	}
}

func configPath() string {
	if custom := strings.TrimSpace(os.Getenv("CFW_MIHOMO_SERVICE_CONFIG")); custom != "" {
		return custom
	}
	base := strings.TrimSpace(os.Getenv("ProgramData"))
	if base == "" {
		base = `C:\ProgramData`
	}
	return filepath.Join(base, "CFW-Mihomo", "service-config.json")
}

func loadConfig() (serviceConfig, error) {
	var cfg serviceConfig
	data, err := os.ReadFile(configPath())
	if err != nil {
		return cfg, err
	}
	data = trimUTF8BOM(data)
	if err := json.Unmarshal(data, &cfg); err != nil {
		return cfg, err
	}
	return cfg, nil
}

func trimUTF8BOM(data []byte) []byte {
	if len(data) >= 3 && data[0] == 0xEF && data[1] == 0xBB && data[2] == 0xBF {
		return data[3:]
	}
	return data
}

func validateConfig(cfg serviceConfig) error {
	required := map[string]string{
		"tokenSha256":             cfg.TokenSHA256,
		"requestedCorePath":       cfg.RequestedCorePath,
		"protectedCorePath":       cfg.ProtectedCorePath,
		"protectedCoreSha256":     cfg.ProtectedCoreSHA256,
		"allowedWorkingDirectory": cfg.AllowedWorkingDir,
		"pidFile":                 cfg.PIDFile,
	}
	for name, value := range required {
		if strings.TrimSpace(value) == "" {
			return fmt.Errorf("%s is empty", name)
		}
	}
	if _, err := hex.DecodeString(strings.TrimSpace(cfg.TokenSHA256)); err != nil {
		return fmt.Errorf("invalid token hash: %w", err)
	}
	if _, err := hex.DecodeString(strings.TrimSpace(cfg.ProtectedCoreSHA256)); err != nil {
		return fmt.Errorf("invalid core hash: %w", err)
	}
	return nil
}

func securityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Cache-Control", "no-store")
		w.Header().Set("X-Content-Type-Options", "nosniff")
		// CFW runs its renderer from an Electron origin. The token still protects
		// privileged operations, while these headers allow the renderer's CORS
		// preflight for JSON and X-CFW-Mihomo-Token requests.
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, X-CFW-Mihomo-Token")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func (m *coreManager) handlePing(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	_, _ = io.WriteString(w, "pong "+serviceVersion)
}

func (m *coreManager) requireAuth(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		token := strings.TrimSpace(r.Header.Get(tokenHeader))
		tokenSum := sha256.Sum256([]byte(token))
		expected, err := hex.DecodeString(strings.TrimSpace(m.cfg.TokenSHA256))
		if err != nil || len(expected) != sha256.Size || subtle.ConstantTimeCompare(tokenSum[:], expected) != 1 {
			http.Error(w, "unauthorized", http.StatusUnauthorized)
			return
		}
		next(w, r)
	}
}

func (m *coreManager) handleStart(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	r.Body = http.MaxBytesReader(w, r.Body, maxBodyBytes)
	defer r.Body.Close()

	var req startRequest
	dec := json.NewDecoder(r.Body)
	dec.DisallowUnknownFields()
	if err := dec.Decode(&req); err != nil {
		http.Error(w, "invalid request: "+err.Error(), http.StatusBadRequest)
		return
	}
	if !sameWindowsPath(req.Path, m.cfg.RequestedCorePath) {
		http.Error(w, "requested core path is not allowed", http.StatusForbidden)
		return
	}
	if !sameWindowsPath(req.CWD, m.cfg.AllowedWorkingDir) {
		http.Error(w, "working directory is not allowed", http.StatusForbidden)
		return
	}
	if err := verifyFileSHA256(m.cfg.ProtectedCorePath, m.cfg.ProtectedCoreSHA256); err != nil {
		http.Error(w, "protected core verification failed: "+err.Error(), http.StatusForbidden)
		return
	}

	logPath, err := m.startCore(req.Silent)
	if err != nil {
		http.Error(w, "failed to start core: "+err.Error(), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	_, _ = io.WriteString(w, logPath)
}

func (m *coreManager) handleStop(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet && r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	if err := m.stopCore(); err != nil {
		http.Error(w, "failed to stop core: "+err.Error(), http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusOK)
	_, _ = io.WriteString(w, "stopped")
}

func (m *coreManager) handleStatus(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	m.mu.Lock()
	pid := m.pid
	m.mu.Unlock()
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{"version": serviceVersion, "pid": pid})
}

func (m *coreManager) startCore(silent bool) (string, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	_ = m.stopCoreLocked()

	if err := os.MkdirAll(m.cfg.AllowedWorkingDir, 0o755); err != nil {
		return "", err
	}

	logPath := ""
	var output io.Writer = io.Discard
	var logFile *os.File
	if !silent {
		logsDir := filepath.Join(m.cfg.AllowedWorkingDir, "logs")
		if err := os.MkdirAll(logsDir, 0o755); err != nil {
			return "", err
		}
		logPath = filepath.Join(logsDir, time.Now().Format("2006-01-02-150405")+"-service.log")
		f, err := os.OpenFile(logPath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0o644)
		if err != nil {
			return "", err
		}
		logFile = f
		output = f
	}

	cmd := exec.Command(m.cfg.ProtectedCorePath, "-d", m.cfg.AllowedWorkingDir)
	cmd.Dir = m.cfg.AllowedWorkingDir
	cmd.Stdout = output
	cmd.Stderr = output
	cmd.Stdin = nil
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true, CreationFlags: 0x08000000}

	if err := cmd.Start(); err != nil {
		if logFile != nil {
			_ = logFile.Close()
		}
		return "", err
	}

	m.cmd = cmd
	m.pid = cmd.Process.Pid
	m.logFile = logFile
	if err := writePIDFile(m.cfg.PIDFile, m.pid); err != nil {
		_ = terminateProcessTree(m.pid)
		if logFile != nil {
			_ = logFile.Close()
		}
		m.cmd = nil
		m.pid = 0
		m.logFile = nil
		return "", err
	}

	pid := m.pid
	go func() {
		_ = cmd.Wait()
		m.mu.Lock()
		defer m.mu.Unlock()
		if m.pid == pid {
			m.pid = 0
			m.cmd = nil
			_ = os.Remove(m.cfg.PIDFile)
			if m.logFile != nil {
				_ = m.logFile.Close()
				m.logFile = nil
			}
		}
	}()

	return logPath, nil
}

func (m *coreManager) stopCore() error {
	m.mu.Lock()
	defer m.mu.Unlock()
	return m.stopCoreLocked()
}

func (m *coreManager) stopCoreLocked() error {
	pid := m.pid
	if pid == 0 {
		pid = readPIDFile(m.cfg.PIDFile)
	}
	if pid > 0 {
		if processImageLooksLikeCore(pid) {
			if err := terminateProcessTree(pid); err != nil {
				return err
			}
		}
	}
	m.pid = 0
	m.cmd = nil
	_ = os.Remove(m.cfg.PIDFile)
	if m.logFile != nil {
		_ = m.logFile.Close()
		m.logFile = nil
	}
	return nil
}

func writePIDFile(path string, pid int) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	return os.WriteFile(path, []byte(strconv.Itoa(pid)), 0o600)
}

func readPIDFile(path string) int {
	data, err := os.ReadFile(path)
	if err != nil {
		return 0
	}
	pid, _ := strconv.Atoi(strings.TrimSpace(string(data)))
	return pid
}

func processImageLooksLikeCore(pid int) bool {
	out, err := exec.Command("tasklist.exe", "/FI", "PID eq "+strconv.Itoa(pid), "/FO", "CSV", "/NH").CombinedOutput()
	if err != nil {
		return false
	}
	text := strings.ToLower(string(out))
	return strings.Contains(text, "clash-win64.exe") || strings.Contains(text, "mihomo")
}

func terminateProcessTree(pid int) error {
	cmd := exec.Command("taskkill.exe", "/PID", strconv.Itoa(pid), "/T", "/F")
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true, CreationFlags: 0x08000000}
	out, err := cmd.CombinedOutput()
	if err != nil {
		lower := strings.ToLower(string(out))
		if strings.Contains(lower, "not found") || strings.Contains(lower, "no running instance") {
			return nil
		}
		return fmt.Errorf("taskkill: %w: %s", err, strings.TrimSpace(string(out)))
	}
	return nil
}

func verifyFileSHA256(path, expected string) error {
	f, err := os.Open(path)
	if err != nil {
		return err
	}
	defer f.Close()
	h := sha256.New()
	if _, err := io.Copy(h, f); err != nil {
		return err
	}
	actual := hex.EncodeToString(h.Sum(nil))
	if subtle.ConstantTimeCompare([]byte(strings.ToLower(actual)), []byte(strings.ToLower(strings.TrimSpace(expected)))) != 1 {
		return fmt.Errorf("sha256 mismatch")
	}
	return nil
}

func sameWindowsPath(a, b string) bool {
	ca := filepath.Clean(strings.TrimSpace(a))
	cb := filepath.Clean(strings.TrimSpace(b))
	return strings.EqualFold(ca, cb)
}
