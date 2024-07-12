'''
Создание модели, решающая проблему рационального планирования.
Распределяющая работников по станкам, также учитывая тип изделия которые они обрабатывают

@Timur
'''
import pulp

# Ввод данных
num_workers = int(input("Введите количество рабочих: "))
num_machines = int(input("Введите количество станков: "))
num_item_types = int(input("Введите количество типов изделий: "))
T = 8 * 60  # максимальное время работы одного сотрудника в минутах

# Инициализация времени обработки
processing_times = {}

print("Введите время обработки в формате 'worker machine item time'. Для завершения введите 'done'.")
while True:
    data = input()
    if data.lower() == 'done':
        break
    w, m, z, t = map(int, data.split())
    # Преобразование в индексацию с 0
    processing_times[(w-1, m-1, z-1)] = t

# Количество деталей каждого типа
num_items = []
print("Введите количество деталей каждого типа через пробел:")
num_items = list(map(int, input().split()))

# Модель
model = pulp.LpProblem("EntOptimization", pulp.LpMinimize)

# Переменные
x = pulp.LpVariable.dicts("x", ((w, m, z) for w in range(num_workers) for m in range(num_machines) for z in range(num_item_types)), 0, None, pulp.LpInteger)
max_time = pulp.LpVariable("max_time", 0, None, pulp.LpInteger)

# Целевая функция
model += max_time

# Ограничения
for z in range(num_item_types):
    i=z
    model += pulp.lpSum([x[w, m, z] for w in range(num_workers) for m in range(num_machines)]) == num_items[i]

for w in range(num_workers):
    for m in range(num_machines):
        model += pulp.lpSum([processing_times.get((w, m, z), 0) * x[w, m, z] for z in range(num_item_types)]) <= T

# Ограничения для уникальности работников на каждом станке
for m in range(num_machines):
    model += pulp.lpSum([x[w, m, z] for w in range(num_workers) for z in range(num_item_types)]) >= 1  # На каждом станке должен работать хотя бы один рабочий

# Ограничение на максимальное время обработки всех изделий типа 1
for w in range(num_workers):
    for m in range(num_machines):
        model += pulp.lpSum([processing_times.get((w, m, 0), 0) * x[w, m, 0] for w in range(num_workers)]) <= max_time

# Решение модели
model.solve()
print('\nпланирвание по РАБОЧИМ:')
# Вывод результатов
total_time = 0
total_day = 0
for z in range(num_item_types):
    item_time = 0
    for w in range(num_workers):
        day=0
        for m in range(num_machines):
            day+=1
            total_day=day
            if pulp.value(x[w, m, z]) > 0:
                time_spent = processing_times.get((w, m, z), 0) * pulp.value(x[w, m, z])
                item_time += time_spent
                print(f"рабочий {w+1} на станке {m+1} обрабатывает {int(pulp.value(x[w, m, z]))} изделий типа {z+1} за {time_spent} минут в {day} день")
    total_time += item_time

# Вывод информации о станках и рабочих
print("\nпланирование по СТАНКАМ")
for m in range(num_machines):
    for w in range(num_workers):
        for z in range(num_item_types):
            if pulp.value(x[w, m, z]) > 0:
                print(f"станок {m+1}: Рабочий {w+1} обрабатывает изделия типа {z+1}")
                break

# Вывод времени обработки всех изделий типа 1
print(f"\nминимальное время для обработки всех изделий типа 1: {pulp.value(max_time)} минут за {total_day} дней")
