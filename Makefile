TARGET=bin/gpid
SOURCES=$(wildcard src/cpp/*.cpp)
LIBS=-lcsv -linform -lcgraph -lgvc
CXXFLAGS += -std=c++17 -g -Wno-write-strings

all: $(TARGET)

$(TARGET): $(SOURCES)
	mkdir -p bin
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LIBS)


clean:
	rm $(TARGET)

PHONY: clean
