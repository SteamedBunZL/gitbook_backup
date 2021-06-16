# Android知识汇总









# KOTLIN









# Android





## 动画相关

[动画相关]()











## 框架结构

MVP和MVVM所谓的框架更多的是一种思想,规范,要明白不同架构解决了什么问题

### 6.MVP

![image-20210513115753021](file:///Users/zhanglong/Library/Application%20Support/typora-user-images/image-20210513115753021.png?lastModify=1623708023)

![image-20210513115825615](file:///Users/zhanglong/Library/Application%20Support/typora-user-images/image-20210513115825615.png?lastModify=1623708023)



- BaseView:一般特指Activity/Fragment,可以定义一些通用的方法

```
public interface BaseView{
  boolean is Alive();//判断宿主是否还存活，避免NPE
}
```

- Presenter,用于处理业务数据逻辑，并通过持有View接口把数据回传View层

```

```





### 7.MVVM





### 8.JetPack & MVVM





## View 相关

### 7.在view里面绘制平行四边形



### 8.Recyclerview 的缓存



### 9.Android touch事件分发



## Android Handler相关

### 5.Android的Handler的原理；

每个线程会持有唯一的一个Looper用于消息循环 每个Handler都会保有当前线程的唯一的Looper对象这是怎么保证的呢 我们在一个线程中想使用Handler 必须先有Looper对象 不然就会报异常 所以我们先要调用Looper.prepare 方法 把当前的线程保存在ThreadLocal中,主线程的Looper的创建是在ActivityThread中 所以我们不用在UI线程中创建looper就可以使用消息机制.

每一个Looper中会有唯一一个MessageQueue对象,核心方法是enqueueMessage 当我们发送一条条消息时 都会执行到这个方法,做消息的派发,这个Messagequeue是一个单向的链表结构去存储message的,存储的顺序是msg.when 消息的触发时间(而不是消息的发送时间)

根据消息的时间插入单向链表

```
boolean enqueueMessage(Message msg, long when) {
        if (msg.target == null) {//targe 就是对应的handler对象
            throw new IllegalArgumentException("Message must have a target.");
        }

        synchronized (this) {
            if (msg.isInUse()) {
                throw new IllegalStateException(msg + " This message is already in use.");
            }

            if (mQuitting) {
                IllegalStateException e = new IllegalStateException(
                        msg.target + " sending message to a Handler on a dead thread");
                Log.w(TAG, e.getMessage(), e);
                msg.recycle();
                return false;
            }

            msg.markInUse();
            msg.when = when;
            Message p = mMessages;
            boolean needWake;
          //这是一个空链或者消息时间小于头部消息 就直接插入头部
            if (p == null || when == 0 || when < p.when) {
                msg.next = p;
                mMessages = msg;
                needWake = mBlocked;
            } else {
                needWake = mBlocked && p.target == null && msg.isAsynchronous();
                Message prev;
                for (;;) {
                    prev = p;
                    p = p.next;
                    if (p == null || when < p.when) {
                        break;
                    }
                    if (needWake && p.isAsynchronous()) {
                        needWake = false;
                    }
                }
                msg.next = p; // invariant: p == prev.next
                prev.next = msg;
            }

            if (needWake) {
                nativeWake(mPtr);
            }
        }
        return true;
    }
```

以上过程是消息的生产

我们看下消息的消费过程,消费过程,是在Looper.loop()方法

```
for (;;) {
            Message msg = queue.next(); // might block
            if (msg == null) {
                // No message indicates that the message queue is quitting.
                return;
            }
            
            ...
            
            try {
                msg.target.dispatchMessage(msg);
                if (observer != null) {
                    observer.messageDispatched(token, msg);
                }
                dispatchEnd = needEndTime ? SystemClock.uptimeMillis() : 0;
            } catch (Exception exception) {
                if (observer != null) {
                    observer.dispatchingThrewException(token, msg, exception);
                }
                throw exception;
            } finally {
                ThreadLocalWorkSource.restore(origWorkSource);
                if (traceTag != 0) {
                    Trace.traceEnd(traceTag);
                }
            }
            ...
            msg.recycleUnchecked();
        }
```

调用到MessageQueue的next()方法,重点

```
for (;;) {
            if (nextPollTimeoutMillis != 0) {
                Binder.flushPendingCommands();
            }

            nativePollOnce(ptr, nextPollTimeoutMillis);

            synchronized (this) {
                // Try to retrieve the next message.  Return if found.
                final long now = SystemClock.uptimeMillis();
                Message prevMsg = null;
                Message msg = mMessages;
                if (msg != null && msg.target == null) {
                    // Stalled by a barrier.  Find the next asynchronous message in the queue.
                    do {
                        prevMsg = msg;
                        msg = msg.next;
                    } while (msg != null && !msg.isAsynchronous());
                }
                if (msg != null) {
                    if (now < msg.when) {
                        // Next message is not ready.  Set a timeout to wake up when it is ready.
                        nextPollTimeoutMillis = (int) Math.min(msg.when - now, Integer.MAX_VALUE);
                    } else {
                        // Got a message.
                        mBlocked = false;
                        if (prevMsg != null) {
                            prevMsg.next = msg.next;
                        } else {
                            mMessages = msg.next;
                        }
                        msg.next = null;
                        if (DEBUG) Log.v(TAG, "Returning message: " + msg);
                        msg.markInUse();
                        return msg;
                    }
                } else {
                    // No more messages.
                    nextPollTimeoutMillis = -1;
                }

                // Process the quit message now that all pending messages have been handled.
                if (mQuitting) {
                    dispose();
                    return null;
                }

                // If first time idle, then get the number of idlers to run.
                // Idle handles only run if the queue is empty or if the first message
                // in the queue (possibly a barrier) is due to be handled in the future.
                if (pendingIdleHandlerCount < 0
                        && (mMessages == null || now < mMessages.when)) {
                    pendingIdleHandlerCount = mIdleHandlers.size();
                }
                if (pendingIdleHandlerCount <= 0) {
                    // No idle handlers to run.  Loop and wait some more.
                    mBlocked = true;
                    continue;
                }

                if (mPendingIdleHandlers == null) {
                    mPendingIdleHandlers = new IdleHandler[Math.max(pendingIdleHandlerCount, 4)];
                }
                mPendingIdleHandlers = mIdleHandlers.toArray(mPendingIdleHandlers);
            }

            // Run the idle handlers.
            // We only ever reach this code block during the first iteration.
            for (int i = 0; i < pendingIdleHandlerCount; i++) {
                final IdleHandler idler = mPendingIdleHandlers[i];
                mPendingIdleHandlers[i] = null; // release the reference to the handler

                boolean keep = false;
                try {
                    keep = idler.queueIdle();
                } catch (Throwable t) {
                    Log.wtf(TAG, "IdleHandler threw exception", t);
                }

                if (!keep) {
                    synchronized (this) {
                        mIdleHandlers.remove(idler);
                    }
                }
            }

            // Reset the idle handler count to 0 so we do not run them again.
            pendingIdleHandlerCount = 0;

            // While calling an idle handler, a new message could have been delivered
            // so go back and look again for a pending message without waiting.
            nextPollTimeoutMillis = 0;
        }
```

这里特别注意 获取的时间now是SystemClock.uptimeMillis()而不是System.currentUptimes()一个是开机到现在的时间,一个是当前系统的时间,差别很大

```
if (msg != null) {
                    if (now < msg.when) {
                        // Next message is not ready.  Set a timeout to wake up when it is ready.
                        nextPollTimeoutMillis = (int) Math.min(msg.when - now, Integer.MAX_VALUE);
                    } else {
                        // Got a message.
                        mBlocked = false;
                        if (prevMsg != null) {
                            prevMsg.next = msg.next;
                        } else {
                            mMessages = msg.next;
                        }
                        msg.next = null;
                        if (DEBUG) Log.v(TAG, "Returning message: " + msg);
                        msg.markInUse();
                        return msg;
                    }
                } else {
                    // No more messages.
                    nextPollTimeoutMillis = -1;
                }
```

如果消息晚于当前时间,则计算出下次poll的时间 nextPollTimeoutMillis 如果相反,得 从链表中取出当前msg 去消息派发

如果当前没有到时间的消息,而且没有idle消息 则执行

```
nativePollOnce(ptr, nextPollTimeoutMillis);
```

等到时间了会进行唤醒操作



### 6.为什么Handler可以发送延时的消息, 延时问题这个。

因为已经把每条消息,按照精确的时间when在链表中进行排队,然后到相应的时间后就会弹出消息,可以延时执行消息,不阻塞是因为使用了linux的piple管道 基于epoll的多路复用原理



### 7.如果我们更改系统时间,延时消息会马上执行么?为什么?

不会. 因为我们在sendMessage中传入的是SystemClock.upTimeMillis方法 而不是用的System.currentTimeMillis这个是开机到现在的时间 而且不包括深度睡眠的时间(息屏)所以我们更改系统时间 对消息的执行是无效的



### 7.ThreadLocal原理,注意线程 threadlocal之间是否有直接关系,是怎么存取的?

每个线程t 中会持有一个ThreadLocalMap 的集合 这是它的**属性字段** 这个集合里面的key是当前的ThreadLocal对象 也就是说 我们在一相线程中存储数据 线程会有很多ThreadLocal对象 我们是把ThreadLocal对象存到了线程持有的ThreadLocalMap 中 然后当我们取threadlocal里的数据时,先把对应的key threadlocal对象传入进去



### 8.ThreadLocal会导致内存泄漏么?为什么?

会导致,我们发现 ThreadLocal的map的值是以WeakReference 形式存储的 但是它的Key 还是ThreadLocal对象本身 所以key还是不会被内存直接回收,可能会导致内存泄漏 所以我们在不再使用ThreadLocal对象后 要把key设置成null 这样内存回收时会把扫到null对应的weakreference对象直接回收掉





## Fragment 相关

### 8.两个fragment之间的通信；

两个Fragment之间不能直接通信，只能通过它们所寄生的Activity作为桥梁进行通信

fragment1 通过接口 把数据传递给 activity activity再把数据传递给相应的fragment

### 9.fragment为什么会重叠?怎么解决

由于Activity由于异常被销毁,会执行onSavedInstanceState方法进行数据状态的保存,里面会执行fragments.saveAllState()方法进行fragments状态数据的保存,在Activity的onCrteate方法 执行fragments.restoreSavedState()进行恢复,如果我们在Activity的onCreate里面添加了一个fagment 那么系统并不保存销毁时的view只保存数据,系统会再帮我们恢复一个view 会重新走到onCreateView方法,这样这个方法就走了两次,所以出现了view的重叠绘制问题.

解决方法:在添加fragment之前先判断是否已经存在了我们要添加的fragment,所以在我们执行add方法的时候 要给fragment添加tag,方便我们通过tag来查找相应的fragment



或者在onSaveInstance中保留当前fagment的currentIndex 然后在重新执行oncreate方法 去初始化的时候 把fragment每次都切换到上次保留的index的fragment上 这样也不会再见到重叠



### 10.系统执行onSaveInstanceState的时机?

### 11.fragment的懒加载的方式有哪些?分别是什么?

### 12.fragment的开启事务后,提交方式有哪些,区别是什么?













### 14.Android启动Service的两种方式是什么?它们适用情况是什么?

startService：生命周期与调用者不同。启动后若调用者未调用stopService而直接退出，Service仍会运行

bindService：生命周期与调用者绑定，调用者一旦退出，Service就会调用unBind->onDestroy

### 15.四大组件的生命周期

1）Activity：onCreate()->onStart()->onResume()->onPause()->onStop()->onDestory()

onCreate()：为Activity设置布局，此时界面还不可见；

onStart(): Activity可见但还不能与用户交互，不能获得焦点

onRestart(): 重新启动Activity时被回调

onResume(): Activity可见且可与用户进行交互

onPause(): 当前Activity暂停，不可与用户交互，但还可见。在新Activity启动前被系统调用保存现有的Activity中的持久数据、停止动画等。 

onStop(): 当Activity被新的Activity覆盖不可见时被系统调用

onDestory(): 当Activity被系统销毁杀掉或是由于内存不足时调用

2）Service

a) onBind方式绑定的：onCreate->onBind->onUnBind->onDestory（不管调用bindService几次，onCreate只会调用一次，onStart不会被调用，建立连接后，service会一直运行，直到调用unBindService或是之前调用的bindService的Context不存在了，系统会自动停止Service,对应的onDestory会被调用）

b) startService启动的：onCreate->onStartCommand->onDestory(start多次，onCreate只会被调用一次，onStart会调用多次，该service会在后台运行，直至被调用stopService或是stopSelf)

