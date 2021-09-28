# ply-bbb

This repo builds an eBPF-friendly Linux kernel and the ply dynamic tracing tool for BeagleBone SBCs. It was meant to accompany the presentation on ["ply: lighweight eBPF tracing"](https://sched.co/lAQF) that I gave at the Embedded Linux Conference on October 28, 2021. See the [slides](https://github.com/fvasquez/ply-bbb/blob/main/ply-lightweight-ebpf-tracing.pdf) for details on how this Linux kernel and rootfs were configured.

## Getting started

Start by cloning the repo and its Buildroot submodule:

```console
$ git clone --recursive https://github.com/fvasquez/ply-bbb.git
```

Install all the necessary Buildroot dependencies:

```console
$ sudo apt install sed make binutils build-essential gcc g++ bash patch gzip bzip2 perl tar cpio unzip rsync file bc wget
```

The preceding packages were required to build on Ubuntu 20.04 LTS.

Optionally, to reconfigure the Linux kernel or root filesystem for the target, install `libncurses-dev` as well:

```console
$ sudo apt install libncurses-dev
```

Now configure the image and build it:

```console
$ cd ply-bbb
$ make all
```

The build will take several minutes to complete the first time you run it. When the image is done building look for the following file:

```console
$ ls output/images/sdcard.img
```

This is the bootable image to write to a micoSD card for deployment to a BeagleBone.

## Deploying

To deploy the finished image to a BeagleBone Black and boot it:

* Use balena Etcher to write `ply-bbb/output/images/sdcard.img` out to a microSD card.
* Insert the microSD card into a BeagleBone Black.
* Plug the USB end of a 3-pin FTDI cable into your computer.
* Connect the black (GND), orange (TX) and yellow (RX) wires from a 3-pin FTDI cable to pins 1, 4 and 5 on the BeagleBone Black.
* `$ sudo screen /dev/ttyUSB0 115200`
* Apply power to the BeagleBone Black while holding down the BOOT button (nearest to the microSD slot).
* Log in from the serial console as `root` with a password of `temppwd`.

A serial console is only needed to find the IP address of the BeagleBone Black. SSH offers a better command line and terminal output experience. Alternatively, use `arp-scan` to locate the BeagleBone's IP address if you do not have a USB to serial cable handy.

## Connecting

To SSH into a BeagleBone Black running the deployed image:

* Plug an Ethernet cable from your router or computer into the BeagleBone Black.
* Wait a few seconds for the BeagleBone Black to obtain a dynamic or link-local IP address.
* Run `ifconfig` from the serial console or `arp-scan` from your computer to view the BeagleBone Black's IP address on `eth0`.
* `$ ssh root@<IP address>`
* Enter `temppwd` when prompted for a password.

Upon connecting, you will find yourself in a `$HOME` directory of `/root`. There are several ply scripts installed in this directory to experiment with.

## Examples

The following ply examples were all run on a BeagleBone Black with the preceding `sdcard.img` deployed. Notice that the image comes with Redis installed so that we have a daemon to play with.

Count vfs calls by executable and function:

```console
# ply -c \
>     "dd if=/dev/zero of=/dev/null bs=1 count=100" \
>     'kprobe:vfs_* { @[comm, caller] = count(); }'
ply: active
100+0 records in
100+0 records out
ply: deactivating

@:
{ dd             , vfs_statx }: 1
{ dd             , vfs_fstat }: 1
{ dd             , vfs_readlink }: 1
{ sh             , vfs_read }: 1
{ sh             , vfs_fstat }: 1
{ sh             , vfs_readlink }: 1
{ dd             , vfs_getattr_nosec }: 2
{ dd             , vfs_open }: 3
{ ply            , vfs_write }: 3
{ sh             , vfs_open }: 3
{ sh             , vfs_statx }: 4
{ sh             , vfs_getattr_nosec }: 5
{ dropbear       , vfs_read }: 9
{ dropbear       , vfs_writev }: 9
{ ply            , vfs_read }: 19
{ ply            , vfs_open }: 25
{ dd             , vfs_read }: 101
{ dd             , vfs_write }: 108
```

Count syscalls systemwide by function:

```console
# ply 'k:__se_sys_* { @syscalls[caller] = count(); }'
ply: active
^Cply: deactivating

@syscalls:
{ __se_sys_write }: 2
{ __se_sys_writev }: 2
{ sys_select }: 2
{ __se_sys_bpf }: 4
{ __se_sys_rt_sigaction }: 6
{ __se_sys_close }: 160
{ __se_sys_epoll_wait }: 160
{ __se_sys_perf_event_open }: 169
{ __se_sys_read }: 304
{ sys_brk }: 362
{ sys_ioctl }: 482
{ sys_clock_gettime32 }: 486
{ __se_sys_open }: 653
{ __se_sys_gettimeofday }: 1431
```

Print stack trace on entry to `i2c-transfer`:

```
# ./i2c-stack.ply

	i2c_transfer
	regmap_i2c_write+28
	_regmap_raw_write_impl+1656
	_regmap_bus_raw_write+128
	regmap_write+68
	tps65217_set_bits+104
	tps65217_pmic_set_voltage_sel+116
	_regulator_call_set_voltage_sel+108
	_regulator_do_set_voltage+1156
	regulator_set_voltage_rdev+152
	regulator_do_balance_voltage+824
	regulator_set_voltage_unlocked+220
	regulator_set_voltage+76
	_set_opp_voltage+56
	dev_pm_opp_set_rate+748
	__cpufreq_driver_target+420
	od_dbs_update+316
	dbs_work_handler+48
	process_one_work+500
	worker_thread+80
	kthread+312
	ret_from_fork+20
```

Read size distribution:

```console
# ./read-dist.ply
ply: active
^Cply: deactivating

@:
{ retsize }:
	[   8,   15]	       2 ┤▍                               │
	[  16,   31]	       1 ┤▏                               │
	...
	[ 128,  255]	     172 ┤███████████████████████████████▌│
```

See short-lived processes:

```console
# ./execsnoop.ply &
# ply: active

# /etc/init.d/S50redis stop
(   0) /etc/init.d/S50redis                              0
Stopping redis: (   0) /usr/bin/redis-cli                                0
OK
# /etc/init.d/S50redis start
(   0) /etc/init.d/S50redis                              0
Starting redis: (   0) /sbin/start-stop-daemon                           0
OK
# (1002) /usr/bin/redis-server                             0

# /etc/init.d/S50redis stop
(   0) /etc/init.d/S50redis                              0
Stopping redis: (   0) /usr/bin/redis-cli                                0
OK
# /etc/init.d/S50redis start
(   0) /etc/init.d/S50redis                              0
Starting redis: (   0) /sbin/start-stop-daemon                           0
OK
# (1002) /usr/bin/redis-server                             0

# fg %1
./execsnoop.ply
^Cply: deactivating

execs:
{   270 }: /etc/init.d/S50redis
{   272 }: /etc/init.d/S50redis
{   279 }: /etc/init.d/S50redis
{   281 }: /etc/init.d/S50redis
{   273 }: /sbin/start-stop-daemon
{   282 }: /sbin/start-stop-daemon
{   271 }: /usr/bin/redis-cli
{   280 }: /usr/bin/redis-cli
{   275 }: /usr/bin/redis-server
{   284 }: /usr/bin/redis-server
```

Count TCP I/O by executable and direction:

```console
# ./tcp-send-recv.ply &
# ply: active

# redis-cli --latency
min: 0, max: 5, avg: 1.20 (1025 samples)^C
# fg %1
./tcp-send-recv.ply
^Cply: deactivating

@:
{ dropbear       , recv    }: 32
{ redis-cli      , recv    }: 1025
{ redis-cli      , send    }: 1025
{ redis-server   , send    }: 1025
{ redis-server   , recv    }: 1026
{ dropbear       , send    }: 1041
```

Run LRU simulation using 100k keys and display heap allocation distribution:

```console
# redis-cli flushall
OK
# ./heap-allocs.ply &
# ply: active

# redis-cli --lru-test 100000
7000 Gets/sec | Hits: 880 (12.57%) | Misses: 6120 (87.43%)
7000 Gets/sec | Hits: 2242 (32.03%) | Misses: 4758 (67.97%)
7000 Gets/sec | Hits: 3260 (46.57%) | Misses: 3740 (53.43%)
6750 Gets/sec | Hits: 3797 (56.25%) | Misses: 2953 (43.75%)
7000 Gets/sec | Hits: 4441 (63.44%) | Misses: 2559 (36.56%)
7000 Gets/sec | Hits: 4826 (68.94%) | Misses: 2174 (31.06%)
7000 Gets/sec | Hits: 5154 (73.63%) | Misses: 1846 (26.37%)
7000 Gets/sec | Hits: 5426 (77.51%) | Misses: 1574 (22.49%)
7000 Gets/sec | Hits: 5583 (79.76%) | Misses: 1417 (20.24%)
^C
# fg %1
./heap-allocs.ply
^Cply: deactivating

@:
{ alloc size      }:
	[   0,    1]	       1 ┤                                │
	...
	[  4k,   8k)	    1073 ┤███████████████████▊            │
	[  8k,  16k)	     593 ┤██████████▉                     │
	[ 16k,  32k)	      64 ┤█▏                              │
	[ 32k,  64k)	       2 ┤                                │
	[ 64k, 128k)	       1 ┤                                │
	[128k, 256k)	       1 ┤                                │
	...
	[  4M,   8M)	       3 ┤                                │

heaps:
{ heap-allocs.ply,   424 }: 4841472
{ redis-server   ,   270 }: 8679424
{ redis-cli      ,   425 }: 14528512
```
