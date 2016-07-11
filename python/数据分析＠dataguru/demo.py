# -*- coding: utf-8 -*-
"""
Created on Wed Apr 06 10:42:29 2016

@author: Administrator
"""

import numpy as np
a1 = np.array(range(10))
print type(a1)
#print dir(a1)
print a1.dtype
print np.asarray("abc")
print np.ones([5,5])
print np.ones_like(a1)
print np.eye(6,dtype=int32)
print np.identity(100)
