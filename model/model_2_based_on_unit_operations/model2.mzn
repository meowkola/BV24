include "model.dzn";

int: max_int = 1000;
int: time;
int: op_count;
int: izd_count;
int: max_izd;

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

% i - каждая машина, j - каждое время, значение - производится (1) или нет (0) операция.
array[0..time, 1..mach_count] of var 0..1: machines;
% i - каждая машина, j - каждое время, значение - на тех. обслуживании (1) или нет (0).
array[0..time, 1..mach_count] of var 0..1: now_rest;
% i - каждая машина, j - каждое время, значение - износ машины
array[0..time, 1..mach_count] of var 0..time: degrade;

% длительность операций
array[1..op_count] of int: op_len;
% сколько ресурсов данного типа надо на вход операции
array[1..op_count, 1..izd_count] of 0..100: op_in;
% сколько ресурсов данного типа операция выдает на выход
array[1..op_count, 1..izd_count] of int: op_out;
% изделий изначально на складе
array[1..izd_count] of int: izd_start;
% количество машин
int: mach_count;
% какие операции может выполнять станок
array[1..mach_count, 1..op_count] of 0..1: mach;
% сколько мы должны отгрузить по заказу
array[1..time, 1..izd_count] of int: delivery;


% на тех обслуживании машина (только начало то)
array[0..time, 1..mach_count] of var 0..1: mt;
% на тех обслуживании машина
array[0..time, 1..mach_count] of var 0..1: mt_ex;
% работает ли машина
array[0..time, 1..mach_count] of var 0..1: work;
% износ машины
array[0..time, 1..mach_count] of var int: damage;
% максимальное время без то
array[1..mach_count] of int: max_damage;
% длина то
array[1..mach_count] of int: mt_len;
% расписание поставок
array[0..time] of 0..1: doing_add;




% может ли идти поставка
constraint forall(i in 1..izd_count) (
    can_add[i] = max(0, 1 - sum(j in 1..op_count)(op_out[j, i]))
);
% поставка сырья не идет, если не может идти
constraint forall(i in 0..time, j in 1..izd_count where can_add[j] == 0) (
    add[i, j] <= can_add[j]
);

% количество свободных работников больше 0
constraint forall(i in 0..time, j in 1..op_count) (
    workers[i, j] >= 0
);

% выполняется ли операция в данный момент времени
constraint forall(i in 0..time, j in 1..op_count where i - op_len[j]+1 >= 0) (
    op_ex[i, j] = sum(k in i - op_len[j]+1..i)(op[k, j])
);

% в 0 день у нас 0 изделий на складе
constraint forall(i in 1..izd_count) (
    izd[0, i] = izd_start[i]
);
% поставки и количество ресурсов на складе неотрицательны
constraint forall(i in 0..time, j in 1..izd_count) (
    izd[i, j] >= 0 /\ add[i, j] >= 0
);
% ограничение на вместимость склада
constraint forall(i in 0..time) (
    sum(j in 1..izd_count) (izd[i, j]) <= max_izd
);
% изменение ресурсов на складе
constraint forall(i in 1..time, j in 1..izd_count) (
    izd[i, j] = izd[i-1, j] + sum(k in 1..op_count where i-op_len[k] > 0)(op[i-op_len[k], k]*op_out[k, j]) - sum(k in 1..op_count) (op[i, k] * op_in[k, j]) - delivery[i, j] + add[i,j]
);
% поставки
constraint forall(i in 0..time-1, j in 1..izd_count) (
    add[i, j] = sum(k in 1..op_count) (op[i+1, k] * op_in[k, j]) * can_add[j] * doing_add[i]
);


constraint forall(j in 1..mach_count) (
    work[0, j] = 0 /\ mt[0, j] = 0 /\ damage[0, j] = 0
);

% в каждый момент времени станок может выполнять не более одной операции
constraint forall(i in 1..time, j in 1..mach_count) (
    work[i, j] = sum(k in 1..op_count) (op_ex[i, k]*mach[j, k])
);

constraint forall(i in 1..time, j in 1..mach_count) (
    work[i, j] + mt_ex[i, j] <= 1
);

constraint forall(i in 1..time, j in 1..mach_count) (
    damage[i, j] = damage[i-1, j] + work[i, j] - 
    (damage[i-1, j])*mt[i, j]
%     max_damage[j]*mt[i, j]
      /\ damage[i, j] <= max_damage[j]
);

constraint forall(i in 0..time, j in 1..mach_count where i - mt_len[j]+1 >= 0) (
    mt_ex[i, j] = sum(k in i - mt_len[j]+1..i)(mt[k, j])
);




solve minimize sum(i in 1..time, j in 1..izd_count)(izd[i, j]);

output ["День:\t| Идет процесс:\t\t\t| Изделия:\t\t\t\t| Поставки:\t\t\t\t| Износ станка:\t|То станка:\n"];
output [if j == 1 then show(i) ++ "\t| " else "" endif ++
     if j <= op_count                           then show(op_ex[i, j])                                ++ if j == op_count                               then "\t| " else "\t" endif
else if j <= op_count+izd_count                 then show(izd[i, j-op_count])                         ++ if j == op_count+izd_count                     then "\t| " else "\t" endif
else if j <= op_count+izd_count*2               then show(add[i, j-op_count-izd_count])               ++ if j == (op_count+izd_count*2)                 then "\t| " else "\t" endif
else if j <= op_count+izd_count*2+mach_count    then show(damage[i, j-op_count-izd_count*2])          ++ if j == (op_count+izd_count*2+mach_count)      then "\t| " else "\t" endif
else                                            show(mt_ex[i, j-op_count-izd_count*2-mach_count])     ++ if j == (op_count+izd_count*2+mach_count*2)    then "\n" else "\t" endif
endif endif endif endif | i in 0..time, j in 1..(op_count + izd_count*2 + mach_count*2)];
