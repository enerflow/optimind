import pandas as pd




load = pd.read_excel('./certh_energy.xlsx', header = 0,sheet_name='Consumption(W)') 
load['Timestamp'] = load['Timestamp'].str[:-31]
load['Timestamp'] = load['Timestamp'].str.replace(r'GMT', '')
load['Timestamp'] = pd.to_datetime(load['Timestamp'])
load = load.set_index('Timestamp')
load = load.rename(columns={"Active Power Total (W)": "Load (W)"})



generation = pd.read_excel('./certh_energy.xlsx', header = 0,sheet_name='Generation(W)') 
generation['Timestamp'] = generation['Timestamp'].str[:-31]
generation['Timestamp'] = generation['Timestamp'].str.replace(r'GMT', '')
generation['Timestamp'] = pd.to_datetime(generation['Timestamp'])
generation = generation.set_index('Timestamp')
generation = generation.rename(columns={"Active Power Total (W)": "Generation (W)"})


df = load.join(generation, on='Timestamp')

df.to_csv('certh_energy.csv', index=True)  