/**
******************************************************************************
* @file     zc_wrtnode_adpter.c
* @authors  cxy
* @version  V1.0.0
* @date     10-Sep-2014
* @brief    Event
******************************************************************************
*/
#include <zc_protocol_controller.h>
#include <zc_timer.h>
#include <zc_module_interface.h>
#include <zc_wrtnode_adpter.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <pthread.h>
#include <net/if.h>
#include <sys/ioctl.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <sys/socket.h>
#include <fcntl.h>
#include <stdarg.h> 
#define FirmwarePath "/tmp/AbcloudFrimware" 
extern PTC_ProtocolCon  g_struProtocolController;
PTC_ModuleAdapter g_struWRTnodeAdapter;

MSG_Buffer g_struRecvBuffer;
MSG_Buffer g_struRetxBuffer;
MSG_Buffer g_struClientBuffer;


MSG_Queue  g_struRecvQueue;
MSG_Buffer g_struSendBuffer[MSG_BUFFER_SEND_MAX_NUM];
MSG_Queue  g_struSendQueue;

u8 g_u8MsgBuildBuffer[MSG_BULID_BUFFER_MAXLEN];
u8 g_u8ClientSendLen = 0;

u8 mux_timer_id;

u16 g_u16TcpMss;
u16 g_u16LocalPort;

pthread_t CloudRecv_t;
pthread_t CloudFunc_t;

int FirmwareFd = 0;


typedef struct Timer_env{
    u32 interval;
    u8 id;
} Timer;

u8 g_u8recvbuffer[WRTnode_MAX_SOCKET_LEN];
ZC_UartBuffer g_struUartBuffer;
WRTnode_TimerInfo g_struWRTnodeTimer[ZC_TIMER_MAX_NUM];
pthread_mutex_t g_struTimermutex;
u8  g_u8BcSendBuffer[100];
u32 g_u32BcSleepCount = 100;
struct sockaddr_in struRemoteAddr;

pthread_attr_t timerattr;

/*************************************************
* Function: WRTnode_ReadDataFormFlash
* Description: 
* Author: cxy 
* Returns: 
* Parameter: 
* History:
*************************************************/
void WRTnode_ReadDataFormFlash(u8 *pu8Data, u16 u16Len) 
{
	int fd_read;
	int R_size = 0;
    u32 u32MagicFlag = 0xFFFFFFFF;
    

    fd_read = open("/tmp/ablecloud", O_RDONLY | O_CREAT, S_IRWXU);
    if(fd_read < 0)
    {
        pu8Data[0] = (rand()% 26) + 65;
    	printf("open /tmp/ablecloud fail\n"); 
        close(fd_read);
        return;
    }
	R_size = lseek(fd_read, sizeof(ZC_ConfigDB)-4, SEEK_SET);
    if(R_size < 0)
    {
        pu8Data[0] = (rand()% 26) + 65;
		printf("lseek mtd fail\n");
        close(fd_read);
        return;
	}
    R_size = read(fd_read, (char *)(pu8Data), u16Len);

    if(R_size < 0)
    {
        pu8Data[0] = (rand()% 26) + 65;
		printf("read mtd fail\n");
	}
	close(fd_read);
	return ;
}

/*************************************************
* Function: WRTnode_WriteDataToFlash
* Description: 
* Author: cxy 
* Returns: 
* Parameter: 
* History:
*************************************************/
void WRTnode_WriteDataToFlash(u8 *pu8Data, u16 u16Len)
{
	int fd_write ;

	fd_write = open("/tmp/ablecloud", O_WRONLY | O_CREAT, S_IRWXU);
	write(fd_write, pu8Data, u16Len);
	close(fd_write);
	return ;

#if 0
    WRTnodeuflash_erase_page(0,1); 

    WRTnodeuflash_write(0, (char*)pu8Data, u16Len);
#endif
	return ;
}

