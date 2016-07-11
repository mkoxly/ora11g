# -*- coding: utf-8 -*-
"""
Created on Mon Jun 13 15:40:18 2016

@author: Administrator
"""
from __future__ import division
import sys
sys.path.append('C:\Anaconda2\Lib')
sys.path.append('C:\\Anaconda2\\Scripts')
sys.path.append('C:\\Anaconda2\\lib\\site-packages')
sys.path.append('C:\\Anaconda2')
for i in sys.path :
    print i
from numpy.random import randn
import numpy as np
from pandas import Series, DataFrame
import pandas as pd

pd.options.display.max_rows = 12
np.set_printoptions(precision=4, suppress=True)
import matplotlib.pyplot as plt
from numpy.random import randn
pd.options.display.max_rows = 12
np.set_printoptions(precision=4, suppress=True)
import matplotlib.pyplot as plt
plt.rc('figure', figsize=(12, 4))
from datetime import datetime
from datetime import timedelta
from dateutil.parser import parse
from pandas.tseries.offsets import Hour, Minute
from scipy.stats import percentileofscore
from statsmodels.graphics.tsaplots import plot_acf
from statsmodels.tsa.stattools import adfuller as ADF
from statsmodels.graphics.tsaplots import plot_pacf
from statsmodels.stats.diagnostic import acorr_ljungbox
from statsmodels.tsa.arima_model import ARIMA


####时序案例分析####
#参数初始化
dir = u'E:\BaiduYunDownload\python数据分析\第12周\\'
discfile = dir+'stock_px.csv'
forecastnum = 5

#读取数据，指定日期列为指标，Pandas自动将“日期”列识别为Datetime格式
data = pd.read_csv(discfile, index_col = 0)
data = pd.DataFrame(data,dtype=np.float64)
data

#时序图
plt.rcParams['font.sans-serif'] = ['SimHei'] #用来正常显示中文标签
plt.rcParams['axes.unicode_minus'] = False #用来正常显示负号
data.plot()
plt.show()

#自相关图
from statsmodels.graphics.tsaplots import plot_acf
plot_acf(data).show()

#平稳性检测
from statsmodels.tsa.stattools import adfuller as ADF
print( ADF(data[u'销量']))
#返回值依次为adf、pvalue、usedlag、nobs、critical values、icbest、regresults、resstore

#差分后的结果
D_data = data.diff().dropna()
D_data.columns = [u'销量差分']
D_data.plot() #时序图
plt.show()
plot_acf(D_data).show() #自相关图
from statsmodels.graphics.tsaplots import plot_pacf
plot_pacf(D_data).show() #偏自相关图
ADF(D_data[u'销量差分'])#平稳性检测

#白噪声检验
from statsmodels.stats.diagnostic import acorr_ljungbox
acorr_ljungbox(D_data, lags=1) #返回统计量和p值

from statsmodels.tsa.arima_model import ARIMA

#定阶
pmax = int(len(D_data)/10) #一般阶数不超过length/10
qmax = int(len(D_data)/10) #一般阶数不超过length/10
bic_matrix = [] #bic矩阵
for p in range(pmax+1):
  tmp = []
  for q in range(qmax+1):
    try: #存在部分报错，所以用try来跳过报错。
      tmp.append(ARIMA(data, (p,1,q)).fit().bic)
    except:
      tmp.append(None)
  bic_matrix.append(tmp)

bic_matrix = pd.DataFrame(bic_matrix) #从中可以找出最小值

p,q = bic_matrix.stack().idxmin() #先用stack展平，然后用idxmin找出最小值位置。
print(u'BIC最小的p值和q值为：%s、%s' %(p,q)) 
model = ARIMA(data, (0,1,1)).fit() #建立ARIMA(0, 1, 1)模型
model.summary() #给出一份模型报告
model.forecast(5) #作为期5天的预测，返回预测结果、标准误差、置信区间。