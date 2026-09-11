# $PostgreSQL: pgsql/contrib/plpgsql_check/Makefile

MODULE_big = plpgsql_check
OBJS = $(patsubst %.c,%.o,$(wildcard src/*.c))
DATA = plpgsql_check--2.10.sql
EXTENSION = plpgsql_check

ifndef MAJORVERSION
MAJORVERSION := $(basename $(VERSION))
endif

REGRESS_OPTS = --dbname=$(PL_TESTDB)

# This fork ships plpgsql_check.disable_dynamic_sql_check enabled by default,
# while the regression suite covers the dynamic SQL checks it turns off. Clear
# the option for the test run only - the runtime default stays untouched.
export PGOPTIONS := $(PGOPTIONS) -c plpgsql_check.disable_dynamic_sql_check=off

REGRESS = plpgsql_check_passive\
		plpgsql_check_active\
		plpgsql_check_active-$(MAJORVERSION)\
		plpgsql_check_passive-$(MAJORVERSION)\
		plpgsql_check_profiler\
		plpgsql_pragma_generator\
		plpgsql_check_nocrash

ifdef NO_PGXS
subdir = contrib/plpgsql_check
top_builddir = ../..
include $(top_builddir)/src/Makefile.global
include $(top_srcdir)/contrib/contrib-global.mk
else
PG_CONFIG ?= pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
endif

# Work around GCC LTO ICEs seen during PGXS shared library links on some toolchains.
override CFLAGS := $(filter-out -flto=% -flto -ffat-lto-objects,$(CFLAGS))
override LDFLAGS := $(filter-out -flto=% -flto -ffat-lto-objects,$(LDFLAGS))

# temorary fix of compilation with gcc 15
override CFLAGS += -fno-lto -Wno-error=incompatible-pointer-types -I$(top_builddir)/src/pl/plpgsql/src -Wall -g
override LDFLAGS += -fno-lto

plpgsql_check.typedefs: $(OBJS)
	./typedefs_gen.py

pgindent: plpgsql_check.typedefs
	pgindent --typedefs=plpgsql_check.typedefs src/*.c src/*.h
