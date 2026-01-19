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
func nm_grep(searchIn *C.char, word *C.char, out_size *C.int) *C.int {
	s := core.Search{
		SearchIn: C.GoString(searchIn),
		Query:    C.GoString(word),
	}
	r, err := s.Search()

	if err != nil {
		*out_size = 0
		return nil
	}

	// we need to allocate on the heap but the C heap
	ptr := (*C.int)(C.malloc(C.size_t(len(r)) * C.size_t(unsafe.Sizeof(C.int(0)))))

	arr := unsafe.Slice(ptr, len(r))

	for i, v := range r {
		arr[i] = C.int(v)
	}

	*out_size = C.int(len(r))
	return ptr
}

func main() {}