/*************************************************
* Function: WRTnode_timer_callback
* Description: 
* Author: cxy 
* Returns: 
* Parameter: 
* History:
*************************************************/
void * WRTnode_timer_callback(void * arg)
{
	u32 u32Interval;
	pthread_mutex_lock(&g_struTimermutex);
	u8 id = mux_timer_id;
	u32Interval = g_struWRTnodeTimer[id].interval;
	pthread_mutex_unlock(&g_struTimermutex);

	//printf("timer :%d start! interval : %d\n", id, u32Interval);
	while(1)
	{
		usleep(u32Interval * 1000); // dan wei shi ms
		TIMER_TimeoutAction(id);
		TIMER_StopTimer(id);
	}

	//printf("timer :%d stop!\n",id);
}
#if 0
void *WRTnode_timer_callback(u32 count)
{
	u8 u8TimeId = 0;
	u8 u8TimerIndex = 0;

	TIMER_FindIdleTimer(&u8TimerIndex);

	while(1)
	{
		if(g_struWRTnodeTimer[u8TimerIndex].exit_flag == 1)
		{
			g_struWRTnodeTimer[u8TimerIndex].exit_flag = 0;
			break ;
		}
		usleep(count);

		TIMER_TimeoutAction(u8TimeId);
        TIMER_StopTimer(u8TimeId);
		WRTnode_timer_callback(u8TimeId);
	}

}
#endif
/*************************************************
* Function: WRTnode_StopTimer
* Description: 
* Author: cxy 
* Returns: 
* Parameter: 
* History:
*************************************************/
void WRTnode_StopTimer(u8 u8TimerIndex)
{
	void *status;
#if 0
    WRTnodetimer_stop(g_struWRTnodeTimer[u8TimerIndex].struHandle);
    WRTnodetimer_delete(g_struWRTnodeTimer[u8TimerIndex].struHandle);
#endif
	//pthread_mutex_lock(&g_struTimermutex);
	//printf("shop timer %d\n", u8TimerIndex);
	//pthread_join(g_struWRTnodeTimer[u8TimerIndex].struHandle, NULL);
	if (g_struWRTnodeTimer[u8TimerIndex].struHandle != 0)
    	pthread_cancel(g_struWRTnodeTimer[u8TimerIndex].struHandle);
}

/*************************************************
* Function: WRTnode_SetTimer
* Description: 
* Author: cxy 
* Returns: 
* Parameter: 
* History:
*************************************************/
u32 WRTnode_SetTimer(u8 u8Type, u32 u32Interval, u8 *pu8TimeIndex)
{
    u8 u8TimerIndex;
    u32 u32Retval;
    u32Retval = TIMER_FindIdleTimer(&u8TimerIndex);
    if (ZC_RET_OK == u32Retval)
    {
        TIMER_AllocateTimer(u8Type, u8TimerIndex, (u8*)&g_struWRTnodeTimer[u8TimerIndex]);
		pthread_mutex_lock(&g_struTimermutex);
		g_struWRTnodeTimer[u8TimerIndex].exit_flag = 0;
		g_struWRTnodeTimer[u8TimerIndex].interval = u32Interval;
		g_struWRTnodeTimer[u8TimerIndex].u32FirstFlag = 1;
		mux_timer_id = u8TimerIndex;
		//printf("id : %d, inetval: %d\n", u8TimerIndex, g_struWRTnodeTimer[u8TimerIndex].interval);
		if(pthread_create(&g_struWRTnodeTimer[u8TimerIndex].struHandle, NULL, WRTnode_timer_callback, NULL) == -1){
			printf("fail to create timer");
			pthread_mutex_unlock(&g_struTimermutex);
			return ;
		}

        *pu8TimeIndex = u8TimerIndex;
		pthread_mutex_unlock(&g_struTimermutex);
    }
    return u32Retval;
}
/*************************************************
* Function: WRTnode_FirmwareUpdateFinish
* Description: 
* Author: cxy 
* Returns: 
* Parameter: 
* History:
*************************************************/
u32 WRTnode_FirmwareUpdateFinish(u32 u32TotalLen)
{
	
#if 0
    int retval;
    retval = WRTnodeupdate_complete(WRTnodeUPDATE_SW, u32TotalLen);
    if (WRTnode_SUCCESS == retval)
    {
        return ZC_RET_OK;
    }
    else
    {
        return ZC_RET_ERROR;    
    }
#endif
	close(FirmwareFd);
	system("/etc/init.d/AbleCloud restart");
	return ZC_RET_OK;
}


