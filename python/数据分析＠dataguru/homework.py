# -*- coding: gbk -*-
"""
Created on Tue Apr 12 16:35:17 2016

@author: Administrator
"""
import numpy as np
def fun1():
    f=r'E:\BaiduYunDownload\python数据分析\第4周\ag0613.csv'
    #print f
    l=np.loadtxt(f,delimiter=',',skiprows=1)
    print "最大值:",l.max()
    print "最小值:",l.min()
    print "均值:",l.mean()
    print "标准差:",l.std()
    print "中位数:",np.median(l)
fun1()
def fun2():
    a=np.array([[1,2],[3,4]])
    b=np.array([[2,5],[1,3]])
    print a
    print b
    print "矩阵乘法a*b="
    print a.dot(b)
fun2() 
def fun3():
    a=np.random.randn(100)
    print "均值:",a.mean()
    print "标准差:",a.std() 
fun3()