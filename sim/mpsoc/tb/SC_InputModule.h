#ifndef INMODULE
#define INMODULE

#include <stdio.h>
#include <string.h>
#include <systemc.h>

int numberoflines(char *filename){
	FILE *f;
	char c;
	int lines = 0;

	f = fopen(filename, "r");

	if(f == NULL)
	return 0;

	while((c = fgetc(f)) != EOF)
		if(c == '\n')
			lines++;

	fclose(f);
	return lines;
}

SC_MODULE(inputmodule)
{
	sc_in<sc_logic> clock;
	sc_in<sc_logic> reset;
//	sc_in<sc_lv<16> > address_ip;
	sc_in<sc_lv<8> > address_ip;
//	sc_in<sc_lv<4> > address_ip;
	sc_out<sc_logic> outTx;
//	sc_out<sc_lv<32> > outData;
	sc_out<sc_lv<16> > outData;
//	sc_out<sc_lv<8> > outData;
	sc_in<sc_logic> inCredit;
	void inline TrafficGenerator();

	SC_CTOR(inputmodule):

//$VARIABLES$
	reset("reset"),
 	clock("clock"),
	address_ip("address_ip"),
	outTx("outTx"),
	outData("outData"),
	inCredit("inCredit"){
	SC_CTHREAD(TrafficGenerator, clock.pos());
	}
};



void inline inputmodule::TrafficGenerator(){


	enum State{S1,S2, S3, EndKernel, EndPacket};
	State CurrentState;
	FILE* Input;
	char temp[32];
	unsigned long int CurrentFlit,Target,Size;
	unsigned long int* BigPacket;
	int FlitNumber, NumberofFlits, WaitTime;
	int Index,i,j,k,numlines;
	bool active,packet;
	int n_active = 0;
	packet=false;
//	printf("\n\n\n\t\t\t******** Send APP ****************\n\n\n\n");
	sprintf(temp,"./mpsoc/app/app_endianness.txt");
	numlines=numberoflines(temp);
	printf("\n\n\n\t\t\t******** Number of lines in APP.TXT: %d ****************\n\n\n\n",numlines);
	Input = fopen(temp,"r");
	if(Input != NULL){
		active = true;
		n_active++;
	}
	else{
		active = false;
	}
	outTx = SC_LOGIC_0;
	outData = 0;
	CurrentState = S1;
	FlitNumber = 0;

	while(true){
		 if(reset!=SC_LOGIC_1 && active){
				if(CurrentState == S1){
						outTx = SC_LOGIC_0;
						outData = 0;
						FlitNumber = 0;
                                                wait(1,SC_US);
						CurrentState = S2;
						if(feof(Input)){
							fclose(Input);
							active = false;
							n_active--;
							outTx = SC_LOGIC_0;
							outData = 0;
							if(packet)
								CurrentState = EndPacket;
							else
								CurrentState = EndKernel;
							free(BigPacket);

						}
				}
				if(CurrentState == S2){
					//Target capture
					Target = address_ip.read().to_int();
					FlitNumber++;
					//Size capture
//					Size = numlines;
					Size = numlines*2;
//					Size = numlines*4;
					NumberofFlits = Size + 2; //2 = header + size
					BigPacket=(unsigned long int*)calloc( sizeof(unsigned long int) , NumberofFlits);
					BigPacket[0] = Target;
					BigPacket[1] = Size;
					FlitNumber++;
					///Payload capture
					while(FlitNumber < NumberofFlits){
//						fscanf(Input, "%8X", &CurrentFlit);
						fscanf(Input, "%4X", &CurrentFlit);
						BigPacket[FlitNumber+1] = CurrentFlit;
						fscanf(Input, "%4X", &CurrentFlit);
						BigPacket[FlitNumber] = CurrentFlit;
//						fscanf(Input, "%2X", &CurrentFlit);
//						BigPacket[FlitNumber+3] = CurrentFlit;
//						fscanf(Input, "%2X", &CurrentFlit);
//						BigPacket[FlitNumber+2] = CurrentFlit;
//						fscanf(Input, "%2X", &CurrentFlit);
//						BigPacket[FlitNumber+1] = CurrentFlit;
//						fscanf(Input, "%2X", &CurrentFlit);
//						BigPacket[FlitNumber] = CurrentFlit;
//						FlitNumber++;
						FlitNumber+=2;
//						FlitNumber+=4;
					}
					CurrentState = S3;
					FlitNumber = 0;
				}
				//comeca a transmitir os dados
				if(CurrentState == S3){
					if (inCredit==SC_LOGIC_1){
						if(FlitNumber>=NumberofFlits){
							outTx = SC_LOGIC_0;
							outData = 0;
							if(packet)
								CurrentState = EndPacket;
							else
								CurrentState = EndKernel;
							free(BigPacket);
						}
						else{
							outTx = SC_LOGIC_1;
							outData = BigPacket[FlitNumber];
							FlitNumber++;
                                                        if(FlitNumber == 1000){
                                                            outTx = SC_LOGIC_0;
                                                            wait(1,SC_US);
                                                            outTx = SC_LOGIC_1;
                                                        }

						}
					}
				}
				if(CurrentState == EndKernel){
					fclose(Input);
					active = false;
					n_active--;
					outTx = SC_LOGIC_0;
					outData = 0;
//					printf("\n\n\n\t\t\t******** Wait to send packet ****************\n\n\n\n");
					wait(3,SC_US);
					sprintf(temp,"./mpsoc/app/packet_endianness.txt");
					numlines=numberoflines(temp);
					printf("\n\n\n\t\t\t******** Number of lines in PACKET.TXT: %d ****************\n\n\n\n",numlines);
					Input = fopen(temp,"r");
					if(Input != NULL){
						active = true;
						n_active++;
					}
					else{
						active = false;
					}
					outTx = SC_LOGIC_0;
					outData = 0;
					CurrentState = S1;
					FlitNumber = 0;
					packet=true;
				}
				if(CurrentState == EndPacket){
					fclose(Input);
					active = false;
					n_active--;
					outTx = SC_LOGIC_0;
					outData = 0;
				}
		  }
		wait( clock.value_changed_event());
	}//end while
}

#endif// INMODULE