/*************************************************
* Function: WRTnode_FirmwareUpdate
* Description: 
* Author: cxy 
* Returns: 
* Parameter: 
* History:
*************************************************/
u32 WRTnode_FirmwareUpdate(u8 *pu8FileData, u32 u32Offset, u32 u32DataLen)
{
	
    int retval;
#if 0
    int retval;
    if (0 == u32Offset)
    {
        WRTnodeupdate_start(WRTnodeUPDATE_SW);
    }
    
    retval = WRTnodeupdate_write_file(WRTnodeUPDATE_SW, u32Offset, (char *)pu8FileData, u32DataLen); 
    if (retval < 0)
    {
        return ZC_RET_ERROR;
    }
#endif
    if (0 == u32Offset){
		FirmwareFd = open(FirmwarePath, O_WRONLY|O_CREAT);
	}

	if(FirmwareFd < 0){
			printf("open /tmp/AbcloudFrimware fail!\n ");
			return -1;
	}

	lseek(FirmwareFd,u32Offset,SEEK_SET);
	retval = write(FirmwareFd,pu8FileData,u32DataLen);
 	   
    return ZC_RET_OK;
}
/*************************************************
* Function: WRTnode_SendDataToMoudle
* Description: 
* Author: cxy 
* Returns: 
* Parameter: 
* History:
*************************************************/
u32 WRTnode_SendDataToMoudle(u8 *pu8Data, u16 u16DataLen)
{
#ifdef ZC_MODULE_DEV
    AC_RecvMessage((ZC_MessageHead *)pu8Data);
#else
    u8 u8MagicFlag[4] = {0x02,0x03,0x04,0x05};
    //send(WRTnodeUART0,(char*)u8MagicFlag,4,1000); 
    //send(WRTnodeUART0,(char*)pu8Data,u16DataLen,1000);
#endif	
    return ZC_RET_OK;

}

/*************************************************
* Function: WRTnode_Rest
* Description: 
* Author: cxy 
* Returns: 
* Parameter: 
* History:
*************************************************/
void WRTnode_Rest(void)
{
	return ;
}
/*************************************************
* Function: WRTnode_SendTcpData
* Description: 
* Author: cxy 
* Returns: 
* Parameter: 
* History:
*************************************************/
void WRTnode_SendTcpData(u32 u32Fd, u8 *pu8Data, u16 u16DataLen, ZC_SendParam *pstruParam)
{
    send(u32Fd, pu8Data, u16DataLen, 0);
}
/*************************************************
* Function: WRTnode_SendUdpData
* Description: 
* Author: cxy 
* Returns: 
* Parameter: 
* History:
*************************************************/
void WRTnode_SendUdpData(u32 u32Fd, u8 *pu8Data, u16 u16DataLen, ZC_SendParam *pstruParam)
{
    sendto(u32Fd,(char*)pu8Data,u16DataLen,0,
        (struct sockaddr *)pstruParam->pu8AddrPara,
        sizeof(struct sockaddr_in)); 
}

