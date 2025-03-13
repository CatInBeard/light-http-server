DEBUG ?= 0

ifeq ($(DEBUG), 1)
    CFLAGS = -g
else
    CFLAGS =
endif

all: main.o server.o helpers.o
	ld -o program main.o server.o helpers.o $(CFLAGS)
main.o:
	as -o main.o main.as $(CFLAGS)
server.o:
	as -o server.o server.as $(CFLAGS)
helpers.o:
	as -o helpers.o helpers.as $(CFLAGS)

clean:
	rm -f *.o program
