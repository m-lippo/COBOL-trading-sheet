       CBL ARITH(EXTEND)
      ****************************************************************
       IDENTIFICATION DIVISION.
      ****************************************************************
       PROGRAM-ID.  TRADING1.
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

           SELECT TRADS001 ASSIGN TO    TRADS001
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS          IS FS-TRADS001.

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

       FD  TRADS001
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 80 CHARACTERS
           RECORDING MODE IS F
           LABEL RECORD IS STANDARD
           DATA RECORD IS OUTPUT-TRADE.

       01  OUTPUT-TRADE.
           03  TRADE-ID           PIC  9(03).
           03  MARKET             PIC  X(06).
           03  TP                 PIC  9(03)V99.
           03  SL                 PIC  9(03)V99.
           03  RR-RATIO           PIC  9(03)V99.
           03  RES-VAL            PIC  S9(03)V99
               SIGN IS LEADING SEPARATE CHARACTER.
           03  CUR                PIC  X(03).
           03  RES-CAT            PIC  X(02).
           03  FILLER             PIC  X(45).
      ****************************************************************
       WORKING-STORAGE SECTION.
      ****************************************************************

       01  FS-TRADE001            PIC  9(02) VALUE ZEROS.
       01  FS-TRADS001            PIC  9(02) VALUE ZEROS.

       01  WS-NEW-VARS.
           03  AC-TRADE-ID        PIC  9(03) VALUE ZEROS.
           03  WS-END-OF-FILE     PIC  X(01) VALUE 'N'.
           03  WS-RES-VAL         PIC  S9(03)V99.
           03  WS-RR-RATIO        PIC  9(03)V99.

       01  WS-CALC-INPUT-VARS.
           03  WS-TP              PIC  S9(03)V99.
           03  WS-SL              PIC  S9(03)V99.
           03  WS-SL-NEG          PIC  S9(03)V99.
      ****************************************************************
       PROCEDURE DIVISION.
      ****************************************************************

      ****************************************************************
       00-STARTING               SECTION.
      ****************************************************************

           PERFORM 10-INITIALIZE.
      *    PERFORM 20-PROCEDURES IS IN THE 10-INITIALIZE SECTION
           PERFORM 90-ENDING.

       00-EXIT. EXIT.
      ****************************************************************

      ****************************************************************
       10-INITIALIZE             SECTION.
      ****************************************************************

           OPEN INPUT  TRADE001
           IF FS-TRADE001 NOT EQUAL ZEROS
               DISPLAY 'ERROR OPENING FILE FS-TRADE001'
               DISPLAY 'FS-TRADE001 = ' FS-TRADE001
               GOBACK
           END-IF.

           OPEN OUTPUT TRADS001
           IF FS-TRADS001 NOT EQUAL ZEROS
               DISPLAY 'ERROR OPENING FILE FS-TRADS001'
               DISPLAY 'FS-TRADS001 = ' FS-TRADS001
               GOBACK
           END-IF.

           PERFORM UNTIL WS-END-OF-FILE EQUAL 'Y'
               READ TRADE001
                   AT END
                       MOVE 'Y' TO WS-END-OF-FILE
                   NOT AT END
                       PERFORM 20-PROCEDURES
               END-READ
           END-PERFORM.

       10-EXIT. EXIT.
      ****************************************************************
       20-PROCEDURES             SECTION.
      ****************************************************************

           PERFORM 21-MOVE-VARS.
           PERFORM 22-CALC-RES-CAT.
           PERFORM 23-CALC-RR-RATIO.

           WRITE OUTPUT-TRADE.

       20-EXIT. EXIT.