c) 又被启动又被绑定的服务，不管如何调用onCreate()只被调用一次，startService调用多少次，onStart就会被调用多少次，而unbindService不会停止服务，必须调用stopService或是stopSelf来停止服务。必须unbindService和stopService(stopSelf）同时都调用了才会停止服务。

3）BroadcastReceiver

a) 动态注册：存活周期是在Context.registerReceiver和Context.unregisterReceiver之间，BroadcastReceiver每次收到广播都是使用注册传入的对象处理的。

b) 静态注册：进程在的情况下，receiver会正常收到广播，调用onReceive方法；生命周期只存活在onReceive函数中，此方法结束，BroadcastReceiver就销毁了。onReceive()只有十几秒存活时间，在onReceive()内操作超过10S，就会报ANR。

进程不存在的情况，广播相应的进程会被拉活，Application.onCreate会被调用，再调用onReceive。

4）ContentProvider：应该和应用的生命周期一样，它属于系统应用，应用启动时，它会跟着初始化，应用关闭或被杀，它会跟着结束。



## Activity 相关



### 15.Activity的启动模式

- **standard**: 标准模式,每次启动都会新创建一个新的实例，不管这个实例是否已经存在。如果A启动了B（B是standard模式） 那么B会进入A的栈。如果使用ApplicationContext来启动会报错，因为它没有启动的任务栈，要加FLAG_ACTIVITY_NEW_TASK 标记位，这样启动的时候就会为它创建一个新的任务栈，这里实际上是以singletask来启动的
- **singleTop**:栈顶复用模式，1.如果新的Activity已经位于栈顶，那么此activity不会重新创建，同时onNewIntent方法会被回调。2.如果已经存在但不位于栈顶，那么新的activity还是会被重新创建。
- **singleTask**:栈内复用模式。如果栈内已经存在，那么多次启动都不会重新创建实例，会回调onNewIntent方法 1.S1：ABC S2:D  2.S1:ABCD D和ABC在同一个栈  3. S1:ADBC -> AD clearTop
- **singleInstance**:加强版的singleTask 新启动的activity只能位于单独的一个任务栈中



