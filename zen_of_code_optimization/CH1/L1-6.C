/*
 * *** Listing 1-6 ***
 *
 * Program to calculate the 16-bit checksum of the stream of bytes
 * from the specified file.  Buffers the bytes internally, rather
 * than letting C or DOS do the work, with the time-critical 
 * portion of the code written in optimized assembler.
 */
#include <stdio.h>
#include <fcntl.h>
#include <alloc.h>   /* alloc.h for Borland compilers,
                        malloc.h for Microsoft compilers */

#define BUFFER_SIZE  0x8000   /* 32Kb data buffer */

main(int argc, char *argv[]) {
   int Handle;
   unsigned int Checksum;
   unsigned char *WorkingBuffer;
   int WorkingLength;

   if ( argc != 2 ) {
      printf("usage: checksum filename\n");
      exit(1);
   }

   if ( (Handle = open(argv[1], O_RDONLY | O_BINARY)) == -1 ) {
      printf("Can't open file: %s\n", argv[1]);
      exit(1);
   }

   /* Get memory in which to buffer the data */
   if ( (WorkingBuffer = malloc(BUFFER_SIZE)) == NULL ) {
      printf("Can't get enough memory\n");
      exit(1);
   }

   /* Initialize the checksum accumulator */
   Checksum = 0;

   /* Process the file in 32Kb chunks */
   do {
      if ( (WorkingLength = read(Handle, WorkingBuffer,
            BUFFER_SIZE)) == -1 ) {
         printf("Error reading file %s\n", argv[1]);
         exit(1);
      }
      /* Checksum this chunk if there's anything in it */
      if ( WorkingLength ) {
         ChecksumChunk(WorkingBuffer, WorkingLength, &Checksum);
      }
   } while ( WorkingLength );

   /* Report the result */
   printf("The checksum is: %u\n", Checksum);

   exit(0);
}


