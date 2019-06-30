/*
 * PROGRAM: 	stripnulls.c
 * AUTHOR: 	Erin Maxwell
 * PURPOSE: 	Strip NULL characters (ASCII 0) from files and write output
 * LICENSE:	GPLv3
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#ifdef HAS_GETOPT
#include <unistd.h>
#endif

#ifndef BUFFER
#define BUFFER 8192
#endif

static char *getStr(FILE *fp);

int
main(int argc, char *argv[])
{
    FILE *ifp;
    FILE *ofp;
    char *str;

#ifdef HAS_GETOPT
    int opt;

    while (opt=getopt(argc, argv, "i:o:") != -1) {
	switch(opt) {
	case 'i':
	    if ((ifp=fopen(optarg, "rb")) == NULL) {
		(void)fprintf(stderr, "Can't open input: %s\n", optarg);
		exit(EXIT_FAILURE);
	    }
	    break;
	case 'o':
	    if ((ofp=fopen(optarg, "a")) == NULL) {
		(void)fprintf(stderr, "Can't open output: %s\n", optarg);
		exit(EXIT_FAILURE);
	    }
	    break;
	case '?':
	default:
	    (void)fprintf(stderr, "Usage: %s -i infile -o outfile \n",
			  argv[0]);
	}
    }
    argc -= optind;
    argv += optind;
#else /* ifdef HAS_GETOPT */
    if (argc < 3) {
	(void)fprintf(stderr, "Usage: %s <infile> <outfile>\n", argv[0]);
	exit(EXIT_FAILURE);
    }
    if ((ifp=fopen(argv[1], "rb")) == NULL) {
	(void)fprintf(stderr, "Can't open input: %s\n", argv[1]);
	exit(EXIT_FAILURE);
    }
    if ((ofp=fopen(argv[2], "w")) == NULL) {
	(void)fprintf(stderr, "Can't open output: %s\n", argv[2]);
	exit(EXIT_FAILURE);
    }
#endif /* ifdef HAS_GETOPT */

    while ((str=getStr(ifp))) {
	fprintf(ofp, "%s\n", str);
    }
    (void)fclose(ifp);
    (void)fclose(ofp);

    exit(EXIT_SUCCESS);

}

char *
getStr(FILE *fp)
{
    size_t buffsize = BUFFER;
    char *ptr, *result, *tempptr;
    int ch;

    /* Allocate memory buffer */
    result = (char *)malloc(buffsize);
    if (!result) return 0;	/* failure to allocate */

    ptr=result;

    /* Strip out null (ascii 0) characters */
    do {
	ch = fgetc(fp);
	if (ch == -1) {
	    free(result);
	    return(0);		/* failure */
	}
    } while (!isprint(ch) && (ch != '\x0c'));		/* while not null */

    while (isprint(ch) && (ch != '\x0c')) {
	*ptr++ = ch;

	/* Expand mem buffer if too small */
	if (ptr - result > buffsize) {
	    buffsize = buffsize * 2;
	    tempptr = (char *)realloc(result, buffsize);
	    if (!tempptr) {
		free(result);
		return(0);	/* failure to reallocate */
	    }
	    ptr = tempptr = (ptr - result); /* ptr now invalid */
	    result = tempptr;
	}
	ch = fgetc(fp);
    }

    /* add terminating null */
    *ptr++ = 0;

    /* Shrink mem buffer to desired size */
    result = realloc(result, ptr - result);

    return(result);
}

