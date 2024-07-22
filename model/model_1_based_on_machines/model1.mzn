include "model1.dzn";

int: time;

int: op_count;
int: izd_count;
int: mach_count;
int: size_of_stock;

% склад
array[0..time, 1..izd_count] of var int: izd;
% поставка
array[0..time, 1..izd_count] of var int: add;
% является ли предмет завозимым сырьём
array[ 1..izd_count] of var int: can_add;
% размер изделия
array[1..izd_count] of int: izd_size;

% i - каждое время, j - каждая машина, значение - производится (1) или нет (0) операция.
array[0..time, 1..mach_count] of var 0..1: machine_now_working;
% i - каждое время, j - каждая машина, значение - номер производимой операции или 0, если операция не производится
array[0..time, 1..mach_count] of var 0..op_count: machine_oper;
% i - каждое время, j - каждая машина, значение: над какой операцией машина начала работу или 0, если не начала. 
array[0..time, 1..mach_count] of var 0..op_count: machine_start;
% i - каждое время, j - каждая машина, значение - на тех. обслуживании (1) или нет (0).
array[0..time, 1..mach_count] of var 0..1: now_rest;
% i - каждое время, j - каждая машина, значение - износ машины
array[0..time, 1..mach_count] of var 0..time: degrade;


% длительность операций
array[1..op_count] of int: op_len;
% сколько ресурсов данного типа надо на вход операции
array[1..op_count, 1..izd_count] of int: op_in;
% сколько ресурсов данного типа операция выдает на выход
array[1..op_count, 1..izd_count] of int: op_out;
% изделий изначально на складе
array[1..izd_count] of int: izd_start;
% соответствие, какой станок предназначен для какой операции (1 - станок может выполнять данную операцию, 0 - не может)
array[1..mach_count, 1..op_count] of int: mach;
% отгрузка готовой продукции
array[0..time, 1..izd_count] of int: delivery;


%i - каждая машина, значение - максимально возможный износ машины
array[1..mach_count] of int: max_without_rest_duration;
%i - каждая машина, значение - время, необходимое на тех. обслуживании каждой машины
array[1..mach_count] of int: rest_time;
% график запланированного большого тех. обслуживания
array[0..time, 1..mach_count] of int: now_big_rest;



% поставка сырья не идет, если не может идти
constraint forall(i in 0..time, j in 1..izd_count where can_add[j] == 0) (
    add[i, j] = 0
);

% может ли идти поставка
constraint forall(i in 1..izd_count) (
    can_add[i] = max(0, 1 - sum(j in 1..op_count)(op_out[j, i]))
);

% в 0 день на складе izd_start изделий + поставка в 0 день - отгрузка в 0 день - расход на запуск операций в 0 день
constraint forall(i in 1..izd_count) (
    izd[0, i] = izd_start[i]- sum(m in 1..mach_count, k in 1..op_count where machine_start[0,m]=k) (op_in[k,i]) - delivery[0, i] + add[0,i]
);
% поставки и количество ресурсов на складе неотрицательны
constraint forall(i in 0..time, j in 1..izd_count) (
    izd[i, j] >= 0 /\ add[i, j] >= 0
);

% размер ресурсов на складе не превышает размер склада
constraint forall(i in 0..time) (
    sum(j in 1..izd_count) (izd[i, j]*izd_size[j]) <= size_of_stock
);

% изменение ресурсов на складе
constraint forall(t in 1..time, p in 1..izd_count) (
    izd[t, p] = izd[t-1, p] + sum(m in 1..mach_count, k in 1..op_count where t-op_len[k]>=0 /\ machine_start[t-op_len[k],m]=k) (op_out[k,p]) - sum(m in 1..mach_count, k in 1..op_count where machine_start[t,m]=k) (op_in[k,p]) - delivery[t, p] + add[t,p]
);

% станок может производить только те операции, которые соответствуют его предназначению
constraint forall (t in 0..time, m in 1..mach_count, k in 1..op_count)(
    machine_oper[t,m]!=k \/ mach[m,k]=1
);

% соответствие между machine_now_working и machine_oper (проведения операции и работы станка)
constraint forall (t in 0..time, m in 1..mach_count)(
    ((machine_oper[t,m]!=0)/\(machine_now_working[t,m]=1))\/((machine_oper[t,m]=0)/\(machine_now_working[t,m]=0))
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

% ограничение: непрерывность операции: если k операция началась на m станке, то всё время исполнения (op_len [k]),её будет исполнять m станок
constraint forall (t in 0..time, k in 1..op_count, m in 1..mach_count)(
    if machine_start[t,m]=k
    then forall (h in t..min(time,t+op_len[k]-1))(machine_oper[h,m]=k)
    else true
    endif
);

% ограничение: если k операция началась на m станке, то всё время исполнения (op_len [k]), на станке m нельзя начинать новую операцию
constraint forall (t in 0..time, k in 1..op_count, m in 1..mach_count)(
    if machine_start[t,m]=k
    then forall (h in (t+1)..min(time,t+op_len[k]-1))(machine_start[h,m]=0)
    else true
    endif
);


solve minimize sum(i in 1..time, j in 1..op_count)(izd[i, j]);

% Вывод для человека
output ["День:\t| Режим работы станков на выполнение операций:| Изделия:\t\t\t\t| Поставки:\t\t\t\t| Машины:\n"];
output [if j == -1 then show(i) else
		if j == 0 \/ j == mach_count \/ j == mach_count+izd_count \/ j == mach_count + 2*izd_count
			then "\t|"
			else "\t"
		endif
		++
		if j < mach_count then
			show(machine_oper[i, j+1])
		else if j < mach_count+izd_count then
			show(izd[i, j+1-mach_count])
		else if j < mach_count+2*izd_count then
			show(add[i, j+1-mach_count-izd_count])
		else
			if fix(machine_now_working[i, j+1-mach_count-2*izd_count]) == 1 then
				"Busy"
			else if fix(now_rest[i, j+1-mach_count-2*izd_count]) == 1 then
				"Tech work"
			else if fix(now_big_rest[i, j+1-mach_count-2*izd_count]) == 1 then
				"Big tech work"
			else
				"Idle"
			endif
			endif
			endif
		endif
		endif
		endif
	endif
++if j == mach_count + 2*izd_count + mach_count - 1 then "\n" endif | i in 0..time, j in -1..(mach_count + 2*izd_count + mach_count - 1)];

% Вывод для скрипта
output ["\n\n"];
output [show (time)++" "++show(mach_count)++"\n"];
output [show(machine_oper[t,m]) ++ (if m==mach_count then "\n" else " " endif) | t in 0..time, m in 1..mach_count]