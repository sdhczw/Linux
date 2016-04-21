# Copyright (C) 2009 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#CC = /home/zhangwen/cross/am335xt3/devkit/arm-arago-linux-gnueabi/bin/gcc
#SYSROOT = /home/zhangwen/cross/am335xt3/devkit/arm-arago-linux-gnueabi
#AR = /home/zhangwen/cross/am335xt3/devkit/arm-arago-linux-gnueabi/bin/ar
AR = ar
CC = gcc
LOCAL_PATH := $(shell pwd)
include $(CLEAR_VARS)
LOCAL_C_INCLUDES := -I$(LOCAL_PATH)         \
                    -I$(LOCAL_PATH)/ZC/inc/zc \
                    -I$(LOCAL_PATH)/ZC/inc/aes \
                    -I$(LOCAL_PATH)/ZC/inc/tropicssl \
		    -I$(LOCAL_PATH)/AC/inc
CFLAGS = -O2 -Wall -g -Wunused-variable
LOCAL_LIB = libACDeviceTcp.a
LOCAL_LIBSRC_FILES := ZC/src/zc/zc_bc.c \
                   ZC/src/zc/zc_client_manager.c \
                   ZC/src/zc/zc_cloud_event.c \
                   ZC/src/zc/zc_common.c \
                   ZC/src/zc/zc_configuration.c \
                   ZC/src/zc/zc_message_queue.c \
                   ZC/src/zc/zc_moudle_manager.c \
                   ZC/src/zc/zc_protocol_controller.c \
                   ZC/src/zc/zc_sec_engine.c \
                   ZC/src/zc/zc_timer.c \
                   ZC/src/tropicssl/bignum.c \
                   ZC/src/tropicssl/rsa.c \
                   ZC/src/crc/crc.c \
                   ZC/src/aes/aes_cbc.c \
                   ZC/src/aes/aes_core.c
LOCAL_LIBSRC_OBJECT := ZC/src/zc/zc_bc.o \
                   ZC/src/zc/zc_client_manager.o \
                   ZC/src/zc/zc_cloud_event.o \
                   ZC/src/zc/zc_common.o \
                   ZC/src/zc/zc_configuration.o \
                   ZC/src/zc/zc_message_queue.o \
                   ZC/src/zc/zc_moudle_manager.o \
                   ZC/src/zc/zc_protocol_controller.o \
                   ZC/src/zc/zc_sec_engine.o \
                   ZC/src/zc/zc_timer.o \
                   ZC/src/tropicssl/bignum.o \
                   ZC/src/tropicssl/rsa.o \
                   ZC/src/crc/crc.o \
                   ZC/src/aes/aes_cbc.o \
                   ZC/src/aes/aes_core.o	               
LOCAL_MODULE := Device-Service
LOCAL_SRC_FILES := AC/src/ac_api.c \
		  AC/src/ac_hal.c \
                  zc_wrtnode_adpter.c \
		  main.c
LOCAL_LDLIBS := -L$(SYSROOT)/usr/lib -lpthread
LOCAL_CFLAGS := -DZC_MODULE_VERSION \
                -DZC_MODULE_TYPE \
                -DTEST_ADDR \
                -DZC_MODULE_DEV
include $(BUILD_SHARED_LIBRARY)
LOCAL_PROGUARD_ENABLED:= disabled
all: Makefile $(LOCAL_LIBSRC_OBJECT) $(LOCAL_LIB) $(LOCAL_MODULE)
$(LOCAL_LIBSRC_OBJECT): %.o: %.c
	$(CC) -c $(LOCAL_C_INCLUDES) $(LOCAL_CFLAGS) $^ -o $@
$(LOCAL_LIB): $(LOCAL_LIBOBJS)
	$(AR) cqs $(LOCAL_LIB) $(LOCAL_LIBSRC_OBJECT)
	cp $(LOCAL_LIB) $(LOCAL_PATH)/lib
$(LOCAL_MODULE):
	$(CC) $(CFLAGS) $(LOCAL_CFLAGS) $(LOCAL_SRC_FILES) $(LOCAL_C_INCLUDES) $(LOCAL_LDLIBS) -o $(LOCAL_MODULE) $(LOCAL_LIB)
clean:
	rm -f $(LOCAL_LIBSRC_OBJECT) $(LOCAL_LIB) $(LOCAL_MODULE) AC/src/*.o

