---
layout: post
title: "RACObserve 的思考"
date: 2018-09-20
categories: macOS&iOS
tags: iOS,ObjC,RAC
---

千呼万唤最终在新项目中接受了RAC的代码，很早之前做个一个项目，也是大量使用RAC，也没有太多考虑RAC的副作用有多大，如今总算是在大项目中去使用了，可是到了性能优化的层面，发现RAC带来的性能还是值得
大家去重新思考。

RAC 的内部实现和代码架构, 等各种网上说的有点就不说了，这里主要谈谈碰见的问题。

大致有几点：

1. 循环引用。
2. KVO中的多级KayPaths
3. 代码消耗

## 循环引用

通过两个Case 来看看循环引用的问题

### CASE ONE

先来看看RACObserve 的实现

```Macro
#define _RACObserve(TARGET, KEYPATH) \
({ \
    __weak id target_ = (TARGET); \
    [target_ rac_valuesForKeyPath:@keypath(TARGET, KEYPATH) observer:self]; \
})

#if __clang__ && (__clang_major__ >= 8)
#define RACObserve(TARGET, KEYPATH) _RACObserve(TARGET, KEYPATH)
#else
#define RACObserve(TARGET, KEYPATH) \
({ \
    _Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Wreceiver-is-weak\"") \
    _RACObserve(TARGET, KEYPATH) \
    _Pragma("clang diagnostic pop") \
})
#endif
```

通过这段代码可以清楚看到Target 后面的self被塞入。

在来看下面一段代码,来只官方提供的源码

```Objective-C
// Observes self, and doesn't stop until self is deallocated.
RACSignal *selfSignal = RACObserve(self, arrayController.items);

// Observes the array controller, and stops when self _or_ the array
// controller is deallocated.
RACSignal *arrayControllerSignal = RACObserve(self.arrayController, items);

// Observes obj.arrayController, and stops when self _or_ the array
// controller is deallocated.
RACSignal *signal2 = RACObserve(obj.arrayController, items);

@weakify(self);
RACSignal *signal3 = [anotherSignal flattenMap:^(NSArrayController *arrayController) {
// Avoids a retain cycle because of RACObserve implicitly referencing
// self.
@strongify(self);
return RACObserve(arrayController, items);
}];
```

官方的解释
> Creates a signal which observes `KEYPATH` on `TARGET` for changes.
In either case, the observation continues until `TARGET` _or self_ is
deallocated. If any intermediate object is deallocated instead, it will be
assumed to have been set to nil.
Make sure to `@strongify(self)` when using this macro within a block! The
macro will _always_ reference `self`, which can silently introduce a retain
cycle within a block. As a result, you should make sure that `self` is a weak
reference (e.g., created by `@weakify` and `@strongify`) before the
expression that uses `RACObserve`.
>

简单说明，在RAC中的block中使用了RACObserve, 然后没有再次使用@strongify 即被弱强转换一次，导致被retain Cycle。

### CASE TWO

RACSubject是非RAC到RAC的一个桥梁，使用可以参考Github教程。
这里说说我碰到的一个场景，代码如下：

```Objective-C
@implementation UIImageView (Demo)

- (RACSignal*)rbs_setImageWithURL:(NSURL *)url{
   return [self rbs_setImageWithURL:url placeholderImage:nil];
}

- (RACSignal*)rbs_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder{
    if (url.absoluteString.length == 0) {
        [self cancelCurrentImageLoad];
        self.image = placeholder;
        return [RACSignal empty];
    }
    RACSubject *subject = [RACSubject subject];
    if (self.frame.size.width == 0 && self.frame.size.height == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self rbs_executeWithUrl:url placeholderImage:placeholder subject:subject];
        });
    }else{
        [self rbs_executeWithUrl:url placeholderImage:placeholder subject:subject];
    }
    return [subject deliverOnMainThread];
}

-(void)rbs_executeWithUrl:(NSURL*)url placeholderImage:(UIImage *)placeholder subject:(RACSubject*)subject{
    [self rbs_setImageWithURL:url placeholderImage:placeholder completed:^(UIImage * _Nullable image, NSError * _Nullable error, RBSImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if(image && !error){
            [subject sendNext:image];
        }else{
            [subject sendError:error];
        }
    }];
}
@end
```

发现了问题吗？看不出来，如果你不了解RACSubject 的实现或者网上能找到的资料，就不知道为什么这里被Leak Profile 确定为Leak 部分。
大致意思就是RACSubject 的释放只会在 SendNext, sendError, sendComp 的协议调用才会触发完成，单从代码上看似没毛病。
可现在的场景是存在异步，而且又有可能被再次调用，这个被抛出的对象被外层所持有，导致问题就是，不被主动释放。
改动方式两个，一种是谁调用谁负责，另外一种，自动释放，当ImageView category 被dealloc的时候自动做到释放。
由于项目的特殊，这里说说第二种
当ImageView category 被dealloc的时候自动做到释放, 这个是怎么实现的呢？
RAC在内部做了dealloc 的swizz，会有专门的dispo 对象被触发。
改后的方式（这里改了顺带修改了weak的生命和使用, 原因是GCD切换的调用会在下一次main loop被执行，如果当前对象释放，这里就存在问题）

