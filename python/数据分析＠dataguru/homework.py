# -*- coding: gbk -*-
"""
Created on Tue Apr 12 16:35:17 2016

@author: Administrator
"""
import numpy as np
def fun1():
    f=r'E:\BaiduYunDownload\python���ݷ���\��4��\ag0613.csv'
    #print f
    l=np.loadtxt(f,delimiter=',',skiprows=1)
    print "���ֵ:",l.max()
    print "��Сֵ:",l.min()
    print "��ֵ:",l.mean()
    print "��׼��:",l.std()
    print "��λ��:",np.median(l)
fun1()
def fun2():
    a=np.array([[1,2],[3,4]])
    b=np.array([[2,5],[1,3]])
    print a
    print b
    print "����˷�a*b="
    print a.dot(b)
fun2() 
def fun3():
    a=np.random.randn(100)
    print "��ֵ:",a.mean()
    print "��׼��:",a.std() 
fun3()