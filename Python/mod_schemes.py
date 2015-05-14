import numpy as np
import mod_coff as coff
from scipy import signal

BUFFER_SIZE    = 1000   # The size of the buffer 
HALF_BUFF_SIZE = 500    # Half of the message buffer
QUAR_BUFF_SIZE = 250    # Quarter of the message buffer
CARRIER_SIZE   = 8      # The size of the carrier for each period
NUM_SAMPLES    = 16     # The number of samples
SAMPLE_RANGE   = 16000  # The size of modulated signal
NORMALIZATION  = 10

def bpsk_mod(message, s, size):
	
	Ik = np.zeros(BUFFER_SIZE, dtype=int)
	Isam = np.zeros(SAMPLE_RANGE, dtype=int)
	Sample_Range = NUM_SAMPLES * size
	oldI = 1
	
	for i in range(size):
		
		newI = message[i] ^ oldI
		oldI = newI
		
		# Re-map to {-1, 1} 0->-1, 1->1
		newI = (newI << 1) - 1
		Ik[i] = newI
		
	j = 0
	
	# Up-sample
	for i in range(Sample_Range):
		
		if i % NUM_SAMPLES == 0:
			Isam[i] = Ik[j]
			j = j+1
		else:
			Isam[i] = 0
			
	y = signal.lfilter(coff.bcoeff, 1, Isam, axis=-1)
	
	# Mix with carrier
	for j in range(Sample_Range):
		
		replicate_carrier = j % CARRIER_SIZE
		s[j] = y[j] * coff.Icarrier[replicate_carrier] * NORMALIZATION
	
def qpsk_mod(message, s, size):
	
	Ik = np.zeros(HALF_BUFF_SIZE)
	Qk = np.zeros(HALF_BUFF_SIZE)
	Isam = np.zeros(SAMPLE_RANGE)
	Qsam = np.zeros(SAMPLE_RANGE)
	
	halfsize = size >> 1
	Sample_Range = NUM_SAMPLES * halfsize
	
	oldI = 1
	oldQ = 0
	multFact = 0.70710678
	
	for i in range(halfsize):
		
		tbc1 = message[i * 2]
		tbc2 = message[i * 2 + 1]
    	    	
		if oldI == oldQ:
			newI = tbc1 ^ oldI
			newQ = tbc2 ^ oldQ
		else:
			newI = tbc2 ^ oldI
			newQ = tbc1 ^ oldQ

		oldI = newI
		oldQ = newQ
		
		# Re-map to {-1, 1} 0->-1, 1->1
		newI = (newI << 1) - 1
		newQ = (newQ << 1) - 1
		
		Ik[i] = newI * multFact
		Qk[i] = newQ * multFact
		
	j = 0
	
	# Up-sample
	for i in range(Sample_Range):
		
		if i % NUM_SAMPLES == 0:
			Isam[i] = Ik[j]
			Qsam[i] = Qk[j]
			j = j+1
		else:
			Isam[i] = Qsam[i] = 0
			
	yI = signal.lfilter(coff.bcoeff, 1, Isam, axis=-1)
	yQ = signal.lfilter(coff.bcoeff, 1, Qsam, axis=-1)
	
	# Mix with carrier
	for j in range(Sample_Range):
		
		replicate_carrier = j % CARRIER_SIZE
		s[j] = (yI[j] * coff.Icarrier[replicate_carrier] + yQ[j] * coff.Qcarrier[replicate_carrier]) * NORMALIZATION	
		
def qam16_mod(message, s, size):
	
	Ik = np.zeros(QUAR_BUFF_SIZE, dtype=int)
	Qk = np.zeros(QUAR_BUFF_SIZE, dtype=int)
	Isam = np.zeros(SAMPLE_RANGE, dtype=int)
	Qsam = np.zeros(SAMPLE_RANGE, dtype=int)
	
	quarsize = size >> 2
	Sample_Range = NUM_SAMPLES * quarsize
	
	oldI1 = 1
	oldI2 = 0
		
	for i in range(quarsize):
		
		tbc1 = message[i * 2]
		tbc2 = message[i * 2 + 1]
		tbc3 = message[i * 2 + 2]
		tbc4 = message[i * 2 + 3]
    	    	
		if oldI1 == oldI2:
			newI1 = tbc1 ^ oldI1
			newI2 = tbc2 ^ oldI2
		else:
			newI1 = tbc2 ^ oldI1
			newI2 = tbc1 ^ oldI2

		oldI1 = newI1
		oldI2 = newI2
		
		# Re-map to {-2,-1,1,2} 00->-2, 01->-1, 11->1 10->2
		if ~newI1 & ~newI2:
			Ik[i] = -2
		if ~newI1 & newI2:
			Ik[i] = -1
		if newI1 & newI2:
			Ik[i] = 1
		if newI1 & ~newI2:
			Ik[i] = 2
		if ~tbc3 & ~tbc4:
			Qk[i] = -2
		if ~tbc3 & tbc4:
			Qk[i] = -1
		if tbc3 & tbc4:
			Qk[i] = 1
		if tbc3 & ~tbc4:
			Qk[i] = 2
		
	j = 0
	
	# Up-sample
	for i in range(Sample_Range):
		
		if i % NUM_SAMPLES == 0:
			Isam[i] = Ik[j]
			Qsam[i] = Qk[j]
			j = j+1
		else:
			Isam[i] = Qsam[i] = 0
			
	yI = signal.lfilter(coff.bcoeff, 1, Isam, axis=-1)
	yQ = signal.lfilter(coff.bcoeff, 1, Qsam, axis=-1)
	
	# Mix with carrier
	for j in range(Sample_Range):
		
		replicate_carrier = j % CARRIER_SIZE
		s[j] = (yI[j] * coff.Icarrier[replicate_carrier] + yQ[j] * coff.Qcarrier[replicate_carrier]) * NORMALIZATION				
	