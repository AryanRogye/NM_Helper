package main

/*
#include <stdlib.h>
*/
import "C"

import (
	"fmt"
	"unsafe"
)
import "os/exec"

type nm_config struct {
	filename string
}

func (nm *nm_config) init() string {
	cmd := exec.Command("/usr/bin/nm", nm.filename)
	out, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Sprintf("nm %s failed: %v\n%s", nm.filename, err, string(out))
	}
	return string(out)
}

//export get_hello
func get_hello() *C.char {
	return C.CString("mONKEY YSDF SDF")
}

//export nm_free
func nm_free(ptr *C.char) {
	C.free(unsafe.Pointer(ptr))
}

// Scan and return the file
//
//export nm_scan_file
func nm_scan_file(filename *C.char) *C.char {
	config := nm_config{
		filename: C.GoString(filename),
	}
	out := config.init()
	return C.CString(out)
}

func main() {}