/*************************************************
* Function: WRTnode_CloudRecvfunc
* Description: 
* Author: cxy 
* Returns: 
* Parameter: 
* History:
*************************************************/
static void *WRTnode_CloudRecvfunc(void* arg) 
{
    s32 s32RecvLen=0; 
    fd_set fdread;
    u32 u32Index;
    u32 u32Len=0; 
    u32 u32ActiveFlag = 0;
    struct sockaddr_in cliaddr;
    int connfd;
    extern u8 g_u8ClientStart;
    u32 u32MaxFd = 0;
    struct timeval timeout; 
    struct sockaddr_in addr;
    int tmp=1;    

    
    while(1) 
    {
        ZC_StartClientListen();

        u32ActiveFlag = 0;
        
        timeout.tv_sec= 0; 
        timeout.tv_usec= 1000; 
        
        FD_ZERO(&fdread);

        FD_SET(g_Bcfd, &fdread);
        u32MaxFd = u32MaxFd > (u32)g_Bcfd ? u32MaxFd : (u32)g_Bcfd;
        
        usleep(5000);
        if (PCT_INVAILD_SOCKET != g_struProtocolController.struClientConnection.u32Socket)
        {
            FD_SET(g_struProtocolController.struClientConnection.u32Socket, &fdread);
            u32MaxFd = u32MaxFd > g_struProtocolController.struClientConnection.u32Socket ? u32MaxFd : g_struProtocolController.struClientConnection.u32Socket;
            u32ActiveFlag = 1;
        }
        
        if ((g_struProtocolController.u8MainState >= PCT_STATE_WAIT_ACCESSRSP) 
        && (g_struProtocolController.u8MainState < PCT_STATE_DISCONNECT_CLOUD))
        {
            FD_SET(g_struProtocolController.struCloudConnection.u32Socket, &fdread);
            u32MaxFd = u32MaxFd > g_struProtocolController.struCloudConnection.u32Socket ? u32MaxFd : g_struProtocolController.struCloudConnection.u32Socket;
            u32ActiveFlag = 1;
        }


        for (u32Index = 0; u32Index < ZC_MAX_CLIENT_NUM; u32Index++)
        {
            if (0 == g_struClientInfo.u32ClientVaildFlag[u32Index])
            {
                FD_SET(g_struClientInfo.u32ClientFd[u32Index], &fdread);
                u32MaxFd = u32MaxFd > g_struClientInfo.u32ClientFd[u32Index] ? u32MaxFd : g_struClientInfo.u32ClientFd[u32Index];
                u32ActiveFlag = 1;            
            }
        }


        if (0 == u32ActiveFlag)
        {
            continue;
        }
        
        select(u32MaxFd + 1, &fdread, NULL, NULL, &timeout);
        
        if ((g_struProtocolController.u8MainState >= PCT_STATE_WAIT_ACCESSRSP) 
        && (g_struProtocolController.u8MainState < PCT_STATE_DISCONNECT_CLOUD))
        {
            if (FD_ISSET(g_struProtocolController.struCloudConnection.u32Socket, &fdread))
            {
                s32RecvLen = recv(g_struProtocolController.struCloudConnection.u32Socket, g_u8recvbuffer, WRTnode_MAX_SOCKET_LEN, 0); 
                
                if(s32RecvLen > 0) 
                {
                    printf("recv data len = %d\n", s32RecvLen);
                    MSG_RecvDataFromCloud(g_u8recvbuffer, s32RecvLen);
                }
                else
                {
                    printf("recv error, len = %d\n",s32RecvLen);
                    PCT_DisConnectCloud(&g_struProtocolController);
                    
                    g_struUartBuffer.u32Status = MSG_BUFFER_IDLE;
                    g_struUartBuffer.u32RecvLen = 0;
                }
            }
            
        }

        
        for (u32Index = 0; u32Index < ZC_MAX_CLIENT_NUM; u32Index++)
        {
            if (0 == g_struClientInfo.u32ClientVaildFlag[u32Index])
            {
                if (FD_ISSET(g_struClientInfo.u32ClientFd[u32Index], &fdread))
                {
                    s32RecvLen = recv(g_struClientInfo.u32ClientFd[u32Index], g_u8recvbuffer, WRTnode_MAX_SOCKET_LEN, 0); 
                    if (s32RecvLen > 0)
                    {
                        ZC_RecvDataFromClient(g_struClientInfo.u32ClientFd[u32Index], g_u8recvbuffer, s32RecvLen);
                    }
                    else
                    {   
                        ZC_ClientDisconnect(g_struClientInfo.u32ClientFd[u32Index]);
                        close(g_struClientInfo.u32ClientFd[u32Index]);
                    }
                    
                }
            }
            
        }

        if (PCT_INVAILD_SOCKET != g_struProtocolController.struClientConnection.u32Socket)
        {
            if (FD_ISSET(g_struProtocolController.struClientConnection.u32Socket, &fdread))
            {
                connfd = accept(g_struProtocolController.struClientConnection.u32Socket,(struct sockaddr *)&cliaddr,&u32Len);

                if (ZC_RET_ERROR == ZC_ClientConnect((u32)connfd))
                {
                    close(connfd);
                }
                else
                {
                    printf("accept client = %d\n", connfd);
                }
            }
        }

        if (FD_ISSET(g_Bcfd, &fdread))
        {
            tmp = sizeof(addr); 
            s32RecvLen = recvfrom(g_Bcfd, g_u8BcSendBuffer, 100, 0, (struct sockaddr *)&addr, (socklen_t*)&tmp); 
            if(s32RecvLen > 0) 
            {
                ZC_SendClientQueryReq(g_u8BcSendBuffer, (u16)s32RecvLen);
            } 
        }
    } 
}
/*************************************************
* Function: WRTnode_GetMac
* Description: 
* Author: cxy 
* Returns: 
* Parameter: 
* History:
*************************************************/
void WRTnode_GetMac(u8 *pu8Mac)
{
	struct ifreq ifreq;
	int sock = 0;
	char mac[32] = "";
	strcpy(ifreq.ifr_name,"eth0");
	sock = socket(AF_INET,SOCK_STREAM,0);
	if(sock < 0)
	{
		perror("error sock");
		return ;
	}

	if(ioctl(sock,SIOCGIFHWADDR,&ifreq) < 0)
	{
		perror("error ioctl");
		return ;
	}
	int i = 0;
	for(i = 0; i < 6; i++){
		sprintf(mac+2*i, "%02X", (unsigned char)ifreq.ifr_hwaddr.sa_data[i]);
	}
		
	memcpy(pu8Mac, mac, 12);
	//pu8Mac[12] = 0;
	printf("MAC:%s\n", mac);

}

