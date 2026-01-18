package main

/*
#include <stdlib.h>
*/
import "C"

import (
	"unsafe"

	"nm_core/core"
)

var api = core.NewAPI()

//export nm_free
func nm_free(ptr *C.char) {
	C.free(unsafe.Pointer(ptr))
}

//export nm_scan_file
func nm_scan_file(filename *C.char) *C.char {
	out := api.ScanFile(C.GoString(filename))
	return C.CString(out)
}

//export nm_grep
func nm_grep(searchIn *C.char, word *C.char) []int {
	s := core.Search{
		SearchIn: C.GoString(searchIn),
		Query:    C.GoString(word),
	}
	r, err := s.Search()

	if err != nil {
		return []int{}
	}

	var results []int
	for _, result := range r {
		results = append(results, result)
	}
	return results
}

func main() {}