### 16.Activity taskAffinity +  allowTaskReparent 有什么作用？



### 17.Activity Intentfilter 的匹配规则有哪些？





### 18.Activity 启动流程？

![image-20210512055918199](file:///Users/zhanglong/Library/Application%20Support/typora-user-images/image-20210512055918199.png?lastModify=1623708023)

![image-20210512060030617](file:///Users/zhanglong/Library/Application%20Support/typora-user-images/image-20210512060030617.png?lastModify=1623708023)

### 19.Activity的窗口如何展示，为什么在onResume及以前的onCreate,onStart生命周期不能直接获取view的宽高信息？

![image-20210512060449038](file:///Users/zhanglong/Library/Application%20Support/typora-user-images/image-20210512060449038.png?lastModify=1623708023)





### 20.Activity的转场动画的实现机制

原理：在跳转退出前Activity之前，记录需要做转场动画view的大小，位置信息，这些是共享的信息，然后在第二个Activity进入之前之前view的大小位置信息，播放到目标页面的大小，位置，进行属性的动画，就完成了转场的动画

![image-20210512061505096](file:///Users/zhanglong/Library/Application%20Support/typora-user-images/image-20210512061505096.png?lastModify=1623708023)

![image-20210512061524908](file:///Users/zhanglong/Library/Application%20Support/typora-user-images/image-20210512061524908.png?lastModify=1623708023)

### 21.如何启动外部应用的Activity?(初级，需要操作来较验) //TODO 去AS上实验

**第一种：通过共享UID** 

可以直接启动Activity B

![image-20210512061858305](file:///Users/zhanglong/Library/Application%20Support/typora-user-images/image-20210512061858305.png?lastModify=1623708023)

![image-20210512061952554](file:///Users/zhanglong/Library/Application%20Support/typora-user-images/image-20210512061952554.png?lastModify=1623708023)

**第二种 ：通过使用exported**



![image-20210512062202921](file:///Users/zhanglong/Library/Application%20Support/typora-user-images/image-20210512062202921.png?lastModify=1623708023)

**第三种 使用 intentFilter 隐式的启动**

//TODO 需要AS较验 

![image-20210512062330447](file:///Users/zhanglong/Library/Application%20Support/typora-user-images/image-20210512062330447.png?lastModify=1623708023)

![image-20210512062401327](file:///Users/zhanglong/Library/Application%20Support/typora-user-images/image-20210512062401327.png?lastModify=1623708023)

### 22.如何为外部启动的 Activity加权限？

![image-20210512062532625](file:///Users/zhanglong/Library/Application%20Support/typora-user-images/image-20210512062532625.png?lastModify=1623708023)

### 23.什么是拒绝服务漏洞？怎么解决？

场景：Activity A 去跳转外部App中的一个Activity B 如果我们在Intent中putExtra 把Activity A中的 类SerializableA 转了进去 一定会序列化

![image-20210512062859774](file:///Users/zhanglong/Library/Application%20Support/typora-user-images/image-20210512062859774.png?lastModify=1623708023)



然后我们在外部App中并没有SerializableA 这个类，所以在ActivityB中 去反序列化时，就会报找不到SerializableA 的异常

![image-20210512063438811](file:///Users/zhanglong/Library/Application%20Support/typora-user-images/image-20210512063438811.png?lastModify=1623708023)



![image-20210512063453661](file:///Users/zhanglong/Library/Application%20Support/typora-user-images/image-20210512063453661.png?lastModify=1623708023)



解决方案，其实非常简单 在Ativity B中一定要在获取Intent的地方加一个try catch

​	![image-20210512063959013](file:///Users/zhanglong/Library/Application%20Support/typora-user-images/image-20210512063959013.png?lastModify=1623708023)

### 24.如何解决Activity参数传递的类型安全以及接口复杂的问题？

可以先说下思路  //TODO 自己去实现 参考第三方的架构



### 25.注解处理器程序开发注意的事项？//TODO 需要详细再查资料了解

- 注意注解标注的类的继承关系
- 注意注解标注的为为内部类的情况
- 注意Kotlin与Java的类型映射的问题



### 26.元编程？

![image-20210512070207762](file:///Users/zhanglong/Library/Application%20Support/typora-user-images/image-20210512070207762.png?lastModify=1623708023)



### 27.如何获取当前Activity?

通过实现ActivityLifecycle接口 在onActivityCreated 中获取currentActivity 注意要用WeakReference引用持有，防止Acvtivity泄漏 



### 28.如何实现微信右滑返回的效果(Activity)？右滑返回前后两个Activity的生命周期？//TODO 自己去试着实现

原理：



![image-20210512075944287](file:///Users/zhanglong/Library/Application%20Support/typora-user-images/image-20210512075944287.png?lastModify=1623708023)



正常三个Activity的叠加是这样的，如果我们想要显示ActivityC 下面的ActivityB 前提必须Activity C 是window透明的

![image-20210512080206967](file:///Users/zhanglong/Library/Application%20Support/typora-user-images/image-20210512080206967.png?lastModify=1623708023)

只修改android:windowBackground背景是不行的，会出现这种情况

![image-20210512080422523](file:///Users/zhanglong/Library/Application%20Support/typora-user-images/image-20210512080422523.png?lastModify=1623708023)

因为系统会认为C是一个实心的东西，不会去绘制B 节省了性能 







## 优化相关



### //TODO L123. TOP 团队大牛带你玩转 Android性能分析与优化

### 16.包体积优化

### 17.内存泄漏

### 18.UI卡顿

### 19.屏幕适配





# 网络

## Socket相关



### //TODO L107 Socket网络编程进阶与实战 源码构建



# 第三方库



## JetPack库





## Retrofit 相关





## OKHttp 相关





## Rxjava 相关



### 1.rxjava 操作符变换的原理?

使用代码如下:

```
Single.just(1)
                .map(new Function<Integer, String>() {

                    @Override
                    public String apply(Integer integer) throws Exception {
                        return String.valueOf(integer);
                    }
                }).subscribe(new SingleObserver<String>() {
            @Override
            public void onSubscribe(Disposable d) {

            }

            @Override
            public void onSuccess(String s) {

            }

            @Override
            public void onError(Throwable e) {

            }
        });
       
```



![image-20210509054239002](file:///Users/zhanglong/Library/Application%20Support/typora-user-images/image-20210509054239002.png?lastModify=1623708023)



例如map 这种,是在初始的Single和 new SingleOberver(观察者)之间加入中间层,map方法也返回了Single对象,

```
    public final <R> Single<R> map(Function<? super T, ? extends R> mapper) {
        ObjectHelper.requireNonNull(mapper, "mapper is null");
        return RxJavaPlugins.onAssembly(new SingleMap<T, R>(this, mapper));
    }
```

但是注意 它返回的是new SingleMap(this,mapper)对象,而不是直接返回this 把原对象返回 这就相当于中间新加了一层的SIngle对象

在调用完.map(xxxx).subscribe的时候 实际上调用的是新的中间层Single的subscribe方法 

```
    @Override
    protected void subscribeActual(final SingleObserver<? super R> t) {
        source.subscribe(new MapSingleObserver<T, R>(t, mapper));
    }
```

这里的source就是上游的Single对象,这样就会自下而上的一层层的调用上游的Single 直到发起者

但是这里要注意,上游的Single这里订阅的对象是一个新的MapSingleObserver对象,并且在source的subscribe方法中把下游的观察者SingleObserver对象传给了它 也就是t 还有变换的方法mapper(像适配器) 

这里的流程就是这样的

最下游的Single一旦调用subscribe方法 就会不断的调用上游的Single的subscribe方法 最上游的Single调用的subcribe方法 就会调用它在subscribe中新传入的MapSingleObserver对象 也就是回调SIngleObserver的onSubscribe() onSucess()方法 而每个MapSingleObserver在new的时候又把下游的SingleObserver对象传入了进去

```
        public void onSuccess(T value) {
            R v;
            try {
                v = ObjectHelper.requireNonNull(mapper.apply(value), "The mapper function returned a null value.");
            } catch (Throwable e) {
                Exceptions.throwIfFatal(e);
                onError(e);
                return;
            }

            t.onSuccess(v);
        }
```

在自己的onSuccess被Single回调的时候 会继续调用 t.onSuccess(v)方法 回调下游的onSucess()方法,在这里我们就可以用mapper进行变换

总结下就是  每个操作符都会在中间加一层新的Observable对象 并持有对上游Obserable的引用 (source) 并在自己的subscribeActual方法中new出一个新的Observer的封装,这个对象会持有下游Observer对象. 流程是  最下游的Observable触发subscribe方法后会逐级调用上游(source.sucrbie()) 一层层的调用到最上游 然后最上游会开始调用持有下游的observer对象的回调方法 并把相应的转换也是在回调中实现的.

### 2.rxjava 线程切换的原理?

知道了操作符的原理后,rxjava切线程的原理也很简单

subscribeOn() 和observeOn() 本质也是操作符 变换的原理同上

subscribeOn() 方法也会在中间新创建一个Observable对象,然后他做了两件事

```
    @Override
    public void subscribeActual(final Observer<? super T> s) {
      	//1.封装了下游的Observer对象生成了一个新的
        final SubscribeOnObserver<T> parent = new SubscribeOnObserver<T>(s);
				//2.直接触发下游observer.onSubscribe的调用 这里不切线程
        s.onSubscribe(parent);
				//3.scheduler.scheduleDirect 这里切线程
        parent.setDisposable(scheduler.scheduleDirect(new SubscribeTask(parent)));
    }
```

scheduler.scheduleDirect 方法会切线程 传入的SubscribeTask是一个Runnable对象

```
    final class SubscribeTask implements Runnable {
        private final SubscribeOnObserver<T> parent;

        SubscribeTask(SubscribeOnObserver<T> parent) {
            this.parent = parent;
        }

        @Override
        public void run() {
            source.subscribe(parent);
        }
    }
```

在run() 方法里 执行了 source(上游的) subscribe方法 这里的意思就是切换线程去 继承往上游去执行subscribe方法

多次切线程

![image-20210509103802790](file:///Users/zhanglong/Library/Application%20Support/typora-user-images/image-20210509103802790.png?lastModify=1623708023)

所以subcribeon 上游的切换后 如果不再切换线程 后续的回调都会以新的线程(黄色) 来执行



observeOn正好相反,它是改变它下游的线程执行的

同样observeOn也会创建中间的Observable对象 在subscribeActual方法中 直接执行了

```
source.subscribe(new ObserveOnObserver<T>(observer, w, delayError, bufferSize));
```

没有切线程.....这是对的,因为它管理的是回调及下游的线程 subscribe这里不切是对的

```
        @Override
        public void onComplete() {
            if (done) {
                return;
            }
            done = true;
            schedule();
        }
        
        void schedule() {
            if (getAndIncrement() == 0) {
                worker.schedule(this);
            }
        }

				void run(){
          actual.onComplete();
        }
```

在回调里 会执行schdule()会切线程继续执行后续的 observer的回调 

![image-20210509104213133](file:///Users/zhanglong/Library/Application%20Support/typora-user-images/image-20210509104213133.png?lastModify=1623708023)



# 其他



### 17.Android studio 为什么主工程里引用不到library引用的第三方库?

Android Studio 3.x升级后,之前library中引用第三方库使用的是

```
implementation 'com.squareup.picasso:picasso:2.71828'
```

现在要改成

```
api 'com.squareup.picasso:picasso:2.71828'
```

​	

### 9多线程同步，touch事件分发，内存泄露分析，热修复

1. oom的情况分析解决
2. linkHashMap加锁的时候，怎么做的插入
3. 怎么优化双向链表的访问速度
4. lru缓存机制是什么，，里面双向链表实现的队列，最近最少用到的缓存会被从队列中删除掉，是否只是从队列中删除吗？

\14. 如果一个视图很小，不想改变他的大小，如果扩大他的点击范围；

\15. 一个App的启动流程

\16. UI绘制原理

\17. 下载器的设计

\18. ViewPager的原理，生产消费等模式

\19. 接口和虚基类

\20. sychronized 和lock (读写锁 copyonwrite)

21.hashmap实现

\22. equals hashcode 为什么要重写他们







27.插件，多dex，热更新，读写锁案例；hashmap的存储模型

28.hashmap的大小为啥是2的指数:

29.currenthashmap的实现原理

30、**touch事件流程**



31、activity生命周期

32、Rxjava操作符

33、SQLite

**34、mvc,mvp与mvvm**

35、json转gson为什么要传getType()?，sparseArray；

36、meessage延迟如何实现

37、线程如何中断，interrupt如何中断线程

38、intent传递数据为什么要序列化

39、dispatchDraw 和 ondraw区别

40、synchronize 修饰静态方法和非静态方法区别

41、synchronize修饰的方法，被重写后还是synchronize的吗

42、targetsdkversion含义

**43、http和https的区别；https的加密过程**

44、Android 混淆，哪些不可以混淆

45、卡顿检测定位途径

46、bug定位途径

47、哪些情况要在主线程使用 handler post  

48、看过哪些第三方源码

\49. 优化了哪些点，哪些是可以说的，滑动优化，动画优化

```
public static 
```

\50. Fresco 架构上说下，MVC模式，说说 Fresco加载gift的流程和原理

\51. 一个大的ViewGroup，上面显示两个不一样大小的图片，内容一样，怎么做（利用Fresco的缓存）

\52. 一个图片是50 * 50，一个图片是100 * 100，内存大小是怎样的，比如 50*50的内存大小是1，100*100的内存大小是多少？ 两张图片，内存变大了还是不变，内存副本有几份？

1. **RecyclerView 滑动的时候，缓存机制**

   \54. RecyclerView 下面一个子item，我手指按在RecylerView上，然后滑动，说出滑动过程

   \55. 海量数据中找出TOP N（堆）

   \56. 自定义帧动画机制，一边解压一边加载，用完之后回收，inBitmap进行内存复用。用了哪些数据结构，如何保证按顺序执行。

   \57. bitmap drawable 区别(互相转化，drawable包含bitmap)Bitmap是Drawable . Drawable不一定是Bitmap Drawable在内存占用和绘制速度这两个非常关键的点上胜过Bitmap

   \58. Gradle打包的一些知识，flavor，打包时序，打包时修改文件，java字节码修改

   \59. Okhttp请求的一些知识，拦截器的使用

   \61. ViewStub的使用优点

   \62. WeakReference和SoftReference的区别

   1. **ThreadLocal**

      \64. 字符串截取输出中文，现场写代码

       

       

      **3.**   **常见数据结构算法题（多刷Leecode）**

      1、函数f(x)随机生成[0-5]，概率一样，实现g(x)=[0-13]概率一样

      2、三个瓶子，每个瓶子装满了一种颜色。每两个瓶子混合，可以均分颜色。现在要三个瓶子最后颜色一样，请问如何平均分配？

      3、求组里面有正，负，0，找两个数，他们的和等于给定的目标值

      4、0-5的随机数，求0-13

      5、Ui树的遍历，用Queue来实现别用stack。

      6、两个大数相加(用两个list表示大数)

      7、（手写递归函数）

      8、合并两个有序数组

      9、哈夫曼编码

      10、双11，如何选出买的最多的100条数据。用最大堆排序

      11.写一个线程安全的单例实现；

      12.有100只一模一样的瓶子，编号1-100。其中99瓶是水，一瓶是看起来像水的毒药。只要老鼠喝下一小口毒药，一天后则死亡。现在，你有7只老鼠和一天的时间，如何检验出哪个号码瓶子里是毒药？

      13.无序数组的中位数，数组长度为n

      \14. 给定一个非空整数数组，取值范围[0,100]，除了某个元素出现奇数次以外，其余每个元素均出现次数为偶数。找出那个出现次数为奇数次的元素。

      如果取值范围为[0,100000000]

      15、4个砝码，整数的，能组合出多少种称量重量

      16、N个人中至少两个人同一天生日的概率

      17、整数数组中找出前边的数都比自己小，后边的数都比自己大的数

      18、字符串串去空格

      19、手写链表反转函数，要求是不用其他辅助的存储

      20、二叉树的遍历，计算二叉树高度

      21、红黑树、二叉树、冒泡排序、快速排序

      22、给定一个有序的旋转数组，查找某个元素是否在数组内，eg： ［4 5 6 1 2 3］target=5

      23、 给定一个物品在各个时间点的价格，求进行一次买卖之后最大获利。

      24、手写代码，求链表倒数第k个元素

      25、系统为某进程分配了4个页框，该进程已访问的页号序列为2,0,2,9,3,4,2,8,2,4,8,4,5。若进程要访问的下一页的页号为7，依据LRU算法，应淘汰页的页号是几号？

      26、有一个随机数生成器，能以p概率生成0，1-p概率生成1。利用这个生成器等概率生成0-6。

      27、简单动态规划，爬楼梯问题

      28、一个数组，和sum，求出数组中所有可能的任意元素（一个元素只能用一次）的和等于sum的组合

       

      

      

      

      

      

      

      

      - hashmap concurenthashmap SpareArray
      - hashcode与equase的区别，重写equase是否需要重写hashcode
      - lock 与synchronized区别，synchronized锁升级过程，各种锁的区别（乐观锁悲观锁等等）
      - JVM垃圾回收，堆分代，帧栈的作用
      - JVM内存模型，transient的特性
      - 类的加载过程,双亲委派机制
      - 静态代理动态代理
      - 线程池ThreadPoolExecutor构建的几个参数及作用，Submit和excute的区别
      - Sleep yeild wait join的区别，notify和notifyAll的区别
      - 单例的实现有哪些，单例模式的破坏方式有哪些
      - 接口和抽象类的区别
      - 泛型
      - 反射的耗时原因
      - 注解及其用途
      - 插件及热修复的实现原理
      - String缓存，StringBuffer与StringBuilder的区别
      - 集合的种类
      - DVM vs JVM的区别
      - Handler原理(Looper,MessgeQuee,ThreadLocal,IdleHandler)
      - APP启动流程
      - Webview内存泄漏原因及解决方式
      - 跨进程通讯方式有哪些，binder使用过程及实现机制，Binder传输大数据的TransactionTooLargeException异常原因及解决方式
      - View绘制过程及自定义View
      - 动画执行流程
      - 屏幕适配方式有哪些
      - RecycleView的优化及缓存原理
      - OOM ANR的定位及解决，如何捕获crash，leakcanary的实现原理
      - eventbus okhttp原理及实现
      - glide与fresco的原理及优缺点
      - kotlin携程
      - jetpack库都有哪些
      - 



