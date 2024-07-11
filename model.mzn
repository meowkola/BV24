include "main.dzn";

int: max_int = 1000;
int: time;
int: op_count;
int: izd_count;
% склад
array[0..time, 1..izd_count] of var int: izd;
% поставка
array[0..time, 1..izd_count] of var int: add;
% нужна ли поставка
array[ 1..izd_count] of var int: can_add;
% начинается ли операция
array[0..time, 1..op_count] of var 0..100: op;
% идет ли операция
array[0..time, 1..op_count] of var 0..100: op_ex;
% сколько свободно рабочих
array[0..time, 1..op_count] of var int: workers;

% длительность операций
array[1..op_count] of int: op_len;
% сколько ресурсов данного типа надо на вход операции
array[1..op_count, 1..izd_count] of 0..100: op_in;
% сколько ресурсов данного типа операция выдает на выход
array[1..op_count, 1..izd_count] of int: op_out;
int: mach_count;
array[1..mach_count, 1..op_count] of 0..1: mach;
array[1..time, 1..izd_count] of int: delivery;


constraint forall(i in 1..izd_count) (
    can_add[i] = max(0, 1 - sum(j in 1..op_count)(op_out[j, i]))
);
constraint forall(i in 0..time, j in 1..izd_count) (
    add[i, j] <= can_add[j] * 1000000
);
output [show(can_add) ++ "\n"];

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
    izd[i, j] >= 0 /\ add[i, j] >= 0
);
constraint forall(i in 1..time, j in 1..izd_count) (
    izd[i, j] = izd[i-1, j] + sum(k in 1..op_count where i-op_len[j] > 0)(op[i-op_len[j], j]*op_out[k, j]) - sum(k in 1..op_count) (op[i, k] * op_in[k, j]) - delivery[i, j] + add[i,j]
);
constraint forall(i in 0..time-1, j in 1..izd_count) (
    add[i, j] = sum(k in 1..op_count) (op[i+1, k] * op_in[k, j]) * can_add[j]
);

constraint forall(i in 1..time, j in 1..mach_count) (
    sum(k in 1..op_count) (op_ex[i, k]*mach[j, k]) <= 1
);

solve minimize sum(i in 1..time, j in 1..op_count)(izd[i, j]);

output ["День:\t| Идет процесс:\t\t\t| Изделия:\t\t\t\t| Поставки:\n"];
output [if j == 1 then show(i) ++ "\t| " else "" endif ++ 
if j <= op_count then show(op_ex[i, j]) ++ if j  == op_count then "\t| " else "\t" endif 
else if j <= op_count+izd_count then show(izd[i, j-op_count]) ++ if j  == op_count+izd_count then "\t| " else "\t" endif 
else show(add[i, j-op_count-izd_count]) ++ if j == (op_count+izd_count*2) then "\n" else "\t" endif
endif endif | i in 0..time, j in 1..(op_count+izd_count*2)];
