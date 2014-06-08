ENTRY(main);
SECTIONS
{
  /* プログラムの開始位置 */ 
  . = 0x7C00;
  .data : { hello.o; }
  /* ブートシグニチャ */
  . = 0x7DFE;
  .sig : { SHORT(0xaa55); }
}

