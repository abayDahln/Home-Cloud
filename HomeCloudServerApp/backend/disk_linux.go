//go:build linux

package main

import (
	"os"
	"path/filepath"
	"strings"

	"github.com/shirou/gopsutil/v3/disk"
)

func getOSDiskLabel(p disk.PartitionStat) string {
	return getLinuxDiskLabel(p)
}

func getLinuxDiskLabel(p disk.PartitionStat) string {
	labelPath := "/dev/disk/by-label"
	entries, err := os.ReadDir(labelPath)
	if err != nil {
		return ""
	}

	for _, e := range entries {
		link, err := os.Readlink(filepath.Join(labelPath, e.Name()))
		if err != nil {
			continue
		}

		if strings.Contains(link, filepath.Base(p.Device)) {
			return e.Name()
		}
	}
	return ""
}
