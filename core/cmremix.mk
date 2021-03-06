# Copyright (C) 2014-2017 UBER
# Copyright (C) 2016-2017 Benzo Rom
# Copyright (C) 2016-2017 CMRemix Rom
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
####################
#  NO OPTIMIZATION #
####################

NO_OPTIMIZATION += camera.msm8084 gps.msm8084 gralloc.msm8084 keystore.msm8084 memtrack.msm8084 hwcomposer.msm8084 audio.primary.msm8084 bluetoothtbd_test libbluetooth_jni bluetooth.mapsapi bluetooth.default bluetooth.mapsapi libbt-brcm_stack audio.a2dp.default libbt-brcm_gki libbt-utils libbt-qcom_sbc_decoder libbt-brcm_bta libbt-brcm_stack libbt-vendor libbtprofile libbtdevice libbtcore bdt bdtest libbt-hci libosi ositests libbluetooth_jni net_test_osi net_test_device net_test_btcore net_bdtool net_hci bdAddrLoader


##########
# FILTER #
##########

  OPT1 := [O3]

CUSTOM_FLAGS := -O3 -g0 -DNDEBUG -fuse-ld=gold
O_FLAGS := -O3 -O2 -Os -O1 -O0 -Og -Oz

# Remove all flags we don't want use high level of optimization
my_cflags := $(filter-out -Wall -Werror -g -Wextra -Weverything $(O_FLAGS),$(my_cflags)) $(CUSTOM_FLAGS)
my_cppflags := $(filter-out -Wall -Werror -g -Wextra -Weverything $(O_FLAGS),$(my_cppflags)) $(CUSTOM_FLAGS)
my_conlyflags := $(filter-out -Wall -Werror -g -Wextra -Weverything $(O_FLAGS),$(my_conlyflags)) $(CUSTOM_FLAGS)

########################
# CMREMIX OPTIMIZATION #
########################

  OPT2 := [misc]

ifeq ($(my_clang),true)
 ifneq ($(strip $(LOCAL_IS_HOST_MODULE)),true)
   ifeq ($(filter $(DISABLE_CMREMIX_OPTIMIZATION), $(LOCAL_MODULE)),)
    my_conlyflags += -pipe -ftree-slp-vectorize -fomit-frame-pointer -ffunction-sections -fdata-sections \
	             -fforce-addr -funroll-loops -ffp-contract=fast -ftree-slp-vectorize -fno-signed-zeros \
                     -freciprocal-math -inline -loop-deletion -ffast-math
    my_ldflags += -Wl,--as-needed -Wl,--gc-sections -Wl,--relax -Wl,--sort-common
  endif
 endif
endif

DISABLE_CMREMIX_OPTIMIZATION := \
    $(NO_OPTIMIZATION)

#######
# IPA #
#######

  OPT3 := [ipa]

ifndef LOCAL_IS_HOST_MODULE
  ifeq (,$(filter true,$(my_clang)))
    ifneq (1,$(words $(filter $(DISABLE_ANALYZER),$(LOCAL_MODULE))))
      my_cflags += -fipa-sra -fipa-pta -fipa-cp -fipa-cp-clone
    endif
  else
    ifneq (1,$(words $(filter $(DISABLE_ANALYZER),$(LOCAL_MODULE))))
      my_cflags += -analyze -analyzer-purge
    endif
  endif
endif

DISABLE_ANALYZER := \
     $(NO_OPTIMIZATION)

###################
# STRICT ALIASING #
###################
ifeq ($(STRICT_ALIASING),true)
  OPT4 := [strict aliasing]
ifeq ($(my_clang),true)
 ifeq (1,$(words $(filter $(DISABLE_STRICT),$(LOCAL_MODULE))))
   my_conlyflags += -fno-strict-aliasing
   my_cppflags += -fno-strict-aliasing
  else
   my_conlyflags += -fstrict-aliasing -Wstrict-aliasing=2 -Werror=strict-aliasing
   my_cppflags += -fstrict-aliasing -Wstrict-aliasing=2 -Werror=strict-aliasing
 endif
else
 ifeq (1,$(words $(filter $(DISABLE_STRICT),$(LOCAL_MODULE))))
   my_conlyflags += -fno-strict-aliasing
   my_cppflags += -fno-strict-aliasing
  else
   my_conlyflags += -fstrict-aliasing -Wstrict-aliasing=3 -Werror=strict-aliasing
   my_cppflags += -fstrict-aliasing -Wstrict-aliasing=3 -Werror=strict-aliasing
  endif
 endif
endif

DISABLE_STRICT := \
	mdnsd \
	$(NO_OPTIMIZATION)

############
# GRAPHITE #
############

GRAPHITE_FLAGS := \
	-fgraphite \
	-fgraphite-identity \
	-floop-flatten \
	-floop-parallelize-all \
	-ftree-loop-linear \
	-floop-interchange \
	-floop-strip-mine \
	-floop-block

# Do not use graphite on host modules or the clang compiler.
ifeq (,$(filter true,$(LOCAL_IS_HOST_MODULE) $(LOCAL_CLANG)))

ifeq ($(GRAPHITE_OPTS),true)
  OPT5 := [graphite]
   ifneq (1,$(words $(filter $(LOCAL_DISABLE_GRAPHITE),$(LOCAL_MODULE))))
    ifdef my_cflags
      my_cflags += $(GRAPHITE_FLAGS)
    else
      my_cflags := $(GRAPHITE_FLAGS)
    endif
    ifdef my_ldflags
      my_ldflags += $(GRAPHITE_FLAGS)
    else
      my_ldflags := $(GRAPHITE_FLAGS)
    endif
   endif
  endif
endif

LOCAL_DISABLE_GRAPHITE := \
    $(NO_OPTIMIZATION)
