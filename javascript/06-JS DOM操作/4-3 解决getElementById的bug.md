# 3.2 解决getElementById()的bug



ie浏览器 可能会有具有相同名字的id和name的控件，引起的bug，**可能会先拿到name的属性**

解决思路就是判断是否是ie浏览器，如果是ie浏览器的话，判断控件的id的属性是否==id，如果相等，就返回控件，如果不相等，就把所有id的属性节点全取出来进行遍历，如果有id === id就返回该元素

![image-20210706051155812](/home/stevenzhang/home/git/gitbook_backup/image/image-20210706051155812.png)





