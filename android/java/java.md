# Java





### 9.equals hashcode 为什么要重写他们



### 10.解析Java中的内存模型

![image-20210509160645209](/Users/zhanglong/Library/Application Support/typora-user-images/image-20210509160645209.png)

执行任务时,cpu会先将运算所需要使用的数据复制到高速缓存中,当运算结束后,再将缓存结果刷回主内存.当多个处理器同时操作主内存时,可能导致数据不一致,这就是缓存不一致问题

![image-20210509160944860](/Users/zhanglong/Library/Application Support/typora-user-images/image-20210509160944860.png)

除了缓存一致性问题外,还有指令重排的问题.指令重排比较严重的问题是著名的DCL 问题

内存模型本质上是一套规范,在这套规范中有一条最重要的happens-before原则

把 happen before 定义为方法
hb(a,b）， 表示 a happen before b。如果 hb(a , b ） 且 hb(b , c）， 能够推导出 hb(a , c） 。



### 11.DCL 单例问题,最优的单例写法(静态内部类)

懒汉式

```java
class LazyInitDemo{
  
  private int i = 0;
  
  private static (volatile) TransactionService service = null;
  public static TransactionService getTransactionService(){
    if(service == null){
      synchronized(this){
        if(service == null){
          service = new TransactionService();
        }
      }
    }
    return service;
  }
}
```

使用者在调用getTransactionService()时,可能会得到初始化未完成的对象.究其原因,与java编译器的优化有关,对于java编译器而言,new TransactionService()这个操作 和service = new TransactionService()并不是原子的 也就是说TranscationService的构造方法可能还没有执行完成 先为引用service分配了内存空间,并赋给了默认值. 这样就出现了

如果两个线程,一个线程在执行初始化,但还没有完成,另一个线程判断到service!=null 然后它会执行return service 返回的service并未赋予真正的有效值,导致用户可能获得未构造完成的对象.

一种较为简单的解决方案是加上volatile来修饰service,这样就限制了编译器对它的相关读写操作;对它的读写操作进行指令重排,确定实例化后才返回引用



### 11.双亲委派机制是什么?为什么要这么设计(好处)?

加载.class文件时,以递归的形式逐级向上委托给父加载器parentClassLoader去加载,如果加载过了,就不用再加载一遍

如果父类加载器也没加载过,则继续委托给父加载器去加载,一直到这条链路的顶级,顶级classloader判断如果没加载过,则尝试加载,加载失败,则逐级向下交还调用者来加载.

![image-20210509173230855](/Users/zhanglong/Library/Application Support/typora-user-images/image-20210509173230855.png)

**双亲委派的作用**

- 防止同一个.class重复加载(就算我们自定义了一个类加载器去加载String.class文件,它也会先交由父类去加载,发现父类已经加载过了,就不再加载,保证了类加载不重复)
- 确保类在虚拟机中的唯一性(同一个类由两个不同的类加载器加载出来的类不是同一个,类的唯一性由它的加载器和全类名来确立)
- 保证系统类.class文件不能被篡改.通过委托方式可以保证系统类的加载逻辑不被篡改



### 12.PahtClassLoader&DexClassLoader有何异同?

PathClassLoader 复杂的加载系统类和应用程序的类,通常用来加载已安装的apk的dex文件,实际上外部存储的dex文件也能加载.

DexClassLoader:可以加载dex文件以及包含dex的压缩文件(apk,dex,jar,zip)

BaseDexClassLoader:实现应用层类文件的加载,而真正的加载逻辑委托给PathList来完成

BootClassLoader:Android平台上所有ClassLoader的最终parent.Android系统启动时会使用BootClassLoader来预加载常用类,我们用不了



pathclassloader&Dexclassloader虽然继承了BaseDexClassLoader但实际上没有覆写 loadClass和findClass 实际上啥事没干

为什么还在搞出来这两个类呢?  由于历史原因







### 13.为什么静态方法中不能调用非静态变量?





### 12.Android中的双亲委派及热修复原理



所以主要由BaseDexClassLoader的加载  它的findClass 和findResource 具体又转交给了DexpathList来实现  执行dexpathlist.findclass

DexPahtList中dexElements []

当想加载MainActiviy这个类时 会去dexElements数组(.dex)中去遍历dex文件 找出类在哪个dex文件中

第一点,如果mainactivity在最后一个dex中,会很耗时间,所以我们在做启动优化的时候,需要把首页及其引用的类,都打包到第一个.dex文件上

![image-20210509175505330](/Users/zhanglong/Library/Application Support/typora-user-images/image-20210509175505330.png)

第二点,如果patch.dex和classes.dex都包含MainActivity.class 那么会如何加载呢?

它会按顺序去加载, 而且只加载一次,所以基于这点成了热修复的基础

![image-20210509175752874](/Users/zhanglong/Library/Application Support/typora-user-images/image-20210509175752874.png)







### 13.Class 类加载问题





### 13.如何确定对象是垃圾?

可达性分析法,从GC ROOT作为起点,向下搜索,搜索走过的路径为引用链,判断引用链的是否可达来判断对象可以被回收.

GC Root 对象

在 Java 中，有以下几种对象可以作为 GC Root：

- Java 虚拟机栈（局部变量表）中的引用的对象。

- 方法区中静态引用指向的对象。

- 仍处于存活状态中的线程对象。

- Native 方法中 JNI 引用的对象。

### 14.GC 回收机制与分代回收策略

**标记清除算法**

![image-20210509165316085](/Users/zhanglong/Library/Application Support/typora-user-images/image-20210509165316085.png)

**复制算法**

1.复制算法之前，内存分为 A/B 两块，并且当前只使用内存 A，内存的状况如下图所示：

![image-20210509165438748](/Users/zhanglong/Library/Application Support/typora-user-images/image-20210509165438748.png)

2.标记完之后，所有可达对象都被按次序复制到内存 B 中，并设置 B 为当前使用中的内存。内存状况如下图所示：

![image-20210509165506555](/Users/zhanglong/Library/Application Support/typora-user-images/image-20210509165506555.png)

- 优点：按顺序分配内存即可，实现简单、运行高效，不用考虑内存碎片。

- 缺点：可用的内存大小缩小为原来的一半，对象存活率高时会频繁进行复制。

**标记-压缩算法** 

![image-20210509165619486](/Users/zhanglong/Library/Application Support/typora-user-images/image-20210509165619486.png)

**分代回收策略**

分代回收的中心思想就是：对于新创建的对象会在新生代中分配内存，此区域的对象生命周期一般较短。如果经过多次回收仍然存活下来，则将它们转移到老年代中。

![image-20210509165857477](/Users/zhanglong/Library/Application Support/typora-user-images/image-20210509165857477.png)

当**eden**区第一次满时,会进行垃圾回收.会将**eden**区的垃圾进行回收清除,将存活对象转移到**S0**,此时**S1**是空的

![image-20210509170109155](/Users/zhanglong/Library/Application Support/typora-user-images/image-20210509170109155.png)

下一次**eden**区满的时候,会将eden和**S0**的垃圾对象清除,将存活的对象转移到**S1**.**S0**变为空

![image-20210509170234739](/Users/zhanglong/Library/Application Support/typora-user-images/image-20210509170234739.png)

如此反复在**S0**和**S1**中来回切换,多次之后,默认是15次之后,会把还存活的对象,转移到**老年代**

![image-20210509170531699](/Users/zhanglong/Library/Application Support/typora-user-images/image-20210509170531699.png)

老年代内存大小比新生代大,如果一些大的对象,并且新生代内存不足,大对象会被直接分配到老年代

老年代生命周期较长,不需要过多的复制操作,所以一般采用标记压缩的回收算法



> 注意：对于老年代可能存在这么一种情况，老年代中的对象有时候会引用到新生代对象。这时如果要执行新生代 GC，则可能需要查询整个老年代上可能存在引用新生代的情况，这显然是低效的。所以，老年代中维护了一个 512 byte 的 **card table**，所有老年代对象引用新生代对象的信息都记录在这里。每当**新生代发生 GC** 时，只需要检查这个 card table 即可，大大提高了性能。



### 14.GC LOG的具体分析

//TODO

### 15.DVM以及ART 是如何对JVM进行优化的

//TODO





## 线程 相关



10.死锁的类型及解决方案



11.Java Synchronized锁优化



10.Synchronized 与 volatile ReetrantLock之间的区别



11.AQS与CAS





### 12.线程池各参数的意义



### 13.线程池复用线程的原理

















### 1.将int转为string；

### 2.将两个有序的数组合并为一个有序的数组；

### 3.Java基础，几种排序，Android基础，界面绘制； viewstub；

### 4.Android的缓存LruCache的实现原理；