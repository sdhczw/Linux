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
#CC = /home/noel/mroot/openwrt/trunk/staging_dir/toolchain-mipsel_24kec+dsp_gcc-4.8-linaro_uClibc-0.9.33.2/bin/mipsel-openwrt-linux-uclibc-gcc
CC = gcc
LOCAL_PATH := $(shell pwd)
include $(CLEAR_VARS)
LOCAL_C_INCLUDES := -I$(LOCAL_PATH)/         \
					          -I$(LOCAL_PATH)/ZC/inc/zc \
                    -I$(LOCAL_PATH)/ZC/inc/aes \
                    -I$(LOCAL_PATH)/ZC/inc/tropicssl \
					          -I$(LOCAL_PATH)/AC/inc
LOCAL_MODULE    := Device-Service
LOCAL_SRC_FILES := zc_wrtnode_adpter.o \
				           AC/src/ac_api.o \
				           AC/src/ac_hal.o \
                   ZC/src/zc/zc_bc.o \
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
                   ZC/src/aes/aes_core.o \
				   main.o
LOCAL_LDLIBS := -L$(SYSROOT)/usr/lib -lpthread
LOCAL_CFLAGS := -DZC_MODULE_VERSION \
                -DZC_MODULE_TYPE \
                -DTEST_ADDR \
                -DZC_MODULE_DEV
LOCAL_EXPORT_CFLAGS := -DZC_MODULE_VERSION \
                       -DZC_MODULE_TYPE \
                       -DTEST_ADDR \
                       -DZC_MODULE_DEV
include $(BUILD_SHARED_LIBRARY)
LOCAL_PROGUARD_ENABLED:= disabled
all: Makefile $(LOCAL_MODULE)
$(LOCAL_MODULE): $(LOCAL_SRC_FILES)
	$(CC) $(LOCAL_CFLAGS) $(LOCAL_SRC_FILES) $(LOCAL_LDLIBS) -o $(LOCAL_MODULE)
%.o: %.c
	$(CC) -c $(LOCAL_C_INCLUDES) $(LOCAL_CFLAGS) $^ -o $@

clean:
	rm -f ZC/src/zc/*.o ZC/src/tropicssl/*.o ZC/src/aes/*.o ZC/src/crc/*.o ac/*.o *.o $(LOCAL_MODULE)
