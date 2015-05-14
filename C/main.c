#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define BUFFER_SIZE     1000
#define SAMPLE_RANGE    16000

extern void encodeBPSK(short message[], double signal[], int size);
extern void encodeQPSK(short message[], double signal[], int size);
extern void encode16QAM(short message[], double signal[], int size);

int main(int argc, char *argv[])
{
    short m[BUFFER_SIZE] = {0};
    double s[SAMPLE_RANGE] = {0};
    int i, num;

    printf("Modulation Scheme: 1.DBPSK  2. DDQPSK  3.16QAM\n");
    printf("Please input the number:");
    scanf("%d", &num);
    
    srand((unsigned int)time(0));

    printf("Original Message:\n");
    for(i = 0; i < BUFFER_SIZE; ++i)
    {
        m[i] = rand() % 2;
        printf("%d " , m[i]);
    }
    printf("\n");

	switch (num)
    {
        case 1:encodeBPSK(m, s, BUFFER_SIZE); break;
        case 2:encodeQPSK(m, s, BUFFER_SIZE); break;
        case 3:encode16QAM(m, s, BUFFER_SIZE);break;
        default:{  printf("input error\n");
                   return 0;
                }
    }
	
    for(i = 0; i < BUFFER_SIZE; ++i)
       printf("%f " , s[i]);

    printf("\n");

    return 0;
}
