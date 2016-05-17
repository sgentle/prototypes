package main

import (
	"fmt"
	"golang.org/x/net/html"
	"gopkg.in/fatih/set.v0"
	"log"
	"net/http"
	"net/url"
	"os"
)

type result struct {
	from string
	to   string
}

func spider(thisurl *url.URL, fromurl *url.URL, results chan<- result, done chan<- bool, visited *set.Set) {
	res, err := http.Get(thisurl.String())
	if err != nil {
		fmt.Printf("URL error: %s\n", err.Error())
		done <- false
		if fromurl != nil {
			results <- result{from: fromurl.String(), to: thisurl.String()}
		}
		return
	}
	defer res.Body.Close()
	// fmt.Printf("Content type: %s\n", res.Header.Get("Content-Type"))
	if res.StatusCode != 200 {
		fmt.Printf("URL Status %d: %s\n", res.StatusCode, thisurl.String())
		done <- false
		if fromurl != nil {
			results <- result{from: fromurl.String(), to: thisurl.String()}
		}
		return
	}
	if res.Header.Get("Content-Type") != "text/html; charset=utf-8" {
		fmt.Printf("URL not html: %s\n", thisurl.String())
		done <- true
		return
	}
	if fromurl != nil && thisurl.Host != fromurl.Host {
		fmt.Printf("URL is remote: %s\n", thisurl.String())
		done <- true
		return
	}

	z := html.NewTokenizer(res.Body)

	//waits := make([]<-chan bool)
	childrenDone := make(chan bool, 5)
	waiting := 0

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
						childurl := thisurl.ResolveReference(u)
						urlString := childurl.String()
						// fmt.Printf("LOCAL: %s\n", urlString)
						if visited.Has(urlString) {
							continue
						}
						visited.Add(urlString)
						//thisWait := make(<-chan bool)
						go spider(childurl, thisurl, results, childrenDone, visited)
						//waits = append(waits, thisWait)
						waiting++
					}
				}
			}
		}
	}
	for range childrenDone {
		waiting--
		if waiting == 0 {
			break
		}
	}
	done <- true
}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: lttp <url>")
		os.Exit(1)
	}
	baseurl, err := url.Parse(os.Args[1])
	if err != nil {
		panic(err)
	}
	visited := set.New()
	results := make(chan result)
	done := make(chan bool)
	go spider(baseurl, nil, results, done, visited)
	go func() {
		for thisresult := range results {
			fmt.Printf("Broken link: %s -> %s\n", thisresult.from, thisresult.to)
		}
	}()
	<-done
}
