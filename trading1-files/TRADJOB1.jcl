//TRADING1 JOB (SYS,SP,72664,09,30),'MATHEUS',NOTIFY=&SYSUID,
//         REGION=0M,MSGLEVEL=(1,1),MSGCLASS=T,CLASS=N
//JOBLIB   DD DSN=DES.TESTEB.LINKLIB,DISP=SHR
//*----------------------------------------------------------------*
//*               DELETE FILES
//*----------------------------------------------------------------*
//ST01     EXEC PGM=IDCAMS,REGION=512K
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
         DELETE (DES.SYS.MZ.BGT1.TRADS001) PURGE
         SET MAXCC=0
//*----------------------------------------------------------------*
//PT01     EXEC PGM=TRADING1
//TRADE001 DD   DSN=DES.SYS.MZ.BGT1.TRADE001,DISP=SHR
//TRADS001 DD   DSN=DES.SYS.MZ.BGT1.TRADS001,
//              DISP=(NEW,CATLG,DELETE),LRECL=80,
//              SPACE=(CYL,(1,1),RLSE),UNIT=SYSDA
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