/*************************************************
* Function: WRTnode_Reboot
* Description: 
* Author: cxy 
* Returns: 
* Parameter: 
* History:
*************************************************/
void WRTnode_Reboot(void)
{
#if 0
    WRTnodesys_reset();
#endif
}

/*************************************************
* Function: WRTnode_ConnectToCloud
* Description: 
* Author: cxy 
* Returns: 
* Parameter: 
* History:
*************************************************/
u32 WRTnode_ConnectToCloud(PTC_Connection *pstruConnection)
{
    int fd; 
    struct sockaddr_in addr;
    int retval;
    u16 port;
	struct hostent *host;   //by lijp
    memset((char*)&addr,0,sizeof(addr));
    if (1 == g_struZcConfigDb.struSwitchInfo.u32ServerAddrConfig)
    {
        port = g_struZcConfigDb.struSwitchInfo.u16ServerPort;
		addr.sin_addr.s_addr = htonl(g_struZcConfigDb.struSwitchInfo.u32ServerIp);
        retval = WRTnode_SUCCESS;
    }
    else
    {
        port = ZC_CLOUD_PORT;
        host = gethostbyname((const char *)g_struZcConfigDb.struCloudInfo.u8CloudAddr);
		if (host != NULL){
			retval = WRTnode_SUCCESS;
			memcpy(&addr.sin_addr, host->h_addr_list[0], host->h_length);
		}
    }

    if (WRTnode_SUCCESS != retval)
    {
        return ZC_RET_ERROR;
    }
    
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    fd = socket(AF_INET, SOCK_STREAM, 0);

    if(fd<0)
        return ZC_RET_ERROR;
    
    if (connect(fd, (struct sockaddr *)&addr, sizeof(struct sockaddr_in))< 0)
    {
        close(fd);
        if(g_struProtocolController.struCloudConnection.u32ConnectionTimes++>20)
        {
           g_struZcConfigDb.struSwitchInfo.u32ServerAddrConfig = 0;
        }

        return ZC_RET_ERROR;
    }
    g_struProtocolController.struCloudConnection.u32ConnectionTimes = 0;

    printf("connect ok!\n");
    g_struProtocolController.struCloudConnection.u32Socket = fd;

    
    ZC_Rand(g_struProtocolController.RandMsg);

    return ZC_RET_OK;
}
/*************************************************
* Function: WRTnode_ConnectToCloud
* Description: 
* Author: cxy 
* Returns: 
* Parameter: 
* History:
*************************************************/
u32 WRTnode_ListenClient(PTC_Connection *pstruConnection)
{
    int fd; 
    struct sockaddr_in servaddr;

    fd = socket(AF_INET, SOCK_STREAM, 0);
    if(fd<0)
        return ZC_RET_ERROR;

    bzero(&servaddr,sizeof(servaddr));
    servaddr.sin_family = AF_INET;
    servaddr.sin_addr.s_addr=htonl(INADDR_ANY);
    servaddr.sin_port = htons(pstruConnection->u16Port);
    if(bind(fd,(struct sockaddr *)&servaddr,sizeof(servaddr))<0)
    {
        close(fd);
        return ZC_RET_ERROR;
    }
    
    if (listen(fd,TCP_DEFAULT_LISTEN_BACKLOG)< 0)
    {
        close(fd);
        return ZC_RET_ERROR;
    }

    printf("Tcp Listen Port = %d\n", pstruConnection->u16Port);
    g_struProtocolController.struClientConnection.u32Socket = fd;

	return ZC_RET_OK;
}

