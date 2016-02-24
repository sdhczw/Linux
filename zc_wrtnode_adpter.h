/**
******************************************************************************
* @file     zc_wrtnode_adpter.h
* @authors  cxy
* @version  V1.0.0
* @date     10-Sep-2014
* @brief    HANDSHAKE
******************************************************************************
*/

#ifndef  __ZC_WRTNODE_ADPTER_H__ 
#define  __ZC_WRTNODE_ADPTER_H__

#include "zc_common.h"
#include "zc_protocol_controller.h"
#include "zc_module_interface.h"
#include <pthread.h>
#define  TCP_DEFAULT_LISTEN_BACKLOG  10
#define  WRTnode_SUCCESS  0



typedef struct 
{
    u32 u32FirstFlag;
    //hftimer_handle_t struHandle; //by lijp
	pthread_t struHandle; //by lijp
	int exit_flag;
	u32 interval;
}WRTnode_TimerInfo;


#define WRTnode_MAX_SOCKET_LEN    (1000)

#ifdef __cplusplus
extern "C" {
#endif
void WRTnode_Init(void);
void WRTnode_WakeUp(void);
void WRTnode_Sleep(void);
void WRTnode_WriteDataToFlash(u8 *pu8Data, u16 u16Len);
#ifdef __cplusplus
}
#endif
#endif

/******************************* FILE END ***********************************/

