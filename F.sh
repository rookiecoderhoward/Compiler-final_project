bison -d -o y.tab.c F.y
gcc -c -g -I.. y.tab.c
flex -o lex.yy.c F.l
gcc -c -g -I.. lex.yy.c
gcc -o F y.tab.o lex.yy.o -ll


bison -d -o y.tab.c F.y
g++ -c -g -I.. y.tab.c
flex -o lex.yy.c F.l
g++ -c -g -I.. lex.yy.c
g++ -o F y.tab.o lex.yy.o -ll


bison -d -o y.tab.c r.y
gcc -c -g -I.. y.tab.c
flex -o lex.yy.c r.l
gcc -c -g -I.. lex.yy.c
gcc -o r y.tab.o lex.yy.o -ll