void WRTnode_Printf(const char *pu8format, ...)
{
	char buffer[100 + 1]={0};
	va_list arg;
	va_start(arg, pu8format);
	vsnprintf(buffer, 100, pu8format, arg);
	va_end(arg);
}
/*************************************************
* Function: WRTnode_BcInit
* Description: 
* Author: cxy 
* Returns: 
* Parameter: 
* History:
*************************************************/
void WRTnode_BcInit()
{
    int tmp=1;
	int ret;
    struct sockaddr_in addr; 

    addr.sin_family = AF_INET; 
    addr.sin_port = htons(ZC_MOUDLE_PORT); 
    addr.sin_addr.s_addr=htonl(INADDR_ANY);

    g_Bcfd = socket(AF_INET, SOCK_DGRAM, 0); 

    tmp=1; 
    ret = setsockopt(g_Bcfd, SOL_SOCKET, SO_BROADCAST, &tmp, sizeof(tmp)); 
	printf("Bcfd = %d, ret = %d\n", g_Bcfd, ret);
    //WRTnodenet_set_udp_broadcast_port_valid(ZC_MOUDLE_PORT, ZC_MOUDLE_PORT + 1);

    //bind(g_Bcfd, (struct sockaddr*)&addr, sizeof(addr)); 
    g_struProtocolController.u16SendBcNum = 0;

	bzero(&addr, sizeof(struct sockaddr_in));
    struRemoteAddr.sin_family = AF_INET; 
    struRemoteAddr.sin_port = htons(ZC_MOUDLE_BROADCAST_PORT); 
    struRemoteAddr.sin_addr.s_addr=htonl(INADDR_BROADCAST); 
    g_pu8RemoteAddr = (u8*)&struRemoteAddr;
    g_u32BcSleepCount = 180;
	return;
}

/*************************************************
* Function: WRTnode_Cloudfunc
* Description: 
* Author: cxy 
* Returns: 
* Parameter: 
* History:
*************************************************/
static void *WRTnode_Cloudfunc(void* arg) 
{
    int fd;
    u32 u32Timer = 0;

    WRTnode_BcInit();

    while(1) 
    {
        fd = g_struProtocolController.struCloudConnection.u32Socket;
        PCT_Run();
        
        if (PCT_STATE_DISCONNECT_CLOUD == g_struProtocolController.u8MainState)
        {
            close(fd);
            u32Timer = rand();
            u32Timer = (PCT_TIMER_INTERVAL_RECONNECT) * (u32Timer % 10 + 1);
            PCT_ReconnectCloud(&g_struProtocolController, u32Timer);
            g_struUartBuffer.u32Status = MSG_BUFFER_IDLE;
            g_struUartBuffer.u32RecvLen = 0;
        }
        else
        {
            MSG_SendDataToCloud((u8*)&g_struProtocolController.struCloudConnection);
        }
        ZC_SendBc();
	usleep(5000);
    } 
}

