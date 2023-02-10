BINARY_NAME = pdftotext++

SRC_DIR = src
TEST_DIR = test
POPPLER_DIR = libs/poppler
UTF8PROC_DIR = libs/utf8proc
GTEST_DIR = libs/gtest

MAIN_BINARY_FILE = $(SRC_DIR)/GitHubActionsMain
TEST_BINARY_FILES = $(basename $(wildcard $(TEST_DIR)/*Test.cpp $(TEST_DIR)/**/*Test.cpp))
HEADER_FILES = $(wildcard $(SRC_DIR)/*.h $(SRC_DIR)/**/*.h)
OBJECT_FILES = $(addsuffix .o, $(basename $(filter-out %Main.cpp %Test.cpp, $(wildcard $(SRC_DIR)/*.cpp $(SRC_DIR)/**/*.cpp))))

CXX = g++ -g -Wall -Wextra -pedantic -std=c++17
#CXX = g++ -O3 -Wall -Wextra -pedantic -std=c++17
# Without the "-Wl,-rpath,$(POPPLER_DIR)/build" part in the next line, libpoppler.so is not found when the tests are executed by Github actions.
LIBS = -I$(POPPLER_DIR) -I$(POPPLER_DIR)/build -I$(POPPLER_DIR)/build/poppler -I$(UTF8PROC_DIR) -L$(POPPLER_DIR)/build -Wl,-rpath,$(POPPLER_DIR)/build -L$(UTF8PROC_DIR)/build -lpoppler -lutf8proc
LIBS_TEST = $(LIBS) -I$(GTEST_DIR)/googletest/include -L $(GTEST_DIR)/build/lib/ -lgtest -lgtest_main -lpthread

CPPLINT_PATH = cpplint.py

.PRECIOUS: %.o
.PHONY: all compile test checkstyle clean install

# ==================================================================================================

all: compile checkstyle test

compile: $(MAIN_BINARY_FILE)

test: $(TEST_BINARY_FILES)
	for T in $(TEST_BINARY_FILES); do ./$$T || exit; done

valgrind: $(TEST_BINARY_FILES)
	for T in $(TEST_BINARY_FILES); do valgrind --leak-check=full ./$$T; done

%Main: %Main.o $(OBJECT_FILES)
	$(CXX) -o $@ $^ $(LIBS)

%Test: %Test.o $(OBJECT_FILES)
	$(CXX) -o $@ $^ $(LIBS_TEST)

%.o: %.cpp $(HEADER_FILES)
	$(CXX) -c $< -o $@ $(LIBS)

%Test.o: %Test.cpp $(HEADER_FILES)
	$(CXX) -c $< -o $@ $(LIBS_TEST)

checkstyle:
	python3 $(CPPLINT_PATH) --repository=$(SRC_DIR) $(SRC_DIR)/*.h $(SRC_DIR)/**/*.h $(SRC_DIR)/*.cpp $(SRC_DIR)/**/*.cpp
	python3 $(CPPLINT_PATH) --repository=$(TEST_DIR) $(TEST_DIR)/*.cpp $(TEST_DIR)/**/*.cpp

clean:
	rm -f *.o **/*.o
	rm -f $(MAIN_BINARY_FILE)
	rm -f $(TEST_BINARY_FILES)
	rm -f core
	rm -f $(TEST_DIR)/*.aux $(TEST_DIR)/**/*.aux
	rm -f $(TEST_DIR)/*.fdb_latexmk $(TEST_DIR)/**/*.fdb_latexmk
	rm -f $(TEST_DIR)/*.fls $(TEST_DIR)/**/*.fls
	rm -f $(TEST_DIR)/*.log $(TEST_DIR)/**/*.log
	rm -f $(TEST_DIR)/*.synctex.gz $(TEST_DIR)/**/*.synctex.gz

install pdftotext: $(MAIN_BINARY_FILE)
	cp $(MAIN_BINARY_FILE) /usr/local/bin/$(BINARY_NAME)

# ==================================================================================================

build-libs: build-poppler build-utf8proc build-gtest

build-poppler:
	@echo "\033[34;1mBuilding poppler ...\033[0m"

	mkdir -p $(POPPLER_DIR)
	cd $(POPPLER_DIR) && git clone https://github.com/freedesktop/poppler.git . && git checkout 065dca3 && mkdir -p build
	cd $(POPPLER_DIR)/build && cmake -DBUILD_GTK_TESTS=OFF -DBUILD_QT5_TESTS=OFF -DBUILD_QT6_TESTS=OFF -DBUILD_CPP_TESTS=OFF -DBUILD_MANUAL_TESTS=OFF -DENABLE_BOOST=OFF -DENABLE_CPP=OFF -DENABLE_GLIB=OFF -DENABLE_GOBJECT_INTROSPECTION=OFF -DENABLE_QT5=OFF -DENABLE_QT6=OFF -DENABLE_LIBCURL=OFF -DRUN_GPERF_IF_PRESENT=OFF -DENABLE_LIBPNG=OFF .. && make poppler

build-utf8proc:
	@echo "\033[34;1mBuilding utf8proc ...\033[0m"

	mkdir -p $(UTF8PROC_DIR)
	cd $(UTF8PROC_DIR) && git clone https://github.com/JuliaStrings/utf8proc.git . && git checkout 1cb28a6 && mkdir -p build
	cd $(UTF8PROC_DIR)/build && cmake .. && make

build-gtest:
	@echo "\033[34;1mBuilding gtest ...\033[0m"

	mkdir -p $(GTEST_DIR)
	cd $(GTEST_DIR) && git clone https://github.com/google/googletest.git . && git checkout b796f7d && mkdir -p build
	cd $(GTEST_DIR)/build && cmake .. && make