def numtolist(num):
    a=[]
    n=num
    i=0
    while n>9:
       a.append(n%10)
       n=n/10
       i+=1
    a.append(n)
    a.reverse()    
    return a
def listtonum(list):
    return 10000*list[0]+1000*list[1]+100*list[2]+10*list[3]+list[4]
def encode(num):
    if num<10000 or num>99999 :
        raise
    nums=list(numtolist(num))
    for i in range(5):
        nums[i]=(nums[i]+5)%10
    ret=[]
    ret.append(nums[0])
    ret.append(nums[4])
    ret.append(nums[3])
    ret.append(nums[2])
    ret.append(nums[1])
    return listtonum(ret)
def decode(num):
    nums=numtolist(num)
    ret=[]
    ret.append(nums[0])
    ret.append(nums[4])
    ret.append(nums[3])
    ret.append(nums[2])
    ret.append(nums[1])
    for i in range(5):
        ret[i]=(ret[i]+5)%10
    return listtonum(ret)     
print encode(12534)
print decode(encode(12534))

