#!/usr/bin/env bash

######################################################################
# SSD TRIM
######################################################################
# Not meant to be run directly - sourced by build_ubuntu.sh, after
# util.sh.
#
# When a file is deleted, the filesystem marks its blocks free but
# doesn't tell the underlying SSD - unlike a spinning disk, an SSD
# can't overwrite a block in place, so it has to erase before
# rewriting, and not knowing which blocks are actually free means it
# may end up erase-cycling ones that hold nothing but old, deleted
# data. TRIM (the ATA/NVMe "discard" command) is how the filesystem
# tells the drive those blocks are free, so it can skip them - fstrim
# does this in a batch sweep rather than continuously (Ubuntu defaults
# to weekly, via fstrim.timer), which is kinder to the drive than
# discarding on every single delete (the `discard` mount option).
######################################################################

# Ubuntu ships fstrim.timer enabled by default (runs fstrim.service
# weekly), but this makes that explicit instead of relying on it
# silently staying that way - same reasoning as enable_apparmor in
# lib/security.sh. Only meaningful on SSDs/NVMe, where letting
# discarded blocks pile up untrimmed degrades write performance over
# time; harmless (a no-op in practice) on spinning disks, which don't
# support the underlying TRIM/discard operation.
enable_fstrim() {
  sudo systemctl enable --now fstrim.timer
}
