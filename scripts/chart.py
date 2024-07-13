import pandas as pd
import altair as alt

# Данные с несколькими интервалами для одного продукта и своим текстом
source = pd.DataFrame([
    {"products": "machine1", "start_time": 1, "end_time": 3, "text": "Стол"},
    {"products": "machine1", "start_time": 4, "end_time": 6, "text": "Стул"},
    {"products": "machine2", "start_time": 3, "end_time": 5, "text": "Дверь"}, 
    {"products": "machine2", "start_time": 6, "end_time": 8, "text": "Шкаф"},
    {"products": "machine3", "start_time": 8, "end_time": 10, "text": "Кровать"},
    {"products": "machine4", "start_time": 10, "end_time": 12, "text": "Стол"},
    {"products": "machine5", "start_time": 12, "end_time": 14, "text": "Стул"},
    {"products": "machine6", "start_time": 14, "end_time": 16, "text": "Стул"},
])

# Основная диаграмма 
bars = alt.Chart(source).mark_bar().encode(
    alt.X('start_time:Q', title="Время"),
    alt.X2('end_time:Q'),  # Используется для определения конца бара
    alt.Y('products:N', title="Продукты"),
    alt.Color('products:N')
).properties(
    width=600,
    height=300
)

# Текстовые метки внутри прямоугольников
text = alt.Chart(source).mark_text(
    align='left',
    baseline='middle',
    dx=20,  # смещение текста вправо
    dy=2  # смещение текста вниз
).encode(
    x=alt.X('start_time:Q', title="Время"),
    y=alt.Y('products:N', title="Продукты"),
    text='text:N'  # Использование столбца с текстом
)

# Комбинация баров и текста
chart = bars + text
chart
