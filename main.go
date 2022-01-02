package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"strconv"
	"strings"

	resty "github.com/go-resty/resty/v2"
)

func main() {

	startPage := 1
	lastPage := 100 // some arbitrary number. We will set it later

	// owner := "prabhatsharma"
	// repo := "zinc"

	owner := "prabhatsharma"
	repo := "zinc"
	var stars []Star

	gh_token, tokenPresent := os.LookupEnv("GITHUB_TOKEN")

	if !tokenPresent {
		fmt.Println("GITHUB_TOKEN not found")
		os.Exit(1)
	}

	fmt.Println("DateTime, Date, User")

	for i := startPage; i <= lastPage; i++ {
		// if i == 2 {
		// 	os.Exit(0)
		// }

		baseURL := "https://api.github.com/repos/" + owner + "/" + repo + "/stargazers?page=" + fmt.Sprint(i)

		client := resty.New()

		resp, err := client.R().
			SetHeader("Accept", "application/vnd.github.v3.star+json").
			SetHeader("authorization", "token "+gh_token).
			EnableTrace().
			Get(baseURL)

		if err != nil {
			fmt.Println(err)
		}

		b := resp.Body()

		err = json.Unmarshal(b, &stars)

		if err != nil {
			fmt.Println(err)
		}

		for _, star := range stars {
			fmt.Println(star.StarredAt + ", " + star.StarredAt[:10] + ", " + star.User.Login)
		}

		if i == 1 {
			lastPage = getLastPage(resp.Header())
		}
	}
}

func getLastPage(headers http.Header) int {
	headersList := map[string][]string(headers)
	linkHeader := headersList["Link"][0]
	linkList := strings.Split(linkHeader, ",")
	lastPage := 0
	for _, link := range linkList {
		if strings.Contains(link, "last") {
			lastPageStr := link[strings.Index(link, "page=")+5:]
			lastPageStr = lastPageStr[:strings.Index(lastPageStr, ">")]
			lastPage, _ = strconv.Atoi(lastPageStr)
		}
	}
	return lastPage
}

type Star struct {
	StarredAt string `json:"starred_at"`
	User      User   `json:"user"`
}

type User struct {
	Login string `json:"login"`
}
