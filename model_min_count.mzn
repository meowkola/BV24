% Use this editor as a MiniZinc scratch book
include "main.dzn";

int: max_int = 1000;
int: time;
int: op_count;
int: izd_count;
int: mach_count;

% склад
array[0..time, 1..izd_count] of var int: izd;
% начинается ли операция
array[0..time, 1..op_count] of var 0..1: op;
% идет ли операция
array[0..time, 1..op_count] of var 0..1: op_ex;
% сколько свободно рабочих
array[0..time, 1..op_count] of var int: workers;

%i - каждая машина, j - каждое время, значение - производится (1) или нет (0) операция.
array[1..mach_count,0..time] of var 0..1: machines;
%i - каждая машина, j - каждое время, значение - на тех. обслуживании (1) или нет (0).
array[1..mach_count,0..time] of var 0..1: now_rest;
%i - каждая машина, j - каждое время, значение - износ машины
array[1..mach_count,0..time] of var 0..time: degrade;

% TODO: задать параметры тех. обслуживания
%i - каждая машина, значение - маскимально возможный износ машины
array[1..mach_count] of int: max_without_rest_duration;
%i - каждая машина, значение - время, необходимое на отдых каждой машины
array[1..mach_count] of int: rest_time;

% длительность операций
array[1..op_count] of int: op_len;
% сколько ресурсов данного типа надо на вход операции
array[1..op_count, 1..izd_count] of 0..100: op_in;
% сколько ресурсов данного типа операция выдает на выход
array[1..op_count, 1..izd_count] of int: op_out;
int: mach_count;
array[1..mach_count, 1..op_count] of 0..1: mach;
array[1..time, 1..izd_count] of int: delivery;


constraint forall(i in 0..time, j in 1..op_count) (
    workers[i, j] >= 0 
);

constraint forall(i in 0..time, j in 1..op_count) (
    op_ex[i, j] = sum(k in max(0, i - op_len[j]+1)..i)(op[k, j])
);

constraint forall(i in 1..izd_count) (
    izd[0, i] = 0
);
constraint forall(i in 0..time, j in 1..izd_count) (
    izd[i, j] >= 0
);
constraint forall(i in 1..time, j in 1..izd_count) (
    izd[i, j] = izd[i-1, j] + sum(k in 1..op_count where i-op_len[j] > 0)(op[i-op_len[j], j]*op_out[k, j]) - sum(k in 1..op_count) (op[i, k] * op_in[k, j]) - delivery[i, j]
);

constraint forall(i in 1..time, j in 1..mach_count) (
    sum(k in 1..op_count) (op_ex[i, k]*mach[j, k]) <= 1
);
% ограничение: тех. обслуживание, увеличение износа
constraint forall (i in 1..mach_count, t in 1..time)(
    if now_rest[i,t]=1
    then degrade[i,t]=0
    else degrade[i,t]=degrade[i,t-1]+machine[i,t]
    endif
);
% ограничение: первый день износа совпадает с тем, поработала ли машина в первый день
constraint forall (i in 1..mach_count)(
    degrade[i,0]=machine[i,0]
);
% ограничение: износ машины в каждый момент не больше максимально возможного для машины
constraint forall (i in 1..mach_count, t in 0..time)(
    degrade[i,t]<=max_without_rest_duration[i]
);
% ограничение: если машина сегодня отдыхает, а вчера - нет, то она должна отдыхать еще rest_time-1
constraint forall (i in 1..mach_count, t in 1..time)(
    if now_rest[i,t]=1 /\ now_rest[i,t-1]=0
    then forall (h in t..min(t+rest_time[i]-1,time))(now_rest[i,h]=1)
    endif
);
% ограничение: машина не может одновременно и отдыхать, и работать
constraint forall (i in 1..mach_count, t in 0..time)(
    now_rest[i,t]!=machine[i,t]
);


solve minimize sum(i in 1..time, j in 1..op_count)(izd[i, j]);

output ["День:\t| Идет процесс:\t\t\t| Изделия:\n"];
output [if j == 1 then show(i) ++ "\t| " else "" endif ++ 
if j <= op_count then show(op_ex[i, j]) ++ if j  == op_count then "\t| " else "\t" endif 
else show(izd[i, j-op_count]) ++ if j == (op_count+izd_count) then "\n" else "\t" endif 
endif | i in 0..time, j in 1..(op_count+izd_count)];
