/* See LICENSE file for copyright and license details. */
#include <limits.h>
#include <stdio.h>

#include "../slstatus.h"
#include "../util.h"

#if defined(__linux__)
	#include <stdint.h>

	#define NET_RX_BYTES "/sys/class/net/%s/statistics/rx_bytes"
	#define NET_TX_BYTES "/sys/class/net/%s/statistics/tx_bytes"

	const char *
	netspeed_rx(const char *interface)
	{
		uintmax_t oldrxbytes;
		static uintmax_t rxbytes;
		extern const unsigned int interval;
		char path[PATH_MAX];

		oldrxbytes = rxbytes;

		if (esnprintf(path, sizeof(path), NET_RX_BYTES, interface) < 0)
			return NULL;
		if (pscanf(path, "%ju", &rxbytes) != 1)
			return NULL;
		if (oldrxbytes == 0)
			return NULL;

		return fmt_human((rxbytes - oldrxbytes) * 1000 / interval,
		                 1024);
	}

	const char *
	netspeed_tx(const char *interface)
	{
		uintmax_t oldtxbytes;
		static uintmax_t txbytes;
		extern const unsigned int interval;
		char path[PATH_MAX];

		oldtxbytes = txbytes;

		if (esnprintf(path, sizeof(path), NET_TX_BYTES, interface) < 0)
			return NULL;
		if (pscanf(path, "%ju", &txbytes) != 1)
			return NULL;
		if (oldtxbytes == 0)
			return NULL;

		return fmt_human((txbytes - oldtxbytes) * 1000 / interval,
		                 1024);
	}

	const char *
	netspeed_combined(const char *interface)
	{
		uintmax_t oldrxbytes, oldtxbytes;
		static uintmax_t rxbytes, txbytes;
		extern const unsigned int interval;
		char path[PATH_MAX];
		double tx_mbps, rx_mbps;

		oldrxbytes = rxbytes;
		oldtxbytes = txbytes;

		if (esnprintf(path, sizeof(path), NET_RX_BYTES, interface) < 0)
			return NULL;
		if (pscanf(path, "%ju", &rxbytes) != 1)
			return NULL;

		if (esnprintf(path, sizeof(path), NET_TX_BYTES, interface) < 0)
			return NULL;
		if (pscanf(path, "%ju", &txbytes) != 1)
			return NULL;

		if (oldrxbytes == 0 || oldtxbytes == 0)
			return NULL;

		/* 计算速度：字节/秒 -> Mbps (乘以 8 转换为 bits，除以 1000000 转换为 Mbps) */
		tx_mbps = (double)(txbytes - oldtxbytes) * 8.0 * 1000.0 / interval / 1000000.0;
		rx_mbps = (double)(rxbytes - oldrxbytes) * 8.0 * 1000.0 / interval / 1000000.0;

		return bprintf("%.02f/%.02f Mbps", tx_mbps, rx_mbps);
	}
#elif defined(__OpenBSD__) | defined(__FreeBSD__)
	#include <ifaddrs.h>
	#include <net/if.h>
	#include <string.h>
	#include <sys/types.h>
	#include <sys/socket.h>

	const char *
	netspeed_rx(const char *interface)
	{
		struct ifaddrs *ifal, *ifa;
		struct if_data *ifd;
		uintmax_t oldrxbytes;
		static uintmax_t rxbytes;
		extern const unsigned int interval;
		int if_ok = 0;

		oldrxbytes = rxbytes;

		if (getifaddrs(&ifal) < 0) {
			warn("getifaddrs failed");
			return NULL;
		}
		rxbytes = 0;
		for (ifa = ifal; ifa; ifa = ifa->ifa_next)
			if (!strcmp(ifa->ifa_name, interface) &&
			   (ifd = (struct if_data *)ifa->ifa_data))
				rxbytes += ifd->ifi_ibytes, if_ok = 1;

		freeifaddrs(ifal);
		if (!if_ok) {
			warn("reading 'if_data' failed");
			return NULL;
		}
		if (oldrxbytes == 0)
			return NULL;

		return fmt_human((rxbytes - oldrxbytes) * 1000 / interval,
		                 1024);
	}

	const char *
	netspeed_tx(const char *interface)
	{
		struct ifaddrs *ifal, *ifa;
		struct if_data *ifd;
		uintmax_t oldtxbytes;
		static uintmax_t txbytes;
		extern const unsigned int interval;
		int if_ok = 0;

		oldtxbytes = txbytes;

		if (getifaddrs(&ifal) < 0) {
			warn("getifaddrs failed");
			return NULL;
		}
		txbytes = 0;
		for (ifa = ifal; ifa; ifa = ifa->ifa_next)
			if (!strcmp(ifa->ifa_name, interface) &&
			   (ifd = (struct if_data *)ifa->ifa_data))
				txbytes += ifd->ifi_obytes, if_ok = 1;

		freeifaddrs(ifal);
		if (!if_ok) {
			warn("reading 'if_data' failed");
			return NULL;
		}
		if (oldtxbytes == 0)
			return NULL;

		return fmt_human((txbytes - oldtxbytes) * 1000 / interval,
		                 1024);
	}

	const char *
	netspeed_combined(const char *interface)
	{
		struct ifaddrs *ifal, *ifa;
		struct if_data *ifd;
		uintmax_t oldrxbytes, oldtxbytes;
		static uintmax_t rxbytes, txbytes;
		extern const unsigned int interval;
		int if_ok = 0;
		double tx_mbps, rx_mbps;

		oldrxbytes = rxbytes;
		oldtxbytes = txbytes;

		if (getifaddrs(&ifal) < 0) {
			warn("getifaddrs failed");
			return NULL;
		}
		rxbytes = 0;
		txbytes = 0;
		for (ifa = ifal; ifa; ifa = ifa->ifa_next)
			if (!strcmp(ifa->ifa_name, interface) &&
			   (ifd = (struct if_data *)ifa->ifa_data)) {
				rxbytes += ifd->ifi_ibytes;
				txbytes += ifd->ifi_obytes;
				if_ok = 1;
			}

		freeifaddrs(ifal);
		if (!if_ok) {
			warn("reading 'if_data' failed");
			return NULL;
		}
		if (oldrxbytes == 0 || oldtxbytes == 0)
			return NULL;

		/* 计算速度：字节/秒 -> Mbps (乘以 8 转换为 bits，除以 1000000 转换为 Mbps) */
		tx_mbps = (double)(txbytes - oldtxbytes) * 8.0 * 1000.0 / interval / 1000000.0;
		rx_mbps = (double)(rxbytes - oldrxbytes) * 8.0 * 1000.0 / interval / 1000000.0;

		return bprintf("%.02f/%.02f Mbps", tx_mbps, rx_mbps);
	}
#endif
