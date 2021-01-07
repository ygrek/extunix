/*
From https://gist.github.com/panzi/6856583
// "License": Public Domain
// I, Mathias Panzenböck, place this file hereby into the public domain. Use it at your own risk for whatever you like.
// In case there are jurisdictions that don't support putting things in the public domain you can also consider it to
// be "dual licensed" under the BSD, MIT and Apache licenses, if you want to. This code is trivial anyway. Consider it
// an example on how to get the endian conversion functions on different platforms.
 */

/* Mac OS */

#if defined(EXTUNIX_USE_OSBYTEORDER_H)

#	define htobe16(x) OSSwapHostToBigInt16(x)
#	define htole16(x) OSSwapHostToLittleInt16(x)
#	define be16toh(x) OSSwapBigToHostInt16(x)
#	define le16toh(x) OSSwapLittleToHostInt16(x)

#	define htobe32(x) OSSwapHostToBigInt32(x)
#	define htole32(x) OSSwapHostToLittleInt32(x)
#	define be32toh(x) OSSwapBigToHostInt32(x)
#	define le32toh(x) OSSwapLittleToHostInt32(x)

#	define htobe64(x) OSSwapHostToBigInt64(x)
#	define htole64(x) OSSwapHostToLittleInt64(x)
#	define be64toh(x) OSSwapBigToHostInt64(x)
# define le64toh(x) OSSwapLittleToHostInt64(x)

#endif

/* Windows */

#if defined(EXTUNIX_USE_WINSOCK2_H)

#	if BYTE_ORDER == LITTLE_ENDIAN

#		define htobe16(x) htons(x)
#		define htole16(x) (x)
#		define be16toh(x) ntohs(x)
#		define le16toh(x) (x)

#		define htobe32(x) htonl(x)
#		define htole32(x) (x)
#		define be32toh(x) ntohl(x)
#		define le32toh(x) (x)

#		if defined(__MINGW32__)
#			define htobe64(x) __builtin_bswap64(x)
#			define be64toh(x) __builtin_bswap64(x)
#		else
#			define htobe64(x) htonll(x)
#			define be64toh(x) ntohll(x)
#		endif
#		define htole64(x) (x)
#		define le64toh(x) (x)

#	elif BYTE_ORDER == BIG_ENDIAN

		/* that would be xbox 360 */
#		define htobe16(x) (x)
#		define htole16(x) __builtin_bswap16(x)
#		define be16toh(x) (x)
#		define le16toh(x) __builtin_bswap16(x)

#		define htobe32(x) (x)
#		define htole32(x) __builtin_bswap32(x)
#		define be32toh(x) (x)
#		define le32toh(x) __builtin_bswap32(x)

#		define htobe64(x) (x)
#		define htole64(x) __builtin_bswap64(x)
#		define be64toh(x) (x)
#		define le64toh(x) __builtin_bswap64(x)

#	else

#		error byte order not supported

# endif

#endif

/* various BSD */

#ifndef be16toh
#	define be16toh(x) betoh16(x)
#endif

#ifndef le16toh
#	define le16toh(x) letoh16(x)
#endif

#ifndef be32toh
#	define be32toh(x) betoh32(x)
#endif

#ifndef le32toh
#	define le32toh(x) letoh32(x)
#endif

#ifndef be64toh
#	define be64toh(x) betoh64(x)
#endif

#ifndef le64toh
# define le64toh(x) letoh64(x)
#endif
