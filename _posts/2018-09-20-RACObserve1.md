---
layout: post
title: "RACObserve 的思考篇（1）"
date: 2018-09-14
categories: macOS&iOS
tags: iOS,ObjC,RAC
---

# RACObserve 的思考

千呼万唤最终在新项目中接受了RAC的代码，很早之前做个一个项目，也是大量使用RAC，也没有太多考虑RAC的副作用有多大，如今总算是在大项目中去使用了，可是到了性能优化的层面，发现RAC带来的性能还是值得
大家去重新思考。

RAC 的内部实现和代码架构, 等各种网上说的有点就不说了，这里主要谈谈碰见的问题。

大致有几点：

1. 循环引用。
2. 代码消耗
3. KVO中的多级KayPaths

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
    [self rbs_setImageWithURL:url placeholderImage:placeholder completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
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
    [self rbs_setImageWithURL:url placeholderImage:placeholder completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
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

RAC的性能有影响吗，往后的工作就需要考虑了。详细看后续介绍。
