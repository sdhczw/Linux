#include <stdio.h>
#include <signal.h>
#include <stdlib.h>
#include <unistd.h>
#include <ac_api.h>
#include <zc_protocol_controller.h>

extern PTC_ProtocolCon  g_struProtocolController;

int main(int argc, char *argv[]){
	WRTnode_Init();
    AC_Init();
    WRTnode_WakeUp();
	//g_struProtocolController.u8MainState = PCT_STATE_ACCESS_NET;
	while (1){
		sleep(1);
	}
	printf("ok");
	return 0;	
}
