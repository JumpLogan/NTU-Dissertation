import numpy as np
import random
import mod_schemes as mod

m = np.zeros(mod.BUFFER_SIZE, dtype = int)
s = np.zeros(mod.SAMPLE_RANGE)

print("Modulation Scheme: 1.DBPSK  2. DDQPSK  3.16QAM")
num = input("Please input the number:")

print("Original Message:")

for i in range(mod.BUFFER_SIZE):
	m[i] = random.randint(0, 1)
	print(m[i])

print("\n");
 
if int(num) == 1:
	mod.bpsk_mod(m, s, mod.BUFFER_SIZE)
elif int(num) == 2:
	mod.qpsk_mod(m, s, mod.BUFFER_SIZE)
elif int(num) == 3:
	mod.qam16_mod(m, s, mod.BUFFER_SIZE)
else:
	raise ValueError("input error")
 
for i in range(mod.BUFFER_SIZE):
    print(s[i]);

print("\n");