import sys
import seaborn
import pandas as pd

df = pd.read_csv('read_summary.txt', sep='\t', names=['chr', 'read', 'num', 'meth_pct'])
df_filtered = df[df['chr'] != 'none']

seaborn.set(style = 'whitegrid') 
plot = seaborn.violinplot(x=df_filtered['chr'], y=df_filtered['meth_pct'], data=df_filtered, linewidth=0.5, inner='point', cut=0)
plot.figure.savefig("output.png")
