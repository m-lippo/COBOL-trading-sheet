      ****************************************************************
       IDENTIFICATION DIVISION.
      ****************************************************************
       PROGRAM-ID.   TRADING9.
       AUTHOR.       MATHEUS.
       DATE-WRITTEN. 07/04/2025.
      ****************************************************************
       ENVIRONMENT DIVISION.
      ****************************************************************
       CONFIGURATION SECTION.
       SPECIAL-NAMES. DECIMAL-POINT IS COMMA.
      ****************************************************************
       DATA DIVISION.
      ****************************************************************
       WORKING-STORAGE SECTION.
      ****************************************************************

       77  WS-BALANCE             PIC  9(05)V99.
       77  WS-FINAL               PIC  X(10).
       77  WS-USD-BRL-RATIO       PIC  9(03)V99.
       01  WS-INPUT.
           03  WS-DATE.
               05  WS-YEAR        PIC  XXXX.
               05  WS-MONTH       PIC  XX.
               05  WS-DAY         PIC  XX.
           03                     PIC  X(01).
           03  WS-MARKET          PIC  X(06)    VALUE SPACES.
           03                     PIC  X(01).
           03  WS-TAKE-PROFIT-X.
               05  WS-TAKE-PROFIT PIC  9(03)V99 VALUE ZEROS.
           03                     PIC  X(01).
           03  WS-STOP-LOSS-X.
               05  WS-STOP-LOSS   PIC  9(03)V99 VALUE ZEROS.
           03                     PIC  X(01).
           03  WS-RESULT-VALUE    PIC  S9(03)V99 VALUE ZEROS
                                  SIGN IS LEADING SEPARATE CHARACTER.
           03                     PIC  X(01).
           03  WS-CURRENCY        PIC  X(03).
               88  US-DOLLAR      VALUE     'USD'.
               88  BR-REAL        VALUE     'BRL'.
      *--> MASK VARIABLES
       01  WS-MASK.
           03  WS-TAKE-PROFIT-MASK  PIC  999,99.
           03  WS-STOP-LOSS-MASK    PIC  999,99.
           03  WS-RESULT-VALUE-MASK PIC  +999,99.
           03  WS-RR-RATIO-MASK     PIC  999,99.
           03  WS-BALANCE-MASK      PIC  ZZ999,99.
           03  WS-DATE-MASK         PIC  X(10)   VALUE SPACES.
      *--------------------------------------------------------------
       01  WS-GROUP-CALC.
           03  AC-TRADE-ID        PIC  9(04)    VALUE ZEROS.
           03  WS-RR-RATIO        PIC  9(03)V99.
           03  WS-STOP-LOSS-NEG   PIC  S9(03)V99 VALUE ZEROS.
           03  WS-TYPE-CODE       PIC  X(03)    VALUE SPACES.
       01  WS-BRL-TO-USD-VALUES.
           03  WS-USD-STOP-LOSS   PIC  9(03)V99 VALUE ZEROS.
           03  WS-USD-TAKE-PROFIT PIC  9(03)V99 VALUE ZEROS.
           03  WS-USD-RESULT-VALUE PIC S9(03)V99 VALUE ZEROS.
       01  TB-2DIM.
           03  TB-AREA.
               05  FILLER         PIC  X(32) VALUE
                   'FTR WINFUT WDOFUT USA500 AUS200'.
               05  FILLER         PIC  X(32) VALUE
                   'ETF QQQ    IVVB11 FOMO11 HASH11'.
               05  FILLER         PIC  X(32) VALUE
                   'STK APPLUS NVDAUS PETR4  VALE3 '.
           03  TB-AREA-RED REDEFINES TB-AREA OCCURS 03 TIMES
                                  INDEXED BY I.
               05  TB-TYPE        PIC  X(03).
               05                 PIC  X(01).
               05  FILLER         OCCURS 04 TIMES
                                  INDEXED BY J.
                   10  TB-CODE    PIC  X(06).
                   10             PIC  X(01).
      ****************************************************************
       PROCEDURE DIVISION.
      ****************************************************************
       0000-STARTING             SECTION.
      ****************************************************************

           MOVE 100   TO WS-BALANCE.
           MOVE 5,93 TO WS-USD-BRL-RATIO.

           PERFORM  1000-INITIALIZE.
           PERFORM  2000-PROCESS UNTIL WS-YEAR(1:3) EQUAL 'END'
           PERFORM  9000-ENDING
           GOBACK.

       0000-EXIT. EXIT.

      ****************************************************************
       1000-INITIALIZE           SECTION.
      ****************************************************************
           ACCEPT WS-INPUT FROM SYSIN.
       1000-EXIT. EXIT.
      ****************************************************************
       2000-PROCESS              SECTION.
      ****************************************************************
           MOVE '404' TO WS-TYPE-CODE

           PERFORM VARYING I FROM 1 BY 1 UNTIL I > 3
               PERFORM VARYING J FROM 1 BY 1 UNTIL J > 4
                   IF  (TB-CODE(I, J) = WS-MARKET)
                       MOVE TB-TYPE(I) TO WS-TYPE-CODE
                   END-IF
               END-PERFORM
           END-PERFORM.

           PERFORM 2001-EVALUATE-TRADE.

       2000-EXIT. EXIT.
      ****************************************************************
       2001-EVALUATE-TRADE       SECTION.
      ****************************************************************

           EVALUATE WS-TYPE-CODE
               WHEN '404'        PERFORM  2995-DISP-ERROR-TYPE
               WHEN OTHER        PERFORM  2002-COMPUTE
           END-EVALUATE.

       2001-EXIT. EXIT.

      ****************************************************************
       2002-COMPUTE              SECTION.
      ****************************************************************

           IF (WS-STOP-LOSS NOT ZERO)
               COMPUTE  WS-RR-RATIO = WS-TAKE-PROFIT / WS-STOP-LOSS
           ELSE
               DISPLAY 'STOP-LOSS CANNOT BE ZERO'
           END-IF.
           COMPUTE  WS-STOP-LOSS-NEG = -1 * WS-STOP-LOSS.

           ADD 01 TO          AC-TRADE-ID.

           IF (WS-RESULT-VALUE >= WS-TAKE-PROFIT)
               MOVE 'FULL GAIN' TO WS-FINAL
           ELSE
               IF (WS-RESULT-VALUE > 0)
                   MOVE 'SMALL GAIN' TO WS-FINAL
               ELSE
                   IF (WS-RESULT-VALUE EQUAL 0)
                       MOVE 'ZERO' TO WS-FINAL
                   ELSE
                       IF (WS-RESULT-VALUE <= WS-STOP-LOSS-NEG)
                           MOVE 'FULL LOSS' TO WS-FINAL
                       ELSE
                           MOVE 'SMALL LOSS' TO WS-FINAL
                       END-IF
                   END-IF
               END-IF
           END-IF.

           IF (AC-TRADE-ID = 01)
               PERFORM  2996-DISP-CODE-TYPES
           END-IF.

           PERFORM  2997-DISP.
           PERFORM  1000-INITIALIZE.

       2002-EXIT. EXIT.
      ****************************************************************
       2100-CONVERTER            SECTION.
      ****************************************************************

           EVALUATE WS-CURRENCY
               WHEN 'USD'        PERFORM  2110-DEFAULT-BALANCE
               WHEN 'BRL'        PERFORM  2120-BRL-TO-USD
               WHEN OTHER        PERFORM  9999-ERROR
           END-EVALUATE.

       2100-EXIT. EXIT.
      ****************************************************************
       2110-DEFAULT-BALANCE      SECTION.
      ****************************************************************

           ADD  WS-RESULT-VALUE TO WS-BALANCE
           END-ADD

           PERFORM 2998-DISP-USD.

       2110-EXIT. EXIT.
      ****************************************************************
       2120-BRL-TO-USD           SECTION.
      ****************************************************************

           COMPUTE WS-USD-TAKE-PROFIT  = WS-TAKE-PROFIT  /
                                         WS-USD-BRL-RATIO.
           COMPUTE WS-USD-STOP-LOSS    = WS-STOP-LOSS    /
                                         WS-USD-BRL-RATIO.
           COMPUTE WS-USD-RESULT-VALUE = WS-RESULT-VALUE /
                                         WS-USD-BRL-RATIO.

           ADD  WS-USD-RESULT-VALUE TO WS-BALANCE
           END-ADD

           PERFORM 2999-DISP-USD-BRL.

       2120-EXIT. EXIT.
      ****************************************************************
       2995-DISP-ERROR-TYPE      SECTION.
      ****************************************************************

           DISPLAY '<--------------------->'.
           DISPLAY '    TYPE NOT FOUND     '.
           PERFORM 1000-INITIALIZE.

       2995-EXIT. EXIT.
      ****************************************************************
       2996-DISP-CODE-TYPES      SECTION.
      ****************************************************************

           DISPLAY '+-------------------+'.
           DISPLAY '| TB-TYPE 1 = ' TB-TYPE(1) ' |'.
           DISPLAY '| TB-TYPE 2 = ' TB-TYPE(2) ' |'.
           DISPLAY '| TB-TYPE 3 = ' TB-TYPE(3) ' |'.
           DISPLAY '+-------------------+'.
           DISPLAY '| CODES FOR ' TB-TYPE(1) ': |'.
           DISPLAY '| 1 : ' TB-CODE(1, 1) '   |'.
           DISPLAY '| 2 : ' TB-CODE(1, 2) '   |'.
           DISPLAY '| 3 : ' TB-CODE(1, 3) '   |'.
           DISPLAY '| 4 : ' TB-CODE(1, 4) '   |'.
           DISPLAY '+-------------------+'.
           DISPLAY '| CODES FOR ' TB-TYPE(2) ': |'.
           DISPLAY '+-------------------+'.
           DISPLAY '| 1 : ' TB-CODE(2, 1) '   |'.
           DISPLAY '| 2 : ' TB-CODE(2, 2) '   |'.
           DISPLAY '| 3 : ' TB-CODE(2, 3) '   |'.
           DISPLAY '| 4 : ' TB-CODE(2, 4) '   |'.
           DISPLAY '+-------------------+'.
           DISPLAY '| CODES FOR ' TB-TYPE(3) ': |'.
           DISPLAY '+-------------------+'.
           DISPLAY '| 1 : ' TB-CODE(3, 1) '   |'.
           DISPLAY '| 2 : ' TB-CODE(3, 2) '   |'.
           DISPLAY '| 3 : ' TB-CODE(3, 3) '   |'.
           DISPLAY '| 4 : ' TB-CODE(3, 4) '   |'.
           DISPLAY '+-------------------+'.
           DISPLAY 'DADOS: '.

       2996-EXIT. EXIT.
      ****************************************************************
       2997-DISP                 SECTION.
      ****************************************************************

           DISPLAY '<--------------------->'.
           DISPLAY 'ID = ' AC-TRADE-ID.
           MOVE WS-BALANCE TO WS-BALANCE-MASK.
           DISPLAY 'MARGIN($) = ' WS-BALANCE-MASK.
           DISPLAY 'TYPE OF INVESTMENT = ' WS-TYPE-CODE.

           STRING WS-YEAR DELIMITED BY SIZE,
                  '-' DELIMITED BY SIZE,
                  WS-MONTH DELIMITED BY SIZE,
                  '-' DELIMITED BY SIZE,
                  WS-DAY DELIMITED BY SIZE,
               INTO WS-DATE-MASK
               ON OVERFLOW DISPLAY 'DATE WENT WRONG!'
               NOT ON OVERFLOW DISPLAY 'DATE = ' WS-DATE-MASK
           END-STRING.

           DISPLAY 'MARKET = ' WS-MARKET.
           DISPLAY 'RESULT = ' WS-FINAL.

           PERFORM 2100-CONVERTER.

       2997-EXIT. EXIT.
      ****************************************************************
       2998-DISP-USD             SECTION.
      ****************************************************************

           DISPLAY 'USD: '.
           MOVE    WS-TAKE-PROFIT  TO WS-TAKE-PROFIT-MASK.
           DISPLAY 'TAKE-PROFIT = ' WS-TAKE-PROFIT-MASK.
           MOVE    WS-STOP-LOSS    TO WS-STOP-LOSS-MASK.
           DISPLAY 'WS-STOP-LOSS = ' WS-STOP-LOSS-MASK.
           MOVE    WS-RESULT-VALUE TO WS-RESULT-VALUE-MASK.
           DISPLAY 'WS-RESULT-VALUE = ' WS-RESULT-VALUE-MASK.
           MOVE    WS-RR-RATIO     TO WS-RR-RATIO-MASK.
           DISPLAY 'R/R RATIO = ' WS-RR-RATIO-MASK.

       2998-EXIT. EXIT.
      ****************************************************************
       2999-DISP-USD-BRL         SECTION.
      ****************************************************************

           DISPLAY 'BRL (CONVERTED): '.
           MOVE    WS-USD-TAKE-PROFIT  TO WS-TAKE-PROFIT-MASK.
           DISPLAY 'TAKE-PROFIT = ' WS-TAKE-PROFIT-MASK.
           MOVE    WS-USD-STOP-LOSS    TO WS-STOP-LOSS-MASK.
           DISPLAY 'WS-STOP-LOSS = ' WS-STOP-LOSS-MASK.
           MOVE    WS-USD-RESULT-VALUE TO WS-RESULT-VALUE-MASK.
           DISPLAY 'WS-RESULT-VALUE = ' WS-RESULT-VALUE-MASK.
           MOVE    WS-RR-RATIO         TO WS-RR-RATIO-MASK.
           DISPLAY 'R/R RATIO = ' WS-RR-RATIO-MASK.

       2999-EXIT. EXIT.
      ****************************************************************
       9000-ENDING               SECTION.
      ****************************************************************

           DISPLAY '<--------------------->'.
           DISPLAY 'ENDING THE PROGRAM'.
           DISPLAY '<--------------------->'.

       9000-EXIT. EXIT.
       9999-ERROR.
           GOBACK.
       9999-EXIT.
