package main

import (
	"bufio"
	"crypto/tls"
	_ "errors"
	"fmt"
	"github.com/gin-contrib/multitemplate"
	"github.com/gin-gonic/gin"
	"github.com/huichen/murmur"
	"io"
	"io/ioutil"
	"net/http"
	"net/url"
	"os"
	"runtime"
	"strings"
)

const (
	MHC_CACHE_DIR = "cache"
)

func getSafeyHttp() *http.Client {
	tr := &http.Transport{
		TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
	}
	client := &http.Client{Transport: tr}
	return client
}

func httpGet(urlPath string) (string, error) {
	var err error
	var pathList []string
	client := getSafeyHttp()

	sc, err := url.Parse(urlPath)

	scPath := strings.Trim(sc.Path, "/")
	actualHash := murmur.Murmur3([]byte(sc.Path))
	scPath = fmt.Sprintf("%s/%s/%d%s", MHC_CACHE_DIR, sc.Host, actualHash, sc.Path)
	b := getDirString(scPath)

	resp, err := client.Get(urlPath)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}
	content := string(body)

	sReader := strings.NewReader(content)
	bReader := bufio.NewScanner(sReader)
	bReader.Split(bufio.ScanLines)
	var m3u8List []string
	for bReader.Scan() {
		line := bReader.Text()
		if !strings.HasPrefix(line, "#") {
			tsFileName := line
			m3u8List = append(m3u8List, tsFileName)
		} else {
			if strings.Contains(line, "URI") {
				downloadKey(fmt.Sprintf("%s/%s/%d", MHC_CACHE_DIR, sc.Host, actualHash), line)
			}
		}
	}

	if len(m3u8List) == 1 && isM3u8File(m3u8List[0]) {
		tsUrl := fmt.Sprintf("%s://%s%s", sc.Scheme, sc.Host, m3u8List[0])
		return httpGet(tsUrl)
	}

	// if _, err := pathExists(b); err != nil {
	os.MkdirAll(b, os.ModePerm)
	// }

	for _, val := range m3u8List {
		dir := getDirString(val)
		pathList = appendOnlyOne(pathList, dir)
	}

	go goDownloadTs(sc, actualHash, m3u8List)

	if exists, _ := pathExists(scPath); exists {
		return scPath, nil //errors.New("m3u8 file exists!")
	}

	for i := 0; i < len(pathList); i++ {
		tmp := fmt.Sprintf("%s/", pathList[i])
		content = strings.ReplaceAll(content, tmp, "")
	}
	err = writeFileContent(scPath, content)

	return scPath, err
}

func downloadKey(prefix, content string) {
	fmt.Println("downloadKey", content)

	list := strings.Split(content, "URI")
	urlKey := strings.Trim(list[1], "=")
	urlKey = strings.Trim(urlKey, "\"")

	sc, err := url.Parse(urlKey)

	fullPath := fmt.Sprintf("%s%s", prefix, sc.Path)

	client := getSafeyHttp()
	resp, err := client.Get(urlKey)
	if err != nil {
		fmt.Println("download ts ", urlKey, "failed,", err)
		return
	}
	defer resp.Body.Close()

	f, err := os.Create(fullPath)
	if err != nil {
		fmt.Println(f, err)
		return
	}
	io.Copy(f, resp.Body)
}

func goDownloadTs(sc *url.URL, actualHash uint32, list []string) {
	gDir := getDirString(sc.Path)
	tsUrl := ""

	for _, val := range list {
		if isSingleFile(val) {
			tsUrl = fmt.Sprintf("%s://%s%s/%s", sc.Scheme, sc.Host, gDir, val)
		} else if isHttpUrl(val) {
			tsUrl = val
		} else {
			tsUrl = fmt.Sprintf("%s://%s%s", sc.Scheme, sc.Host, val)
		}
		go downloadTS(fmt.Sprintf("%s/%s/%d", MHC_CACHE_DIR, sc.Host, actualHash), tsUrl)
	}
}

func sateyDownloadTs(pathPrefix string, tsUrl string) {

}

func downloadTS(pathPrefix string, tsUrl string) {
	fmt.Println("downloadTS", pathPrefix, tsUrl)
	sc, err := url.Parse(tsUrl)
	fmt.Println(sc.Path, err)

	scPath := fmt.Sprintf("%s%s", pathPrefix, sc.Path)
	b := getDirString(scPath)
	if _, err := pathExists(b); err != nil {
		os.MkdirAll(b, os.ModePerm)
	}

	if exists, _ := pathExists(scPath); exists {
		return
	}

	client := getSafeyHttp()

	resp, err := client.Get(tsUrl)
	if err != nil {
		fmt.Println("download ts ", tsUrl, "failed,", err)
		return
	}
	defer resp.Body.Close()

	f, err := os.Create(scPath)
	if err != nil {
		fmt.Println(f, err)
		return
	}
	io.Copy(f, resp.Body)
	// body, err := ioutil.ReadAll(resp.Body)
	// fmt.Println(string(body))

}

func envInit() {
	runtime.GOMAXPROCS(runtime.NumCPU())
	if _, err := pathExists(MHC_CACHE_DIR); err != nil {
		os.MkdirAll(MHC_CACHE_DIR, os.ModePerm)
	}
}

//http routers
func httpDownload(c *gin.Context) {
	url := c.Query("url")
	fmt.Println(url)
	// "https://dbx3.tyswmp.com/20190501/3BQr6x23/index.m3u8"
	path, err := httpGet(url)
	if err != nil {
		fmt.Println(path, err)
		c.JSON(http.StatusOK, gin.H{"status": -1})
		return
	}
	c.JSON(http.StatusOK, gin.H{"status": 0, "msg": "ok", "path": path})
}

func httpIndex(c *gin.Context) {
	c.HTML(http.StatusOK, "index", gin.H{
		"title": "Api接口测试",
	})
}

func httpFile(c *gin.Context) {
	path := c.Param("path")
	fullPath := fmt.Sprintf("%s%s", MHC_CACHE_DIR, path)
	c.File(fullPath)
}

func createMyRender() multitemplate.Renderer {
	r := multitemplate.NewRenderer()
	r.AddFromFiles("index", "tpl/index.html")
	return r
}

func main() {
	envInit()
	r := gin.Default()
	r.HTMLRender = createMyRender()
	r.GET(fmt.Sprintf("/%s/*path", MHC_CACHE_DIR), httpFile)
	r.GET("/download", httpDownload)
	r.GET("/", httpIndex)
	r.Run(":5050")
}
