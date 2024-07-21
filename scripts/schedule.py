import pulp

# Входные данные
num_workers = 2
num_machines = 2
num_operations = 2

serv = [
    [1, 0, 0],
    [2, 0, 0],
    [3, 0, 0],
    [4, 0, 0],
    [5, 0, 1],
    [6, 1, 1],
    [7, 1, 0],
    [8, 1, 0],
    [9, 0, 0],
    [10, 0, 0],
    [11, 0, 0],
    [12, 0, 0],
    [13, 0, 0],
    [14, 0, 0],
    [15, 0, 0],
    [16, 0, 0],
    [17, 0, 0],
    [18, 0, 0],
    [19, 0, 0],
    [20, 0, 0],
    [21, 0, 0],
    [22, 0, 0],
    [23, 0, 0],
    [24, 0, 0],
    [25, 0, 0],
    [26, 0, 0],
    [27, 0, 0],
    [28, 0, 0],
    [29, 0, 0]
]
# Матрица смежности операций ко времени их выполнения
time_operation_matrix = [
    [1, 0, 1],
    [2, 0, 1],
    [3, 1, 1],
    [4, 1, 1],
    [5, 1, 1],
    [6, 1, 1],
    [7, 1, 0],
    [8, 1, 0],
    [9, 1, 0],
    [10, 1, 0],
    [11, 1, 0],
    [12, 1, 0],
    [13, 1, 0],
    [14, 1, 0],
    [15, 1, 0],
    [16, 1, 0],
    [17, 1, 0],
    [18, 1, 0],
    [19, 1, 0],
    [20, 1, 0],
    [21, 1, 0],
    [22, 1, 0],
    [23, 1, 0],
    [24, 1, 0],
    [25, 1, 0],
    [26, 1, 0],
    [27, 1, 0],
    [28, 0, 0],
    [29, 0, 0]
]

# Матрица смежности операций и станков
operation_machine_matrix = [
    [1, 1, 1],
    [2, 1, 1],
    [1, 2, 1],
    [2, 2, 1]
]

# Матрица смежности рабочих и станков
worker_machine_matrix = [
    [1, 1, 1],
    [1, 2, 1],
    [2, 1, 1],
    [2, 2, 1]
]

# Временные параметры
time_intervals = len(time_operation_matrix)

prob = pulp.LpProblem("Work_Scheduling", pulp.LpMaximize)

x = pulp.LpVariable.dicts("x", ((i, t, j, k) for i in range(num_workers) 
                                        for t in range(time_intervals)
                                        for j in range(num_machines) 
                                        for k in range(num_operations)), 
                          cat='Binary')

# Целевая функция: максимизация количества выполненных операций
prob += pulp.lpSum(x[i, t, j, k] for t in range(time_intervals)
                                 for j in range(num_machines)
                                 for k in range(num_operations)
                                 for i in range(num_workers))

# Ограничения:
for i in range(num_workers):
    for t in range(time_intervals):
        for j in range(num_machines):
            for k in range(num_operations):
                operation_active = time_operation_matrix[t][k + 1]
                if operation_active == 0 or worker_machine_matrix[i * num_machines + j][2] == 0 or operation_machine_matrix[j * num_operations + k][2] == 0:
                    prob += x[i, t, j, k] == 0

# Ограничение: рабочий не может работать больше 14 тактов подряд, нужен отдых в 4 такта
max_work_period = 14
rest_period = 4

for i in range(num_workers):
    for t in range(time_intervals - max_work_period - rest_period + 1):
        prob += pulp.lpSum(x[i, t_prime, j, k] for t_prime in range(t, t + max_work_period + 1)
                                               for j in range(num_machines)
                                               for k in range(num_operations)) <= max_work_period

# Ограничение: один рабочий может выполнять только одну операцию на одном станке в один момент времени
for t in range(time_intervals):
    for j in range(num_machines):
        prob += pulp.lpSum(x[i, t, j, k] for i in range(num_workers)
                                        for k in range(num_operations)) <= 1

# Ограничение: рабочий должен потратить хотябы один временной промежуток на переход между станками
for i in range(num_workers):
    for j in range(num_machines):
        for t in range(time_intervals):
            if pulp.value(x[i, t, j, k])==1 and  pulp.value(x[i, (t+1), j, k])==1:
                prob += x[i, (t+1), j, k] == 0

for i in range(num_workers):
    for t in range(time_intervals):
        prob += pulp.lpSum(x[i, t, j, k] for j in range(num_machines)
                                        for k in range(num_operations)) <= 1

# Ограничение: одна операция может выполняться только одним рабочим в один момент времени
for t in range(time_intervals):
    for k in range(num_operations):
        prob += pulp.lpSum(x[i, t, j, k] for i in range(num_workers)
                                        for j in range(num_machines)) <= 1

# Решение задачи
prob.solve()

# Создание и заполнение матрицы ans
ans = [[None for _ in range(num_workers)] for _ in range(time_intervals)]
ans_machines = [[None for _ in range(num_machines)] for _ in range(time_intervals)]
for t in range(time_intervals):
    for k in range(num_operations):
        for j in range(num_machines):
            for i in range(num_workers):
                if pulp.value(x[i, t, j, k]) == 1:
                    ans[t][i] = (j + 1, k + 1)

# Заполнение пустых ячеек "rest"
for t in range(time_intervals):
    for i in range(num_workers):
        if ans[t][i] is None:
            ans[t][i] = "rest"

for t in range(1, time_intervals+1):
    if t == time_intervals:
        break
    for j in range(1, num_machines+1):
        if serv[t][j] == 1:
            ans[t][j-1] = "tech_work4mach"

for t in range(time_intervals):
    for k in range(num_operations):
        for i in range(num_workers):
            for j in range(num_machines):
                if pulp.value(x[i, t, j, k]) == 1:
                    ans_machines[t][j] = (k + 1, i + 1)

# Заполнение пустых ячеек "service"
for t in range(time_intervals):
    for j in range(num_machines):
        if ans_machines[t][j] is None:
            ans_machines[t][j] = "no work"

for t in range(1, time_intervals+1):
    if t == time_intervals:
        break
    for j in range(1, num_machines+1):
        if serv[t][j] == 1:
            ans_machines[t][j-1] = "tech_work"

print('schedule for workers')
# Вывод матрицы ans
for t in range(time_intervals):
    print(f"Time {time_operation_matrix[t][0]}: {ans[t]}")
print("\n")
print('schedule for machines')
for t in range(time_intervals):
    print(f"Time {time_operation_matrix[t][0]}: {ans_machines[t]}")
