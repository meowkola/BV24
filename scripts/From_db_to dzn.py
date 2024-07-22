import psycopg2
from config import host, user, password, db_name
import pandas as pd
import numpy as np

try:
    # connect to exist database
    connection = psycopg2.connect(
        host=host,
        user=user,
        password=password,
        database=db_name
    )
    connection.autocommit = True

    with connection.cursor() as cursor:
        cursor.execute("SELECT version();")
        print(f"Server version: {cursor.fetchone()[0]}")

        cursor.execute("SELECT id, name FROM commodity;")
        commodity = pd.DataFrame(cursor.fetchall(), columns=['id', 'name'])

        cursor.execute("SELECT workers_id, machines_id FROM workers_machines")
        workers_machines = pd.DataFrame(cursor.fetchall(), columns=['workers_id', 'machines_id'])

        cursor.execute("SELECT id, type, name FROM machines")
        machines = pd.DataFrame(cursor.fetchall(), columns=['id', 'type', 'name'])

        cursor.execute("SELECT id, amount, name FROM workers")
        workers = pd.DataFrame(cursor.fetchall(), columns=['id', 'amount', 'name'])

        cursor.execute("SELECT id, long, type, cost, name, machines_id  FROM operations")
        operations = pd.DataFrame(cursor.fetchall(), columns=['id', 'long', 'type', 'cost', 'name', 'machines_id'])

        cursor.execute("SELECT id, operation, op_time FROM plan")
        plan = pd.DataFrame(cursor.fetchall(), columns=['id', 'operation', 'op_time'])

        cursor.execute("SELECT id, name, specification FROM item")
        item = pd.DataFrame(cursor.fetchall(), columns=['id', 'name', 'specification'])

        cursor.execute("SELECT amount_input, direction, operations_id, item_id_input, amount_output, item_id_output FROM operations_item")
        operations_item = pd.DataFrame(cursor.fetchall(), columns=['amount_input', 'direction', 'operations_id', 'item_id_input', 'amount_output', 'item_id_output'])

        cursor.execute("SELECT amount, plan_id, item_id FROM plan_item")
        plan_item = pd.DataFrame(cursor.fetchall(), columns=['amount', 'plan_id', 'item_id'])

        cursor.execute("SELECT amount, item_id, commodity_id FROM commodity_item")
        commodity_item = pd.DataFrame(cursor.fetchall(), columns=['amount', 'item_id', 'commodity_id'])

        cursor.execute("SELECT amount, plan_id, commodity_id FROM plan_commodity")
        plan_commodity = pd.DataFrame(cursor.fetchall(), columns=['amount', 'plan_id', 'commodity_id'])

        cursor.execute("SELECT id, cost, run_id, time FROM iorder")
        iorder = pd.DataFrame(cursor.fetchall(), columns=['id', 'cost','run_id', 'time'])

        cursor.execute("SELECT amount, order_id, commodity_id FROM iorder_commodity")
        iorder_commodity = pd.DataFrame(cursor.fetchall(), columns=['amount', 'order_id', 'commodity_id'])

        cursor.execute("SELECT item_id, amount FROM start_store")
        start_store = pd.DataFrame(cursor.fetchall(), columns=['item_id', 'amount'])

        time = iorder['time'].max()
        max_izd = 52
        op_count = operations.shape[0]
        izd_count = item.shape[0]
        commodity_count = commodity.shape[0]
        op_len = np.array(operations['long'].values)
         
        izd_start = np.array(start_store['amount'].values)

        pre_izd_mach = operations[['id', 'machines_id']]
        pre_izd_mach['value'] = 1

        
        mach_count = machines.shape[0]
        mach = pd.pivot_table(pre_izd_mach, values='value', index='machines_id', columns='id', fill_value=0)
        mach = np.array(mach).astype(int)
        
        
        op_out = pd.pivot_table(operations_item, values= 'amount_output', index = 'operations_id', columns= 'item_id_output', fill_value= 0)
        op_in  = pd.pivot_table(operations_item, values= 'amount_input', index = 'operations_id', columns= 'item_id_input', fill_value= 0)
        op_out = np.array(op_out).astype(int)
        op_in = np.array(op_in).astype(int)
        
        

        # создание дедлайнов
        order_array = np.zeros((time, commodity_count), dtype = int)
        order = pd.merge(iorder_commodity, iorder, left_on='order_id',right_on='id',how='left')
        
        orderl = pd.pivot_table(order, values='amount', index = 'time', columns='commodity_id', fill_value = 0)
        
        new_index = range(0, time+1)
        new_columns = range(0,izd_count+1)
        orderl = orderl.reindex(index = new_index, columns=new_columns, fill_value= 0)
        delivery = np.array(orderl).astype(int)
        


        
        mt_len = [1,2]
        max_damage = [2,2]

        doing_add = np.random.randint(2, size= (time, izd_count))
            

        filename = "data.dzn"
        with open(filename, "w") as file:
            file.write(f"time = {int(time)};\n")
            file.write(f"op_count = {int(op_count)};\n")
            file.write(f"izd_count = {int(izd_count)};\n")
            file.write(f"max_izd = {int(max_izd)};\n")
            
            file.write(f"op_len = [{', '.join(map(str, op_len))}];\n")

            file.write("op_in = array2d(1..op_count, 1..izd_count, [\n")
            for row in op_in:
                file.write(f"    {', '.join(map(str, row))},\n")
            file.write("]);\n")



            file.write("op_out = array2d(1..op_count, 1..izd_count, [\n")
            for row in op_out:
                file.write(f"    {', '.join(map(str, row))},\n")
            file.write("]);\n")
            file.write(f"izd_start = [{', '.join(map(str, izd_start))}];\n")
            file.write(f"mach_count = {int(mach_count)};\n")
            file.write("mach = array2d(1..mach_count, 1..op_count, [\n")
            for row in mach:
                file.write(f"    {', '.join(map(str, row))},\n")
            file.write("]);\n")
            file.write("delivery = array2d(1..time, 1..izd_count, [\n")
            for row in delivery:
                file.write(f"    {', '.join(map(str, row))},\n")
            file.write("]);\n")

            file.write(f"mt_len = [{', '.join(map(str, mt_len))}];\n")
            file.write(f"max_damage = [{', '.join(map(str, max_damage))}];\n")

            file.write("doing_add = array1d(0..time, [1,")
            for row in doing_add:
                file.write(f"    {', '.join(map(str, row))},\n")
            file.write("]);\n")
            





    


        
        

        

except Exception as _ex:
    print("[INFO] Error while working with PostgreSQL", _ex)
finally:
    if connection:
        connection.close()
        print("[INFO] PostgreSQL connection closed")
