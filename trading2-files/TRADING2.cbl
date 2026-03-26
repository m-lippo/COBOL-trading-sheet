       CBL ARITH(EXTEND)
      ****************************************************************
       IDENTIFICATION DIVISION.
      ****************************************************************

       PROGRAM-ID.  TRADING2.
       AUTHOR.      MATHEUS.
       DATE-WRITTEN. 14/07/2025.

      ****************************************************************
       ENVIRONMENT DIVISION.
      ****************************************************************
       CONFIGURATION SECTION.
       SPECIAL-NAMES. DECIMAL-POINT IS COMMA.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.

           SELECT TRADE001 ASSIGN TO    TRADE001
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS          IS FS-TRADE001.

           SELECT STATS001 ASSIGN TO    STATS001
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS          IS FS-STATS001.

      ****************************************************************
       DATA DIVISION.
      ****************************************************************

      ****************************************************************
       FILE SECTION.
      ****************************************************************
       FD  TRADE001
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 80 CHARACTERS
           RECORDING MODE IS F
           LABEL RECORD IS STANDARD
           DATA RECORD IS INPUT-TRADE.

       01  INPUT-TRADE.
           03  MARKET             PIC  X(06).
           03  TP                 PIC  9(03)V99.
           03  SL                 PIC  9(03)V99.
           03  RES-VAL            PIC  S9(03)V99
               SIGN IS LEADING SEPARATE CHARACTER.
           03  CUR                PIC  X(03).
           03  FILLER             PIC  X(55).

       FD  STATS001
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 30 CHARACTERS
           RECORDING MODE IS F
           LABEL RECORD IS STANDARD
           DATA RECORD IS STATS.

       01  STATS.
           03  STAT               PIC  X(03).
           03  LOSS               PIC  9(03)V99.
           03  GAIN               PIC  9(03)V99.
           03  FILLER             PIC  X(17).
      ****************************************************************
       WORKING-STORAGE SECTION.
      ****************************************************************

       01  FS-TRADE001            PIC  9(02) VALUE ZEROS.
       01  FS-STATS001            PIC  9(02) VALUE ZEROS.

       01  INTERNAL-TABLE.
           03  AC-COUNTER         PIC  9(04) VALUE ZEROS.
           03  WS-MAX-RECORD      PIC  9(04) VALUE 50.
           03  WS-TABLE-RECORD.
               05  WS-GAIN-COL   PIC  S9(03)V99 OCCURS 50 TIMES
                                  INDEXED BY I.
               05  WS-LOSS-COL   PIC  S9(03)V99 OCCURS 50 TIMES
                                  INDEXED BY I.

       01  MEASURES.
           03  WS-AVG             PIC  9(03)V99.
           03  WS-SD              PIC  9(03)V99.
           03  WS-MIN             PIC  9(03)V99.
           03  WS-MAX             PIC  9(03)V99.

       77  WS-EOF                 PIC  X(01) VALUE 'N'.
      ****************************************************************
       PROCEDURE DIVISION.
      ****************************************************************

      ****************************************************************
       00-STARTING               SECTION.
      ****************************************************************

           PERFORM 10-INITIALIZE.
           PERFORM 20-PROCEDURES.
           PERFORM 90-ENDING.

       00-EXIT. EXIT.
      ****************************************************************
       10-INITIALIZE             SECTION.
      ****************************************************************

           OPEN INPUT  TRADE001
           IF FS-TRADE001 NOT EQUAL ZEROS
               DISPLAY 'ERROR OPENING FILE TRADE001'
               DISPLAY 'FS-TRADE001 = ' FS-TRADE001
               GOBACK
           END-IF.

           OPEN OUTPUT STATS001
           IF FS-STATS001 NOT EQUAL ZEROS
               DISPLAY 'ERROR OPENING FILE STATS001'
               DISPLAY 'FS-STATS001 = ' FS-STATS001
               GOBACK
           END-IF.

           PERFORM UNTIL WS-EOF = 'Y'
               READ TRADE001
                   AT END
                       MOVE 'Y' TO WS-EOF
                   NOT AT END
                       ADD 01 TO I
                       IF (RES-VAL > 0)
                           MOVE RES-VAL TO WS-GAIN-COL(I)
                       ELSE
                           IF (RES-VAL < 0)
                               MOVE RES-VAL TO WS-LOSS-COL(I)
                           END-IF
                       END-IF
               END-READ
           END-PERFORM.

       10-EXIT. EXIT.
      ****************************************************************
       20-PROCEDURES             SECTION.
      ****************************************************************

           PERFORM 21-CALC-AVG.
           PERFORM 22-CALC-SD.
           PERFORM 23-CALC-MIN.
           PERFORM 24-CALC-MAX.

           WRITE STATS.

       20-EXIT. EXIT.
      ****************************************************************
       21-CALC-AVG               SECTION.
      ****************************************************************

           MOVE 'AVG' TO STAT.
           COMPUTE WS-AVG = FUNCTION MEAN(WS-GAIN-COL(ALL)).
           MOVE WS-AVG TO GAIN.
           COMPUTE WS-AVG = FUNCTION MEAN(WS-LOSS-COL(ALL)).
           MOVE WS-AVG TO LOSS.

       21-EXIT. EXIT.
      ****************************************************************
       22-CALC-SD                SECTION.
      ****************************************************************

           MOVE 'SD' TO STAT.
           COMPUTE WS-SD = FUNCTION STANDARD-DEVIATION(
                                    WS-GAIN-COL(ALL)).
           MOVE WS-SD  TO GAIN.
           COMPUTE WS-SD = FUNCTION STANDARD-DEVIATION(
                                    WS-LOSS-COL(ALL)).
           MOVE WS-SD  TO LOSS.

       22-EXIT. EXIT.
      ****************************************************************
       23-CALC-MIN               SECTION.
      ****************************************************************

           COMPUTE WS-MIN = FUNCTION MIN(WS-GAIN-COL(ALL)).
           MOVE WS-MIN TO GAIN.
           COMPUTE WS-MIN = FUNCTION MIN(WS-LOSS-COL(ALL)).
           MOVE WS-MIN TO LOSS.

       23-EXIT. EXIT.
      ****************************************************************
       24-CALC-MAX               SECTION.
      ****************************************************************

           COMPUTE WS-MAX = FUNCTION MAX(WS-GAIN-COL(ALL)).
           MOVE WS-MAX TO GAIN.
           COMPUTE WS-MAX = FUNCTION MAX(WS-LOSS-COL(ALL)).
           MOVE WS-MAX TO LOSS.

       24-EXIT. EXIT.
      ****************************************************************
       90-ENDING                 SECTION.
      ****************************************************************

           CLOSE TRADE001.
           CLOSE STATS001.

           DISPLAY 'END'.

       90-EXIT. EXIT.
