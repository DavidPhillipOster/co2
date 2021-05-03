all: co2

CC=gcc
OBJS=../common/hid/hid.o ../common/holtekco2/holtekco2.o
INCLUDES=-I../common/hid -I../common/holtekco2
LIBS=-framework IOKit -framework CoreFoundation

co2: $(OBJS) co2.c
	$(CC) $(INCLUDES) -Wall -g $^ $(LIBS) -o co2

$(OBJS): %.o: %.c
	$(CC) $(INCLUDES) -Wall -g -c $< -o $@

clean:
	rm -f *.o co2 $(OBJS)

.PHONY: clean
