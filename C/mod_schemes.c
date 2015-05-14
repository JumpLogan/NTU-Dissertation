#include <stdio.h>
#include <stdlib.h>
#include "mod_coff.h"

#define multFact  0.70710678

void fir_filter (double signal[], int size);

extern void encodeBPSK(short message[], double signal[], int size)
{
 double Ik[BUFFER_SIZE];
 double Isam[SAMPLE_RANGE];
 int i, j, Sample_Range;
 short oldI, newI;
 int replicate_carrier;
 short NORMALIZATION = 10;

 Sample_Range = NUM_SAMPLES * size;

 oldI = 1;

 // Returns DBPSK from the input binary data stream
 for(i = 0; i < size; ++i)
 {
    newI = message[i] ^ oldI;
	oldI = newI;

    // Remap to {-1, 1} 0->-1, 1->1
	newI = (newI << 1) - 1;
	Ik[i] = newI;
 }

 j = 0;

 // Up-sample
 for(i = 0; i < Sample_Range; ++i)
 {
   if( i % NUM_SAMPLES == 0 )
   {
     Isam[i] = Ik[j];
     j = j + 1;
   }
  else
     Isam[i] = 0;
 }

 fir_filter( Isam, Sample_Range );

 // Mix with carrier
 for(j = 0; j < Sample_Range; ++j)
 {
   replicate_carrier = j % CARRIER_SIZE;
   signal[j] = Isam[j] * Icarrier[replicate_carrier] * NORMALIZATION;
 }
}

//_____________________________________________________________________________________________________________________________________________________

extern void encodeQPSK(short message[], double signal[], int size)
{
 double Ik[HALF_BUFF_SIZE], Qk[HALF_BUFF_SIZE];
 double Isam[SAMPLE_RANGE], Qsam[SAMPLE_RANGE];
 int i, j, halfsize, Sample_Range;
 short oldI, oldQ, newI, newQ;
 int replicate_carrier;
 short tbc1, tbc2;
 short NORMALIZATION = 10;

 halfsize     = size >> 1;
 Sample_Range = NUM_SAMPLES * halfsize;

 oldI = 1;
 oldQ = 0;

 // Returns the phase shifts for pi/4 DQPSK from the input binary data stream
 for(i = 0; i < halfsize; ++i)
 {
    tbc1 = message[i * 2];
    tbc2 = message[i * 2 + 1];

    if (oldI == oldQ)
    {
		newI = tbc1 ^ oldI;
		newQ = tbc2 ^ oldQ;
	}
	else
	{
		newI = tbc2 ^ oldI;
		newQ = tbc1 ^ oldQ;
	}

    oldI = newI;
    oldQ = newQ;

    //Remap to {-1,1} 0->-1, 1->+1
    newI = (newI << 1) - 1;
	newQ = (newQ << 1) - 1;

	Ik[i] = newI * multFact;
    Qk[i] = newQ * multFact;;
  }

 j = 0;

 // Up-sample
 for(i = 0; i < Sample_Range; ++i)
 {
   if( i % NUM_SAMPLES == 0 )
   {
     Isam[i] = Ik[j];
     Qsam[i] = Qk[j];
     j = j + 1;
   }
  else
     Isam[i] = Qsam[i] = 0;
 }

 fir_filter( Isam, Sample_Range );
 fir_filter( Qsam, Sample_Range );

 // Mix with carrier
 for(j = 0; j < Sample_Range; ++j)
 {
   replicate_carrier = j % CARRIER_SIZE;
   signal[j] = ( Isam[j] * Icarrier[replicate_carrier] + Qsam[j] * Qcarrier[replicate_carrier] ) * NORMALIZATION;
 }
}

//_____________________________________________________________________________________________________________________________________________________

extern void encode16QAM(short message[], double signal[], int size)
{
 double Ik[QUAR_BUFF_SIZE], Qk[QUAR_BUFF_SIZE];
 double Isam[SAMPLE_RANGE], Qsam[SAMPLE_RANGE];
 int i, j, quarsize, Sample_Range;
 short oldI1, oldI2, newI1, newI2;
 int replicate_carrier;
 short tbc1, tbc2, tbc3, tbc4;
 short NORMALIZATION = 10;

 quarsize     = size >> 2;
 Sample_Range = NUM_SAMPLES * quarsize;

 oldI1 = 1;
 oldI2 = 0;

 for(i = 0; i < quarsize; ++i)
 {
    tbc1 = message[i * 2];
    tbc2 = message[i * 2 + 1];
    tbc3 = message[i * 2 + 2];
    tbc4 = message[i * 2 + 3];

    //Only tbc1 and tbc2 using differential coding
    if (oldI1 == oldI2)
    {
		newI1 = tbc1 ^ oldI1;
		newI2 = tbc2 ^ oldI2;
	}
	else
	{
		newI1 = tbc2 ^ oldI1;
		newI2 = tbc1 ^ oldI2;
	}

    oldI1 = newI1;
    oldI2 = newI2;

    //Remap to {-2,-1,1,2} 00->-2, 01->-1, 11->1 10->2
    if (~newI1 & ~newI2)
        Ik[i] = -2;
    if (~newI1 & newI2)
        Ik[i] = -1;
    if (newI1 & newI2)
        Ik[i] = 1;
    if (newI1 & ~newI2)
        Ik[i] = 2;
    if (~tbc3 & ~tbc4)
        Qk[i] = -2;
    if (~tbc3 & tbc4)
        Qk[i] = -1;
    if (tbc3 & tbc4)
        Qk[i] = 1;
    if (tbc3 & ~tbc4)
        Qk[i] = 2;
  }

 j = 0;

 // Up-sample
 for(i = 0; i < Sample_Range; ++i)
 {
   if( i % NUM_SAMPLES == 0 )
   {
     Isam[i] = Ik[j];
     Qsam[i] = Qk[j];
     j = j + 1;
   }
  else
     Isam[i] = Qsam[i] = 0;
 }

 fir_filter( Isam, Sample_Range );
 fir_filter( Qsam, Sample_Range );

 // Mix with carrier
 for(j = 0; j < Sample_Range; ++j)
 {
   replicate_carrier = j % CARRIER_SIZE;
   signal[j] = ( Isam[j] * Icarrier[replicate_carrier] + Qsam[j] * Qcarrier[replicate_carrier] ) * NORMALIZATION;
 }
}

//_____________________________________________________________________________________________________________________________________________________

/* in-place FIR filter */
void fir_filter(double signal[], int size)
{
    double R_in[NUM_TAPS]; 		/* Input samples R_in[0] most recent, R_in[NUM_TAPS-1]  oldest */
    double acc = 0;
    double prod;
    int i, j;

    for(j = 0; j < NUM_TAPS; ++j)
        R_in[j] = 0;

    for(j = 0; j < size; ++j)
      {
	  R_in[0] = signal[j];         		/* Update most recent sample */

	  acc = 0;

	  for (i = 0; i < NUM_TAPS; i++)
	  {
		prod = (bcoeff[i] * R_in[i]);
		acc = acc + prod;
	  }

	  signal[j] = acc;

	  for (i = NUM_TAPS-1; i > 0; i--)         	/* Shift delay samples */
		  R_in[i]=R_in[i-1];
      }
}