/*************************************************
* Function: WRTnode_Init
* Description: 
* Author: cxy 
* Returns: 
* Parameter: 
* History:
*************************************************/
void WRTnode_Init()
{
	u8 u8Mac[ZC_SERVER_MAC_LEN] = {0};
    printf("MT Init\n");
    g_struWRTnodeAdapter.pfunConnectToCloud = WRTnode_ConnectToCloud;
    g_struWRTnodeAdapter.pfunListenClient = WRTnode_ListenClient;
    g_struWRTnodeAdapter.pfunSendTcpData = WRTnode_SendTcpData;   
    g_struWRTnodeAdapter.pfunUpdate = WRTnode_FirmwareUpdate;     
    g_struWRTnodeAdapter.pfunUpdateFinish = WRTnode_FirmwareUpdateFinish;
    g_struWRTnodeAdapter.pfunSendToMoudle = WRTnode_SendDataToMoudle;  
    g_struWRTnodeAdapter.pfunSetTimer = WRTnode_SetTimer;   
    g_struWRTnodeAdapter.pfunStopTimer = WRTnode_StopTimer;
    
    g_struWRTnodeAdapter.pfunRest = WRTnode_Rest;
    g_struWRTnodeAdapter.pfunReadFlash = WRTnode_ReadDataFormFlash;
    g_struWRTnodeAdapter.pfunWriteFlash = WRTnode_WriteDataToFlash;
    g_struWRTnodeAdapter.pfunSendUdpData = WRTnode_SendUdpData;   
    g_struWRTnodeAdapter.pfunGetMac = WRTnode_GetMac;
    g_struWRTnodeAdapter.pfunReboot = WRTnode_Reboot;


	//add new
	g_struWRTnodeAdapter.pfunFree = free;
	g_struWRTnodeAdapter.pfunMalloc = (pFunMalloc)malloc;
	g_struWRTnodeAdapter.pfunPrintf = (pFunPrintf)printf;
    
    g_u16TcpMss = 1000;
    PCT_Init(&g_struWRTnodeAdapter);

    g_struUartBuffer.u32Status = MSG_BUFFER_IDLE;
    g_struUartBuffer.u32RecvLen = 0;
    //by lijp
    //WRTnodethread_create(WRTnode_Cloudfunc,"WRTnode_Cloudfunc",256,NULL,WRTnodeTHREAD_PRIORITIES_LOW,NULL,NULL); 
    //WRTnodethread_create(WRTnode_CloudRecvfunc,"WRTnode_CloudRecvfunc",256,NULL,WRTnodeTHREAD_PRIORITIES_LOW,NULL,NULL); 
	pthread_create(&CloudFunc_t, NULL, (void *)WRTnode_Cloudfunc, NULL);
	pthread_create(&CloudRecv_t, NULL, (void *)WRTnode_CloudRecvfunc, NULL);
    //WRTnodethread_mutex_new(&g_struTimermutex);
	pthread_mutex_init(&g_struTimermutex,NULL);
	// by lijp
	//WRTnode_ReadDataFormFlash();
}

/*************************************************
* Function: WRTnode_WakeUp
* Description: 
* Author: cxy 
* Returns: 
* Parameter: 
* History:
*************************************************/
void WRTnode_WakeUp()
{
    PCT_WakeUp();
    if(PCT_STATE_INIT==g_struProtocolController.u8MainState)
    {
        g_struZcConfigDb.struDeviceInfo.u32UnBcFlag = 0xffffffff;
    }
}
/*************************************************
* Function: WRTnode_Sleep
* Description: 
* Author: cxy 
* Returns: 
* Parameter: 
* History:
*************************************************/
void WRTnode_Sleep()
{
#if 0
    u32 u32Index;
    
    close(g_Bcfd);

    if (PCT_INVAILD_SOCKET != g_struProtocolController.struClientConnection.u32Socket)
    {
        close(g_struProtocolController.struClientConnection.u32Socket);
        g_struProtocolController.struClientConnection.u32Socket = PCT_INVAILD_SOCKET;
    }

    if (PCT_INVAILD_SOCKET != g_struProtocolController.struCloudConnection.u32Socket)
    {
        close(g_struProtocolController.struCloudConnection.u32Socket);
        g_struProtocolController.struCloudConnection.u32Socket = PCT_INVAILD_SOCKET;
    }
    
    for (u32Index = 0; u32Index < ZC_MAX_CLIENT_NUM; u32Index++)
    {
        if (0 == g_struClientInfo.u32ClientVaildFlag[u32Index])
        {
            close(g_struClientInfo.u32ClientFd[u32Index]);
            g_struClientInfo.u32ClientFd[u32Index] = PCT_INVAILD_SOCKET;
        }
    }

    PCT_Sleep();
    
    g_struUartBuffer.u32Status = MSG_BUFFER_IDLE;
    g_struUartBuffer.u32RecvLen = 0;
#endif
}

/******************************* FILE END ***************************/
