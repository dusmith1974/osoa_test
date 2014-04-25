CXXFLAGS = -DBOOST_ALL_DYN_LINK
CXXFLAGS += -Wall -Wextra -ansi -pedantic -Weffc++ -Wshadow -Werror
CXXFLAGS += -Wno-error=effc++ # for boost and other libs.
CXXFLAGS += -std=c++11

TEST = test
BASE = .
PRJS := $(BASE) $(TEST)

LIB_OSOA_BASE = libosoa-mt
ifeq ($(MAKECMDGOALS), debug)
LIB_OSOA_SUFFIX = -d.a
CONFIG=debug
else
LIB_OSOA_SUFFIX = .a
CONFIG=release
endif
OSOA_DIR=../osoa
LIB_OSOA_DIR=$(OSOA_DIR)/lib/$(CONFIG)
LIB_OSOA=$(LIB_OSOA_DIR)/$(LIB_OSOA_BASE)$(LIB_OSOA_SUFFIX)

OBJ_BASE=lib
OBJ_DIR=$(OBJ_BASE)/$(CONFIG)
BIN_DIR=bin

SRCS := $(foreach prj, $(PRJS), $(wildcard $(prj)/*.cc))
OBJS := $(foreach prj, $(PRJS), $(addprefix $(OBJ_DIR)/, $(patsubst %.cc, %.o, $(subst $(prj)/,,$(wildcard $(prj)/*.cc)))))

VPATH := $(addsuffix :, $(PRJS))
INC := $(addprefix -I, $(PRJS))
INC += -I$(BOOST_DIR)
INC += -I$(OSOA_DIR)

$(OBJ_DIR)/%.o : %.cc 
	$(COMPILE.cc) $(INC) $(OUTPUT_OPTION) $<

all: $(BIN_DIR)/test

debug: CXXFLAGS += -DDEBUG -g -O0
debug: $(BIN_DIR)/test

ifneq ($(MAKECMDGOALS), debug)
CXXFLAGS += -O3 -DNDEBUG
endif

ifeq ($(MAKECMDGOALS),clean)
DEPS=
else
DEPS=$(OBJS:.o=.d)
$(OBJ_DIR)/%.d : %.cc
	$(CXX) $(CXXFLAGS) -MM $(INC) $< |sed -e '1 s/^/obj\//' > $@ 
-include $(DEPS)
endif

$(BIN_DIR)/test: $(OBJS)
	$(LINK.cc) $(OBJS) $(LIB_OSOA) -dynamic -pthread -lboost_program_options -lboost_log_setup -lboost_log -lboost_system -lboost_thread -lboost_date_time -lboost_filesystem $(OUTPUT_OPTION)
	ctags -R --c-kinds=+cdefglmnpstuvx --extra=+f
	cscope -Rb

$(OBJS) $(DEPS) : | $(OBJ_DIR) $(BIN_DIR)

$(OBJ_DIR):
	mkdir -p $(OBJ_DIR)

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

.PHONY: clean
clean :
	rm -f numbers output.log
	rm -rf $(OBJ_BASE) $(BIN_DIR) *.o *.d
