# 2-6 高效创建节点的方法(innerHTML-outerHTML)



![image-20210704132849472](../../image/image-20210704132849472.png)



![image-20210704134817068](../../image/image-20210704134817068.png)

![image-20210704134836251](../../image/image-20210704134836251.png)

> 使用innerHTML注意 写模式并不会替换content的div标签 它只会在div内新增



![image-20210704135007176](../../image/image-20210704135007176.png)

![image-20210704135047806](../../image/image-20210704135047806.png)

> 使用outterHTML 的写模式，会把外层的content的标签div给去掉，这就是和innerHTML的区别



> 当然读的模式也是类似的innderHTML 会带有div标签  而outterHTML不会带div标签
