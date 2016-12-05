all: make run
cleanmake: clean make run
make:
	g++ -c *.cpp -std=c++11 -Wall -g
	g++ -o run.exe *.o -std=c++11

run:
	./run.exe

clean:
	rm *.o
	#rm *.gch
	rm *.exe