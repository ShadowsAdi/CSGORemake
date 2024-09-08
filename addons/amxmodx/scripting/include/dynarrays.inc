#if defined _dynarrays_included
	#endinput
#endif
#define _dynarrays_included

#include <amxmodx>

#if !defined MAX_DYNMEMORY
	#define MAX_DYNMEMORY	4096
#endif

new any: __DA@Memory[1][MAX_DYNMEMORY];

#if !defined NULL
	#define NULL			0
#endif

#define new[%0]		__DA@Allocate(%0)
#define ref<%0>		__DA@Reference(%0)

#define _$%0[		(__DA@Pointer(%0), __DA@Memory[0][0])[

stock any: __DA@Allocate(size)
{
	if(size > MAX_DYNMEMORY)
	{
		server_print("Run-time error: Tried to dynamically allocate more than %d cells of memory.", MAX_DYNMEMORY);
		return NULL;
	}

	new ptr;

	#emit LOAD.S.pri size 			// Load "size" value into PRI
	#emit SMUL.C 4 					// Multiply it by 4 to get number of bytes
	#emit MOVE.alt 					// Move the value to alt
	#emit LCTRL 2					// Load HEA into PRI
	#emit STOR.S.pri ptr 			// Load HEA into "ptr"
	#emit ADD 						// Add HEA(pri) and size(alt) together
	#emit SCTRL 2 					// Allocate memory by moving the heap pointer

	return ptr;
}

stock __DA@Pointer(any: ptr) 
{
	// This is where the magic happens
	#emit CONST.alt __DA@Memory 	// Get "__DA@Memory"'s header address
	#emit LOAD.S.pri ptr			// Load "ptr" value into PRI
	#emit SUB						// PRI -= ALT / get the distance between the two
	#emit STOR.I 					// Store the distance in the header
}

stock any: __DA@Reference(...)
{
	#emit LOAD.S.pri 12				// Load first param's address
	#emit RETN
}

public __DA@WTFIsThisFunctionDoingHere()
{
	__DA@Memory[0][0] = 0;
}
