package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Go Link Yourself sets GOPATH to a temporary path that symlinks to the current directory")
		fmt.Println("Usage: goly <go command>")
		os.Exit(1)
	}
	tmpdir, err := ioutil.TempDir("", "goly")
	if err != nil {
		log.Fatal("Could not create temporary directory")
	}
	defer os.RemoveAll(tmpdir)

	src := path.Join(tmpdir, "src")

	cwd, err := os.Getwd()
	if err != nil {
		log.Fatal("Could not get current directory")
	}

	linkdir := path.Join(src, path.Base(cwd))
	os.Symlink(path.Join(cwd, "vendor"), src)

	os.Setenv("GOPATH", tmpdir)
	os.Chdir(linkdir)

	cmd := exec.Command("go", os.Args[1:]...)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	err = cmd.Run()
	if err != nil {
		os.Exit(2)
	}
}
