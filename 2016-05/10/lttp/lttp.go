package main

import (
	"fmt"
	"golang.org/x/net/html"
	"log"
	"net/http"
	"net/url"
)

func spider(starturl *url.URL, visited map[string]bool) bool {
	res, err := http.Get(starturl.String())
	if err != nil {
		panic(err)
	}
	defer res.Body.Close()
	// fmt.Printf("Content type: %s\n", res.Header.Get("Content-Type"))
	if res.StatusCode != 200 {
		// fmt.Printf("URL Status %d: %s\n", res.StatusCode, starturl.String())
		return false
	}
	if res.Header.Get("Content-Type") != "text/html; charset=utf-8" {
		// fmt.Printf("URL not html: %s\n", starturl.String())
		return true
	}

	z := html.NewTokenizer(res.Body)

	for {
		tt := z.Next()
		if tt == html.ErrorToken {
			break
		}
		if tt == html.StartTagToken {
			tn, moreAttrs := z.TagName()
			if string(tn) == "a" {
				// fmt.Printf("TAG: %s\n", tn)
				for moreAttrs {
					attr, attrVal, _moreAttrs := z.TagAttr()
					moreAttrs = _moreAttrs
					if string(attr) == "href" {
						u, err := url.Parse(string(attrVal))
						if err != nil {
							log.Println(err)
							continue
						}
						u = starturl.ResolveReference(u)
						if u.Host == "samgentle.com" {
							fmt.Printf("Rewrote external link on %s: %s\n", starturl.String(), attrVal)
							u.Host = "samgentle.dev"
							u.Scheme = "http"
						}
						if u.Host == starturl.Host {
							urlString := u.String()
							// fmt.Printf("LOCAL: %s\n", urlString)
							if visited[urlString] {
								continue
							}
							visited[urlString] = true
							if !spider(u, visited) {
								fmt.Printf("Broken link on %s: %s\n", starturl.String(), urlString)
							}
						} else {
							// fmt.Printf("\tREMOTE: %s\n", u.String())
						}
					}
				}
			}
		}
	}
	return true
}

func main() {
	starturl, err := url.Parse("http://samgentle.dev/")
	if err != nil {
		panic(err)
	}
	visited := make(map[string]bool)
	spider(starturl, visited)
}
