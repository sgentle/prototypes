package main

import (
	"fmt"
	"github.com/PuerkitoBio/goquery"
	"io"
	"log"
	"net/http"
	"os"
	//	"path"
)

func downloadImage(url string, name string) {
	//name := path.Base(url)
	file, err := os.Create(name)
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()

	res, err := http.Get(url)
	if err != nil {
		log.Fatal(err)
	}
	defer res.Body.Close()

	_, err = io.Copy(file, res.Body)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Printf("%s downloaded\n", name)
}

func main() {
	doc, err := goquery.NewDocument("https://github-ranking.com/organizations?page=1")
	if err != nil {
		log.Fatal(err)
	}
	doc.Find("a.list-group-item").Each(func(i int, a *goquery.Selection) {
		href, _ := a.Attr("href")
		img := a.Find("img")
		src, _ := img.Attr("src")
		fmt.Printf("%s %s\n", href[1:]+".png", src)
		downloadImage(src, href[1:]+".png")
	})
}
