package core

import (
	"fmt"
	"os/exec"
)

// API is the public facade for core operations.
type API struct {
	nmPath string
}

// NewAPI creates a default API using /usr/bin/nm.
func NewAPI() *API {
	return &API{nmPath: "/usr/bin/nm"}
}

// ScanFile runs nm against the provided file and returns the output or error message.
func (api *API) ScanFile(filename string) string {
	cmd := exec.Command(api.nmPath, filename)
	out, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Sprintf("nm %s failed: %v\n%s", filename, err, string(out))
	}
	return string(out)
}
