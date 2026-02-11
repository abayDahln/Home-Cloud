//go:build windows

package main

import (
	"strings"

	"github.com/shirou/gopsutil/v3/disk"
	"golang.org/x/sys/windows"
)

func getOSDiskLabel(p disk.PartitionStat) string {
	return getWindowsVolumeLabel(p.Mountpoint)
}

func getWindowsVolumeLabel(mountpoint string) string {
	if !strings.HasSuffix(mountpoint, "\\") {
		mountpoint += "\\"
	}

	var (
		volumeName      = make([]uint16, 261)
		fsName          = make([]uint16, 261)
		serialNumber    uint32
		maxComponentLen uint32
		fileSystemFlags uint32
	)

	err := windows.GetVolumeInformation(
		windows.StringToUTF16Ptr(mountpoint),
		&volumeName[0],
		uint32(len(volumeName)),
		&serialNumber,
		&maxComponentLen,
		&fileSystemFlags,
		&fsName[0],
		uint32(len(fsName)),
	)

	if err != nil {
		return ""
	}

	return windows.UTF16ToString(volumeName)
}
