package main

import (
	"encoding/json"
	"fmt"
	"net/http"
)

type Jsonip struct {
	IP string `json: "ip"`
}

func main() {
	url := "http://jsonip.com"
	res, err := http.Get(url)
	if err != nil {
		panic(err)
	}
	defer res.Body.Close()

	result := new(Jsonip)
	json.NewDecoder(res.Body).Decode(result)

	fmt.Printf("IP: %s\n", result.IP)
}
