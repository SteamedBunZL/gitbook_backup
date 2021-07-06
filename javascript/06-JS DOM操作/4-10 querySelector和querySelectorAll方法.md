# 3.7 querySelector()和querySelectorAll()方法



![image-20210706054025228](../../image/image-20210706054025228.png)



## querySelector



主流的浏览器基本都支持，传入#myUl 这是css的id



![image-20210706054135297](../../image/image-20210706054135297.png)







![image-20210706054150315](../../image/image-20210706054150315.png)





找最后一个li

![image-20210706054236313](../../image/image-20210706054236313.png)



![image-20210706054306968](../../image/image-20210706054306968.png)



querySelector只能找到一个元素，所以它找到input元素就返回了

要想找到所有的元素，要使用querySelectorAll方法

![image-20210706054423142](../../image/image-20210706054423142.png)

找不存在的元素

![image-20210706054441396](../../image/image-20210706054441396.png)



通过class的值来获取元素对象

![image-20210706054553358](../../image/image-20210706054553358.png)



![image-20210706054604007](../../image/image-20210706054604007.png)



但是class中不能有违规字符，要不会报错，必须进行转义，：转义成\: 但是\也是违规的，所以再加\

![image-20210706054708723](../../image/image-20210706054708723.png)



![image-20210706054716726](../../image/image-20210706054716726.png)



## querySelectorAll



![image-20210706054928027](../../image/image-20210706054928027.png)

获取到的是NodeList

试图获取一个不存在的元素



![image-20210706055037813](../../image/image-20210706055037813.png)



![image-20210706055047639](../../image/image-20210706055047639.png)



虽然获取的是NodeList 类数组对象，但是不是纯正的NodeList是静态的NodeList  之前有说到NodeList具有动态性，但是静态的NodeList不具有





![image-20210706055249827](../../image/image-20210706055249827.png)



这段代码使用querySelectorAll来动态添加，是不会进入死循环的







