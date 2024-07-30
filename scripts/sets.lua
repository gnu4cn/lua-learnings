#!/usr/bin/env lua

local s = [===[

/*
 * Copyright 2018-2019 Senscomm Semiconductor Co., Ltd.	All rights reserved.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <getopt.h>

#include <at.h>
#include <wise_system.h>
#include <sys/termios.h>
#include <sys/ioctl.h>

#include "cli.h"

#ifdef CONFIG_ATCMD_AT
static int at_exec(int argc, char *argv[])
{
	return AT_RESULT_CODE_OK;
}
AT(AT, NULL, NULL, NULL, at_exec);
#endif /* CONFIG_ATCMD_AT */

#ifdef CONFIG_ATCMD_AT_RST
static int at_rst_exec(int argc, char *argv[])
{
	wise_restart(); /* it actually will not return */
	return AT_RESULT_CODE_OK;
}
ATPLUS(RST, NULL, NULL, NULL, at_rst_exec);
#endif /* CONFIG_ATCMD_AT_RST */

#ifdef CONFIG_ATCMD_ATE
static int ate_echo_on(int argc, char *argv[])
{
	at_echo(1);
	return AT_RESULT_CODE_OK;
}

static int ate_echo_off(int argc, char *argv[])
{
	at_echo(0);
	return AT_RESULT_CODE_OK;
}
AT(ATE0, NULL, NULL, NULL, ate_echo_off);
AT(ATE1, NULL, NULL, NULL, ate_echo_on);
#endif /* CONFIG_ATCMD_ATE */

#ifdef CONFIG_ATCMD_AT_UART_CUR
static int at_uart_cur_query(int argc, char *argv[])
{
	struct termios termios;
	int speed, dbits, sbits, par, flow;

	ioctl(STDIN_FILENO, TCGETS, &termios);
	speed = termios.c_ispeed;
	switch (termios.c_cflag & CSIZE) {
	case CS5:
		dbits = 5;
		break;
	case CS6:
		dbits = 6;
		break;
	case CS7:
		dbits = 7;
		break;
	default:
		dbits = 8;
		break;
	}
	if (termios.c_cflag & CSTOPB) {
		if (dbits == 5)
			sbits = 2;
		else
			sbits = 3;
	} else
		sbits = 1;
	if (termios.c_cflag & PARENB)
		par = 1;
	else
		par = 0;
	switch (termios.c_cflag & CRTSCTS) {
	case CRTS_IFLOW:
		flow = 1;
		break;
	case CCTS_OFLOW:
		flow = 2;
		break;
	case CRTSCTS:
		flow = 3;
		break;
	default:
		flow = 0;
		break;
	}
	printf("%s:%d,%d,%d,%d,%d\r\n", argv[0], speed, dbits, sbits, par, flow);
	return AT_RESULT_CODE_OK;
}

static int at_uart_cur_set(int argc, char *argv[])
{
	struct termios termios;
	int speed, dbits, sbits, par, flow;

	speed = atoi(argv[1]);
	dbits = atoi(argv[2]);
	sbits = atoi(argv[3]);
	par = atoi(argv[4]);
	flow = atoi(argv[5]);

	if (ioctl(STDIN_FILENO, TCGETS, &termios))
		goto fail;

	termios.c_ispeed = speed;
	termios.c_cflag &= ~CSIZE;
	switch (dbits) {
	case 5:
		termios.c_cflag |= CS5;
		break;
	case 6:
		termios.c_cflag |= CS6;
		break;
	case 7:
		termios.c_cflag |= CS7;
		break;
	default:
		termios.c_cflag |= CS8;
		break;
	}

	if (sbits > 1)
		termios.c_cflag |= CSTOPB;
	else
		termios.c_cflag &= ~CSTOPB;

	termios.c_cflag &= ~(PARENB | PARODD);
	if (par) {
		termios.c_cflag |= PARENB;
		if (par == 1)
			termios.c_cflag |= PARODD;
	}

	termios.c_cflag &= ~CRTSCTS;
	if (flow & 1)
		termios.c_cflag |= CRTS_IFLOW;
	if (flow & 2)
		termios.c_cflag |= CCTS_OFLOW;

	if (ioctl(STDIN_FILENO, TCSETS, &termios))
		goto fail;

	return AT_RESULT_CODE_OK;

fail:
	return AT_RESULT_CODE_ERROR;
}
ATPLUS(UART_CUR, NULL, at_uart_cur_query, at_uart_cur_set, NULL);
#endif /* CONFIG_ATCMD_AT_UART_CUR */

#ifdef CONFIG_ATCMD_AT_SYSRAM
static int at_sysram_query(int argc, char *argv[])
{
	printf("%s:%d\r\n", argv[0], wise_get_free_heap_size());
	return AT_RESULT_CODE_OK;
}
ATPLUS(SYSRAM, NULL, at_sysram_query, NULL, NULL);
#endif /* CONFIG_ATCMD_AT_SYSRAM */

#if defined(CONFIG_ATCMD_AT_SLEEP) && defined(CONFIG_CMDLINE)
/* FIXME: don't use system().*/
static int at_sleep_set(int argc, char *argv[])
{
	int enable = atoi(argv[1]);
	char cmd[64];

	snprintf(cmd, sizeof(cmd), "ifconfig wlan0 %spowersave", enable ? "" : "-");
	if (system(cmd) != CMD_RET_SUCCESS)
		goto fail;

	snprintf(cmd, sizeof(cmd), "pm %s", enable ? "on" : "off");
	if (system(cmd) != CMD_RET_SUCCESS)
		goto fail;

	return AT_RESULT_CODE_OK;

fail:
	return AT_RESULT_CODE_ERROR;
}
ATPLUS(SLEEP, NULL, NULL, at_sleep_set, NULL);
#endif /* CONFIG_ATCMD_AT_SLEEP */

#if defined(CONFIG_ATCMD_AT_GSLP) && defined(CONFIG_CMDLINE)
/* FIXME: don't use system().*/
static int at_gslp_set(int argc, char *argv[])
{
	int timeout = atoi(argv[1]);
	char cmd[32];

	snprintf(cmd, sizeof(cmd), "pm on deep1 %d", timeout);
	if (system(cmd) != CMD_RET_SUCCESS)
		goto fail;

	return AT_RESULT_CODE_OK;

fail:
	return AT_RESULT_CODE_ERROR;
}
ATPLUS(GSLP, NULL, NULL, at_gslp_set, NULL);
#endif /* CONFIG_ATCMD_AT_GSLP */
]===]


reserved = {
    ["while"] = true, ["if"] = true,
    ["else"] = true, ["do"] = true,
}

for w in string.gmatch(s, "[%a_][%w_]*") do
    if not reserved[w] then
        -- do somthing with 'w'    -- 'w' 不是保留字
    end
end

function Set (list)
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
    return set
end

reserved = Set {"while", "end", "function", "local", }


local ids = {}
for w in string.gmatch(s, "[%a_][%w_]*") do
    if not reserved[w] then
        ids[w] = true
    end
end

-- 每个标识符打印一次
for w in pairs(ids) do print(w) end
