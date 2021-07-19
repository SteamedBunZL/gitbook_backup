[toc]



# Kotlin协程





## 协程基础

### 1.最简单的协程程序

```kotlin
import kotlinx.coroutines.*

fun main() {
    GlobalScope.launch { // 在后台启动一个新的协程并继续
        delay(1000L) // 非阻塞的等待 1 秒钟（默认时间单位是毫秒）
        println("World!") // 在延迟后打印输出
    }
    println("Hello,") // 协程已在等待时主线程还在继续
    Thread.sleep(2000L) // 阻塞主线程 2 秒钟来保证 JVM 存活
}
```

> 这里不阻塞主线程，程序会执行打印“Hello”后直接退出，协程是挂起去执行，但是程序退出全局的协程可能会继续运行，所以不推荐使用全局的GlobalScope来启动一个协程



### 2.runBlocking

> 调用了 `runBlocking` 的主线程会一直 *阻塞* 直到 `runBlocking` 内部的协程执行完毕。

```kotlin
import kotlinx.coroutines.*

fun main() = runBlocking<Unit> { // 开始执行主协程
    GlobalScope.launch { // 在后台启动一个新的协程并继续
        delay(1000L)
        println("World!")
    }
    println("Hello,") // 主协程在这里会立即执行
    delay(2000L)      // 延迟 2 秒来保证 JVM 存活
}
```

> runBlocking{  delay(2000) }  相当于调用了Thread.sleep(2000) 的效果是一样的

这里的结果是 马上打印hello 然后 1秒后打印world 程序又卡了1秒后退出了

如果是这样的

```kotlin
        runBlocking {

            GlobalScope.launch {
                delay(3000L)
                println("World!")
            }

            delay(2000L)
        }
        println("Hello")
```

这里会在延迟2秒后打印hello 然后程序就退出了，runBlocking 会确保delay这种 suspend方法 执行完成 launch启动的协程执行完成，但是像GlobalScope.launch这种新启动的全局协程 跟 runBlocking就没关系了



### 3.结构化并发

```kotlin
    @Test
    fun main2() = runBlocking {//这叫结构化并发
        launch {//CoroutineScope构造器 重点：在外部作用域内新启了一个协程而不是全局的 受runBlocking影响
            //避免启动过多全局协程 还不需要join
            delay(1000)
            println("World")
        }

        println("Hello")
    }
```

这里会马上打印hello 因为delay使用了launch 去启动，并不会卡住 打印hello 但是因为在runblocking内部的launch 会确保它执行完成，所以在1秒后又打了world后才会退出程序



### 4.作用域构建器 coroutineScope

```kotlin
    @Test
    fun main3() = runBlocking {
        launch {//顺序执行到这里会马上启动一个后台协程200ms会执行 打印
            delay(200)
            println("task from runblocking")
        }

        coroutineScope {//新启了一个作用域  把它想成runBlocking{}
            launch {
                delay(500)
                println("task from nested launch")
            }

            delay(100) //这里就相当于Thread.sleep(100)
            println("task from coroutine scope")
        }

        println("coroutine scope is over")
    }
```

这里会先打印coroutineScope scope  注意不会马上打印 "coroutine scope is over" 因为coroutineScope 相当于runblocking 新启了一个作用域 效果和runblocking是一样的 但是由于外部先启动了launch 这里会接着打印

"task from runblocking" 然后 会确保 coroutineScope 启动的launch执行完 所以什么打印完

 "task from nested launch" 后才最后打印  "coroutine scope is over"



> ```
> 除了不同构建器提供的协程作用域之外，还可以使用 coroutineScope 构建器来声明您自己的作用域。它创建了一个协程范围，并且在所有启动的子项完成之前不会完成。
> 
> runBlocking 和 coroutineScope 构建器可能看起来相似，因为它们都等待它们的主体及其所有子节点完成。主要区别在于 runBlocking 方法阻塞当前线程等待，而 coroutineScope 只是挂起，释放底层线程用于其他用途。由于这种差异，runBlocking 是一个常规函数，coroutineScope 是一个挂起函数。
> 
> 您可以从任何挂起函数中使用 coroutineScope。例如，您可以将 Hello 和 World 的并发打印移动到 suspend fun doWorld() 函数中：
> ```
>

### 5.提取函数重构

```kotlin
import kotlinx.coroutines.*

fun main() = runBlocking {
    launch { doWorld() }
    println("Hello,")
}

// 这是你的第一个挂起函数
suspend fun doWorld() {
    delay(1000L)
    println("World!")
}
```

这里会先打印Hello 1秒后打印world 因为挂起执行了doWorld 

如果我想在doWorld函数中再使用launch去启用协程，只使用suspend就不行了，要加入作用域

在挂起函数中使用coroutineScope

```kotlin
fun main() = runBlocking {
    doWorld()
  	println("doworld after")
}

suspend fun doWorld() = coroutineScope {  // this: CoroutineScope
    launch {
        delay(1000L)
        println("World!")
    }
    println("Hello")
}
```

这里会先执行完成doWorld方法后，才会打印"doworld after"



## 取消与超时





