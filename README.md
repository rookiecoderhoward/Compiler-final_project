# Mini-LISP interpreter

## 完成功能
### Basic Function：
Syntax Validation   
Print  
Numerical Operations   
Logical Operations   
if Expression  
Variable Definition  


## 未完成功能
### Basic Function：
Function  
Named Function  

### Bonus：
Recursion  
Type Checking -> 只有做檢測四則運算、布林運算  
Nested Function   
First-class Function   


## 程式簡介(思路：使用遞迴)
###### 1.先parse input，建立AST
###### 2.從AST的root往下走，各個node依序traverse，最後call對應的運算op後賦予node數值
###### 3.運算op : 依據每個node的type(e.g. add, or)去做運算並賦值

###### is_boolean : 判斷是否為四則或布林運算，避免混淆運算type  
###### 在create node時，就會先標記 ; 做運算op時還會再double check一次  


## 編譯
bison -d -o y.tab.c F.y  
gcc -c -g -I.. y.tab.c  
flex -o lex.yy.c F.l  
gcc -c -g -I.. lex.yy.c  
gcc -o F y.tab.o lex.yy.o -ll  


## 執行
./F  
