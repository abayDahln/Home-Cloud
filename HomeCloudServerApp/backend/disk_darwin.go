//go:build darwin

package main

import (
	"path/filepath"

	"github.com/shirou/gopsutil/v3/disk"
)

func getOSDiskLabel(p disk.PartitionStat) string {
	return filepath.Base(p.Mountpoint)
}
