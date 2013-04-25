#line 2 "../inc/stat.h"
/*
 * User-space Unix compatibility API - stat() definitions.
 *
 * Copyright (C) 2010 Yale University.
 * See section "MIT License" in the file LICENSES for licensing terms.
 *
 * Primary author: Bryan Ford
 */

#ifndef PIOS_INC_STAT_H
#define PIOS_INC_STAT_H 1

#include <types.h>

struct stat {
	ino_t		st_ino;		/* File inode number */
	mode_t		st_mode;	/* File access mode */
	off_t		st_size;	/* File size in bytes */
#line 32 "../inc/stat.h"
};

#line 58 "../inc/stat.h"

#define	S_IFMT		0070000		/* type of file mask */
#define	S_IFREG		0010000		/* regular */
#define	S_IFDIR		0020000		/* directory */
#line 69 "../inc/stat.h"

#define S_IFPART	0100000		/* partial file: wait on read at end */
#define S_IFCONF	0200000		/* write/write conflict(s) detected */

#define	S_ISREG(m)	(((m) & S_IFMT) == S_IFREG)	/* regular file */
#define	S_ISDIR(m)	(((m) & S_IFMT) == S_IFDIR)	/* directory */
#line 82 "../inc/stat.h"

int	stat(const char *path, struct stat *statbuf);
int	fstat(int fd, struct stat *statbuf);
#line 93 "../inc/stat.h"

#endif	// !PIOS_INC_STAT_H
