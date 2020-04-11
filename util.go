package main

import (
	"os"
	"strings"
)

func getDirString(url string) string {
	// url = strings.Trim(url, "/")
	a := strings.Split(url, "/")
	a = a[0 : len(a)-1]
	b := strings.Join(a, "/")
	return b
}

func isHttpUrl(file string) bool {
	if file[0:4] == "http" {
		return true
	}
	return false
}

func isSingleFile(file string) bool {
	a := strings.Split(file, "/")
	if len(a) > 1 {
		return false
	}
	return true
}

func isM3u8File(file string) bool {
	sp := strings.Split(file, ".")
	ftype := sp[len(sp)-1]
	if ftype == "m3u8" {
		return true
	}
	return false
}

func appendOnlyOne(list []string, key string) []string {
	for i := 0; i < len(list); i++ {
		if list[i] == key {
			return list
		}
	}
	return append(list, key)
}

func pathExists(path string) (bool, error) {
	_, err := os.Stat(path)
	if err == nil {
		return true, nil
	}
	if os.IsNotExist(err) {
		return false, nil
	}
	return false, err
}

func writeFileContent(file string, content string) error {
	f, err := os.Create(file)
	if err != nil {
		return err
	}
	defer f.Close()

	_, err = f.WriteString(content)
	if err != nil {
		return err
	}
	return nil
}
