program mydaemon;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  SysUtils, BaseUnix, Classes, Dateutils;

const
  PidFilePath = '/var/run/myloggerd.pid';
  LogFilePath = '/var/log/mydaemon.log';

var
  bTerm : boolean;
  aOld,
  aTerm: pSigActionRec;
  ps1  : psigset;
  sSet : cardinal;
  pid  : pid_t;
  zerosigs : sigset_t;

procedure DoSig(Sig : longint); cdecl;
begin
  case Sig of
    SIGTERM: bTerm := True;
  end;
end;

function IsPrimeNumber(ANumber: Byte): boolean;
var
  i: Integer;
begin
  Result := True;
  if ANumber < 2 then
    Result := False
  else
    for i := 1 to ANumber div 2 do
      if ((ANumber mod i) = 0) and (i <> 1)
        then Result := False;
end;

procedure RunDaemon;
var
  F: TextFile;
  CurrentSecond: Byte;
begin
  {$hints off}
    fpSigEmptySet(ZeroSigs);
  {$hints on}

  bTerm := False;

  sSet := $ffffbffe;
  ps1 := @sSet;
  fpSigProcMask(sig_block, ps1, nil);

  New(aOld);
  New(aTerm);
  aTerm^.sa_handler := SigactionHandler(@DoSig);

  aTerm^.sa_mask := ZeroSigs;
  aTerm^.sa_flags := 0;
  fpSigAction(SIGTERM, aTerm, aOld);

  pid := fpFork;
  case pid of
    0 : begin
          // Сохраняем id процесса
          try
            AssignFile(F, PidFilePath);
            Rewrite(F);
            pid := fpGetPid;
            WriteLn(F, pid);
            Close(F);
          except
            on E: Exception do
            begin
              case E.Message of
                'Access denied': WriteLn('Ошибка: необходимы права суперпользователя');
              else
                WriteLn(E.ClassName + ' ' + E.Message);
              end;
              Halt(0);
            end;
          end;
          WriteLn('Демон запущен');

          // Закрываем стандартные потоки ввода/вывода
          Close(Input);
          Assign(Input,'/dev/null');
          ReWrite(Input);
          Close(Output);
          Assign(Output,'/dev/null');
          ReWrite(Output);
          Close(ErrOutput);
          Assign(ErrOutput,'/dev/null');
          ReWrite(ErrOutput);
        end;
    -1 :begin
          WriteLn('Ошибка запуска демона');
          Halt(1);
        end;
  else
    Halt(0);
  end;

  AssignFile(F, LogFilePath);
  if FileExists(LogFilePath) then
    Append(F)
  else
    Rewrite(F);

  repeat
    CurrentSecond := SecondOf(Now);
    if IsPrimeNumber(CurrentSecond) then
      WriteLn(F, TimeToStr(Now) + ': '
        + IntToStr(CurrentSecond) + ' - простое число.');
    Sleep(1000);
  until bTerm;

  Close(F);

  DeleteFile(PidFilePath);
end;

function GetPid: pid_t;
var
  F: TextFile;
begin
  try
    AssignFile(F, PidFilePath);
    Reset(F);
    ReadLn(F, Result);
  finally
    Close(F);
  end;
end;

function DaemonIsRuning: boolean;
var
  s: String[10];
begin
  Result := False;
  if FileExists(PidFilePath) then
  begin
    s := IntToStr(GetPid);

    if fpOpenDir('/proc/' + s) = nil then
      DeleteFile(PidFilePath)
    else
      Result := True;
  end;
end;

procedure DaemonKill;
var
  Err: Longint;
begin
  if DaemonIsRuning then
  begin
    pid := GetPid;
    if fpkill(pid, SIGTERM) < 0 then
    begin
      Err := fpGetErrNo;
      case Err of
        ESysEsrch: begin
                     Writeln('Процесса с PID=' + IntToStr(pid) + ' не существует');
                     DeleteFile(PidFilePath);
                   end;
        ESysEperm: Writeln('Ошибка: не прав для уничтожения процесса');
      else
        WriteLn('Ошибка с кодом ' + IntToStr(Err));
      end;
    end;
    WriteLn('Демон остановлен');
  end;
end;

procedure WrongParam;
begin
  WriteLn('Используйте:');
  WriteLn('    ' + ParamStr(0) + ' {start|stop|restart|status}');
  Halt(0);
end;

begin
  if fpGetUID <> 0 then
  begin
    WriteLn('Ошибка: необходимы права суперпользователя');
    Halt(0);
  end;

  if ParamCount > 0 then
  begin
    if ParamCount = 1 then
    begin
      case ParamStr(1) of
          'start' : begin
                      if DaemonIsRuning then
                      begin
                        WriteLn('Демон уже запущен');
                        Halt(0);
                      end else
                        RunDaemon;
                    end;

           'stop' : begin
                      if DaemonIsRuning then
                      begin
                        WriteLn('Остановка демона...');
                        DaemonKill;
                        Halt(0);
                      end else
                        WriteLn('Демон не запущен');
                    end;

        'restart' : begin
                      if DaemonIsRuning then
                      begin
                        WriteLn('Остановка демона...');
                        DaemonKill;
                        RunDaemon;
                      end else
                        WriteLn('Демон не запущен');
                    end;
         'status' : begin
                      if DaemonIsRuning then
                        WriteLn('Демон запущен')
                      else
                        WriteLn('Демон не запущен');
                    end
      else
        WriteLn('Ошибка: неверный параметр');
        WrongParam;
      end;
    end else
    begin
      WriteLn('Ошибка: неверное количество параметров');
      WrongParam;
    end;
  end else
  begin
    WriteLn('Ошибка: не заданы параметры');
    WrongParam;
  end;

  Halt(0);
end.
