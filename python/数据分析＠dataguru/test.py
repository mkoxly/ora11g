# -*- coding: gbk -*-


"""
Created on Fri Apr 01 11:36:48 2016
utf-8

@author: Administrator
"""

a=[]
b=()
a.append(10)
a[0]=5
print a
b=tuple(a)
print b[0]
print '未来'
import os
print os.defpath
a=[ 'a','b' ]
print a
print "-".join(a)
n=1234
def fun(n):
 return ''.join(map(lambda x :str((int(x)+5)%10),str(n)[::-1]))
print fun(fun(1234))
b=[i for i in range(0,101)]
print reduce(lambda x,y:x+y,[ i for i in range(1,101)])

