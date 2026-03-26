       01  INPUT-TRADE.
           03  MARKET             PIC  X(06).
           03  TAKE-PROFIT        PIC  9(03)V99.
           03  STOP-LOSS          PIC  9(03)V99.
           03  RESULT-VALUE       PIC  S9(03)V99
               SIGN IS LEADING SEPARATE CHARACTER.
           03  CUR                PIC  X(03).
           03  FILLER             PIC  X(55).