```Objective-C
@implementation UIImageView (Demo)

- (RACSignal*)rbs_setImageWithURL:(NSURL *)url{
   return [self rbs_setImageWithURL:url placeholderImage:nil];
}

- (RACSignal*)rbs_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder{
    if (url.absoluteString.length == 0) {
        [self cancelCurrentImageLoad];
        self.image = placeholder;
        return [RACSignal empty];
    }
    RACSubject *subject = [RACSubject subject];
    if (self.frame.size.width == 0 && self.frame.size.height == 0) {
        _weak typeof(self) weakSelf = self;
        __weak typeof(subject) weakSubject = subject;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf rbs_executeWithUrl:url placeholderImage:placeholder subject:weakSubject];
        });
    }else{
        [self rbs_executeWithUrl:url placeholderImage:placeholder subject:subject];
    }
    return [[subject deliverOnMainThread] takeUntil:self.rac_willDeallocSignal];
}

-(void)rbs_executeWithUrl:(NSURL*)url placeholderImage:(UIImage *)placeholder subject:(RACSubject*)subject{
    __weak typeof(subject) weakSubject = subject;
    [self rbs_setImageWithURL:url placeholderImage:placeholder completed:^(UIImage * _Nullable image, NSError * _Nullable error, RBSImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if(image && !error){
            [weakSubject sendNext:image];
        }else{
            [weakSubject sendError:error];
        }
    }];
}
@end
```

就是这句 takeUntil:self.rac_willDeallocSignal 来解决这次带来的泄漏问题。

> [[subject deliverOnMainThread] takeUntil:self.rac_willDeallocSignal]

总结：通过使用 RACSubject 要清楚了解里面的工作原因，RACSubject 产生的是一个热信号，内部的subscribeNext 会触发map，然后到bind，bind 内部block了自身的操作。
RAC在设计的时候，一些操作的解开需要自己来操作，这样导致很多刚步入的就面临各种使用苦难，也许别人说度过这段期间就好了，前提组内需要一个经验丰富的RAC的程序员。

## KVO中的多级KayPaths

直接进入话题，大家都知道Cocoa 下的KVO 支持的KeyPath 都是一级的，就是Observer 的当前级别，如果需要跨区域这个过程就复杂了。RAC 带来的一个场景就是解决了KeyPaths 多层级，代码RACKVOWrapper 这个Category 就是多层级的实现。
思路，通过当前层级的Observe 去KeyPath下一级，然后递归下去，多层深度直到KeyPaths中的最后一级。实现的代码201行，可里面牵连的业务包含8个头文件内容。

简单说下，首先需要解析原始KeyPaths的路径，通过第一层KeyPath 的runtime，Keypath下一级，这个过程是持续的，然后将每一层rac_propertyAttributes的解析放入到一个集合数据结构中存储。

### 自己制造个轮子

有人说，咋不直接使用KeyPaths的倒数第二层作为Observe，最后一层作为Cocoa的最后KeyPath，这样不就解决问题了。
可是不然，举个例子，如果这个KeyPaths中的每层路径都被已经实例化对象，这样没问题，如果这个Observe被定义在init中，而其他的keyPaths中的某层路径没有被实例化，自己写的KVO失败了。
再举一个例子，如果KeyPaths上的所有层级都已经实例化了，上述的解决方案成功了，如果这个时候突然对之间构建的KeyPaths中的某一层路径设置为nil，然后再次初始化，同样KVO再次失败。
上述的解决方案就不行了。

## 代码消耗

RAC 这个代码库确实足够庞大的，做的分装部分包含了C，和ObjC，然后就是各种场景下的锁。
RAC的各种业务场景层的代码，代码文件占比533k，190个文件。如果说只是一个场景，这里面就占用很大一部分的操作。
先来说说锁这个事，作为项目中比较常用的业务也是在主线程中使用，而RAC来带的锁场景就多了去了，常见的锁，基本封盖。

上述提到 RACKVOWrapper 这个类，里面的会牵扯一些RAC的信号相关的代码，每一层 KeyPaths 解析，又是一层消耗。

存在的业务场景多，这里就不一一举例，所以单方面考虑还是不切实际。只能根据具体业务，具体来做，没必要杀鸡用牛刀。

## 后续

我们的业务中存在了RAC，在性能方面，RAC阻碍了我们的关键路径，我们通过KVO 加block 去替换RACObserve 的工作，但是面临的问题就是多层级KVO的实现被挡住了，后期考虑自己写一套多层级的KeyPaths解决方案，但是会尽量轻，解决当下需要重构的业务。后期尽量通过事件驱动，而不是太多KVO，KVO就好比一个大海中的冰山，太多不安全和不稳定。RAC的思想很好，但是可以通过其他的方式来做，没有业务，就没有技术。
