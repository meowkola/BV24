'''
Расписание рабочих распределяя их по станкамЮ учитывая операции которые они выполняют
'''
import pulp

# Входные данные
num_workers = 2
num_machines = 2
num_operations = 2

#Пример
# Матрица смежности операций ко времени их выполнения
time_operation_matrix = [
[1, 0, 1], [2, 0, 1], [3, 1, 1], [4, 1, 1], [5, 1, 1], [6, 1, 1], [7, 1, 0], [8, 1, 0], [9, 1, 0], [10, 1, 0], [11, 1, 0], [12, 1, 0], [13, 1, 0], [14, 1, 0], [15, 1, 0], [16, 1, 0], [17, 1, 0], [18, 1, 0], [19, 1, 0], [20, 1, 0]
]

# Матрица смежности операций и станков
operation_machine_matrix = [
    [1, 1, 0],
    [2, 1, 1],
    [1, 2, 1],
    [2, 2, 0]
]

# Матрица смежности рабочих и станков
worker_machine_matrix = [
    [1, 1, 1],
    [1, 2, 0],
    [2, 1, 0],
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

# Ограничение: рабочий может работать только на одном станке в один момент времени
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
print('schedule')
# Вывод матрицы ans
for t in range(time_intervals):
    print(f"Time {time_operation_matrix[t][0]}: {ans[t]}")
