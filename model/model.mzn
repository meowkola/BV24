include "model.dzn";

int: max_int = 1000;
int: time;

int: op_count;
int: izd_count;
int: mach_count;

% склад
array[0..time, 1..izd_count] of var int: izd;
% поставка
array[0..time, 1..izd_count] of var int: add;
% нужна ли поставка
array[ 1..izd_count] of var int: can_add;
% начинается ли операция
array[0..time, 1..op_count] of var 0..1: op;
% идет ли операция
array[0..time, 1..op_count] of var 0..1: op_ex;
% сколько свободно рабочих
array[0..time, 1..op_count] of var int: workers;

% i - каждое время, j - каждая машина, значение - производится (1) или нет (0) операция.
array[0..time, 1..mach_count] of var 0..1: machine_now_working;
% i - каждое время, j - каждая машина, значение - на тех. обслуживании (1) или нет (0).
array[0..time, 1..mach_count] of var 0..1: now_rest;
% i - каждое время, j - каждая машина, значение - износ машины
array[0..time, 1..mach_count] of var 0..time: degrade;
% Аналогично для big_rest
% i - каждое время, j - каждая машина, значение - на большом тех. обслуживании (1) или нет (0).
array[0..time, 1..mach_count] of var 0..1: now_big_rest;
% i - каждое время, j - каждая машина, значение - большой износ машины
array[0..time, 1..mach_count] of var 0..time: big_degrade;

% длительность операций
array[1..op_count] of int: op_len;
% сколько ресурсов данного типа надо на вход операции
array[1..op_count, 1..izd_count] of 0..100: op_in;
% сколько ресурсов данного типа операция выдает на выход
array[1..op_count, 1..izd_count] of int: op_out;
% изделий изначально на складе
array[1..izd_count] of int: izd_start;
array[1..mach_count, 1..op_count] of 0..1: mach;
array[1..time, 1..izd_count] of int: delivery;


%i - каждая машина, значение - максимально возможный износ машины
array[1..mach_count] of int: max_without_rest_duration;
%i - каждая машина, значение - время, необходимое на тех. обслуживании каждой машины
array[1..mach_count] of int: rest_time;
% Аналогичные значения для big_rest
%i - каждая машина, значение - маскимально возможный big-износ каждой машины
array[1..mach_count] of int: max_without_big_rest_duration;
%i - каждая машина, значение - время, необходимое на большое тех. обслуживание каждой машины
array[1..mach_count] of int: big_rest_time;



% может ли идти поставка
constraint forall(i in 1..izd_count) (
    can_add[i] = max(0, 1 - sum(j in 1..op_count)(op_out[j, i]))
);
% поставка сырья не идет, если не может идти
constraint forall(i in 0..time, j in 1..izd_count where can_add[j] == 0) (
    add[i, j] <= can_add[j]
);

% количество свободных работников не меньше 0
constraint forall(i in 0..time, j in 1..op_count) (
    workers[i, j] >= 0
);

% выполняется ли операция в данный момент времени
constraint forall(i in 0..time, j in 1..op_count) (
    op_ex[i, j] = sum(k in max(0, i - op_len[j]+1)..i)(op[k, j])
);

% в 0 день у нас izd_start изделий на складе
constraint forall(i in 1..izd_count) (
    izd[0, i] = izd_start[i]
);
% поставки и количество ресурсов на складе неотрицательны
constraint forall(i in 0..time, j in 1..izd_count) (
    izd[i, j] >= 0 /\ add[i, j] >= 0
);
% изменение ресурсов на складе
constraint forall(i in 1..time, j in 1..izd_count) (
    izd[i, j] = izd[i-1, j] + sum(k in 1..op_count where i-op_len[k] >= 0)(op[i-op_len[k], k]*op_out[k, j]) - sum(k in 1..op_count) (op[i, k] * op_in[k, j]) - delivery[i, j] + add[i,j]
);
% поставки
constraint forall(i in 0..time-1, j in 1..izd_count) (
    add[i, j] = sum(k in 1..op_count) (op[i+1, k] * op_in[k, j]) * can_add[j]
);

% в каждый момент времени станок может выполнять не более одной операции (это следует из того, что machines 0..1) + соответствие между mach и machines
constraint forall(i in 1..time, j in 1..mach_count) (
    sum(k in 1..op_count) (op_ex[i, k]*mach[j, k]) = machine_now_working[i, j]
);

% ограничение: тех. обслуживание, увеличение износа
constraint forall (t in 1..time, m in 1..mach_count)(
    if now_rest[t, m] = 1 \/ now_big_rest[t, m] = 1
    then degrade[t, m] = 0
    else degrade[t, m] = degrade[t-1, m] + machine_now_working[t, m]
    endif
);
% ограничение: первый день износа совпадает с тем, поработала ли машина в первый день
constraint forall (m in 1..mach_count)(
    degrade[0, m] = machine_now_working[0, m]
);
% ограничение: износ машины в каждый момент не больше максимально возможного для машины
constraint forall (t in 0..time, m in 1..mach_count)(
    degrade[t, m] <= max_without_rest_duration[m]
);
% ограничение: если машина сегодня отдыхает, а вчера - нет, то она должна отдыхать еще rest_time-1
constraint forall (t in 1..time, m in 1..mach_count)(
    if now_rest[t, m] = 1 /\ now_rest[t-1, m] = 0
    then forall (h in t..min(t+rest_time[m]-1, time)) (now_rest[h, m] = 1)
    else true
    endif
);
% ограничение: машина не может одновременно и отдыхать, и работать
constraint forall (t in 0..time, m in 1..mach_count)(
    now_rest[t, m] + machine_now_working[t, m] + now_big_rest[t, m] <= 1
);
% ограничение: увеличение большого износа
constraint forall (t in 1..time, m in 1..mach_count)(
    if now_big_rest[t, m]=1
    then big_degrade[t, m]=0
    else big_degrade[t, m]=big_degrade[t-1, m]+machine_now_working[t, m]
    endif
);
% ограничение: первый день большого износа совпадает с тем, поработала ли машина в первый день
constraint forall (m in 1..mach_count)(
    big_degrade[0, m]=machine_now_working[0, m]
);
% ограничение: большой износ машины в каждый момент не больше максимально возможного для машины
constraint forall (t in 0..time, m in 1..mach_count)(
    big_degrade[t, m] <= max_without_big_rest_duration[m]
);
% ограничение: если машина сегодня big-отдыхает, а вчера - нет, то она должна big-отдыхать еще rest_time-1
constraint forall (t in 1..time, m in 1..mach_count)(
    if now_big_rest[t, m] = 1 /\ now_big_rest[t-1, m] = 0
    then forall (h in t..min(t+big_rest_time[m]-1,time))(now_big_rest[h, m]=1)
    else true
    endif
);


solve minimize sum(i in 1..time, j in 1..op_count)(izd[i, j]);

output ["День:\t| Идет процесс:\t\t\t| Изделия:\t\t\t\t| Поставки:\n"];
output [if j == 1 then show(i) ++ "\t| " else "" endif ++
if j <= op_count then show(op_ex[i, j]) ++ if j  == op_count then "\t| " else "\t" endif
else if j <= op_count+izd_count then show(izd[i, j-op_count]) ++ if j  == op_count+izd_count then "\t| " else "\t" endif
else show(add[i, j-op_count-izd_count]) ++ if j == (op_count+izd_count*2) then "\n" else "\t" endif
endif endif | i in 0..time, j in 1..(op_count+izd_count*2)];
