# Flutter基础





开发工具的选择

AndroidStudio





操作系统

macOS(64-bit)



命令行工具

bash curl git 2.x mkdir rm unzip which



设置flutter镜像

```shell
//.bash.profile
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
```

[Using Flutter in China](https://flutter.dev/community/china)  最新服务器动态









## Dart





### dartpad

https://dartpad.dev/?null_safety=true





### 变量和类型

```dart
int a = 123;
var b = 124;
String c = 'Dart';
var d = 'Dart';
```



### 默认值





### 检查null或零

javascript中 !null 是true  非0也是true

dart跟java更像 

判断 dart == null 或者 dart  == 0



### Dart null 检查最佳实践 

跟kotlin一样 使用?.

?.



kotlin中的?:  在dart中是??

```dart
bool isConnected(a,b){
	bool outConn = outgoing[a]?.contains(b) ?? false;//如果??前面为null 就执行赋值??后面的
}
```





```dart
 
  print(null ?? false);//false null == null 所以赋值 false
  print(false ?? 11);//false  false不为null 所以不执行11 执行前面的
  print(true ?? false);//true  
```





### Functions

```dart
//Javascript ES5
function fn(){
  return true;
}

//dart
fn(){
  return true;
}

//can also be written as
bool fn(){
  return true;
}
```





异步编程



