package main

import (
	"testing"
)

func Test_getDirString(t *testing.T) {
	if getDirString("/tmp/vv") != "/tmp" {
		t.Errorf("/tmp/vv => %s; want /tmp", getDirString("/tmp/vv"))
	}
}

func Benchmark_getDirString(b *testing.B) {
	for i := 0; i < b.N; i++ {
		getDirString("/tmp/vv")
	}
}
