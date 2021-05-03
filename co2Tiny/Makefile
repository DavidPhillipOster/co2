all: co2tiny

CC=gcc
OBJS=../common/hid/hid.o ../common/holtekco2/holtekco2.o
INCLUDES=-I../common/hid -I../common/holtekco2
LIBS=-framework IOKit -framework CoreFoundation

co2tiny: $(OBJS) co2tiny.c
	$(CC) $(INCLUDES) -Wall -g $^ $(LIBS) -o co2tiny

$(OBJS): %.o: %.c
	$(CC) $(INCLUDES) -Wall -g -c $< -o $@

clean:
	rm -f *.o co2tiny $(OBJS)

.PHONY: clean
