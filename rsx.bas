10 CALL &8000
20 INPUT "width: ",w%
30 INPUT "height: ",h%
40 a%=0
50 |MAZEGEN,w%,h%,@a%
60 PRINT HEX$(a%,4)
70 FOR y=1 TO 16
80 a$=""
90 FOR x=1 to 16
100 v=PEEK(a%) AND 15
110 a$=a$+CHR$(v+144)
120 a%=a%+1
130 NEXT
140 PRINT a$
150 NEXT
