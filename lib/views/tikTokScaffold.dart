import 'dart:math';
import 'package:flutter_tiktok/style/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

const double scrollSpeed = 300;

enum TikTokPagePositon {
  left,
  right,
  middle,
}

//定义的一个页面控制
class TikTokScaffoldController extends ValueNotifier<TikTokPagePositon> {
  TikTokScaffoldController([
    TikTokPagePositon value = TikTokPagePositon.middle,
  ]) : super(value);

  Future animateToPage(TikTokPagePositon pagePositon) {
    return _onAnimateToPage?.call(pagePositon);
  }

  Future animateToLeft() {
    return _onAnimateToPage?.call(TikTokPagePositon.left);
  }

  Future animateToRight() {
    return _onAnimateToPage?.call(TikTokPagePositon.right);
  }

  Future animateToMiddle() {
    return _onAnimateToPage?.call(TikTokPagePositon.middle);
  }

  Future Function(TikTokPagePositon pagePositon) _onAnimateToPage;
}

class TikTokScaffold extends StatefulWidget {
  final TikTokScaffoldController controller;

  /// 首页的顶部
  final Widget header;

  /// 底部导航
  final Widget tabBar;

  /// 左滑页面
  final Widget leftPage;

  /// 右滑页面
  final Widget rightPage;

  /// 视频序号
  final int currentIndex;

  final bool hasBottomPadding;
  final bool enableGesture;

  final Widget page;

  final Function() onPullDownRefresh;

  const TikTokScaffold({
    Key key,
    this.header,
    this.tabBar,
    this.leftPage,
    this.rightPage,
    this.hasBottomPadding: false,
    this.page,
    this.currentIndex: 0,
    this.enableGesture,
    this.onPullDownRefresh,
    this.controller,
  }) : super(key: key);

  @override
  _TikTokScaffoldState createState() => _TikTokScaffoldState();
}

/**
 * 这个类主要定义好每个页面切换的动画效果，对于页面需要传入 Widget
 */
class _TikTokScaffoldState extends State<TikTokScaffold>
    with TickerProviderStateMixin {
  AnimationController animationControllerX; //x轴 动画控制器
  AnimationController animationControllerY; //y轴 动画控制器
  Animation<double> animationX;
  Animation<double> animationY;
  double offsetX = 0.0; //偏移量x
  double offsetY = 0.0; //偏移量y
  // int currentIndex = 0;
  double inMiddle = 0;

  @override
  void initState() {
    widget.controller._onAnimateToPage = animateToPage; //回调函数绑定当前异步方法
    super.initState();
  }

  Future animateToPage(p) async {
    if (screenWidth == null) {
      return null;
    }
    switch (p) {
      case TikTokPagePositon.left:
        await animateTo(screenWidth);
        break;
      case TikTokPagePositon.middle:
        await animateTo();
        break;
      case TikTokPagePositon.right:
        await animateTo(-screenWidth);
        break;
    }
    widget.controller.value = p;
  }

  double screenWidth;

  @override
  Widget build(BuildContext context) {
    //屏幕宽度
    screenWidth = MediaQuery.of(context).size.width; //获取屏幕信息
    // 先定义正常结构
    Widget body = Stack(
      children: <Widget>[
        //设定左边滑动效果和页面,范爷
        _LeftPageTransform(
          offsetX: offsetX,
          content: widget.leftPage,
        ),
        //设定中间页面滑动效果和页面,抽屉滑动效果
        _MiddlePage(
          absorbing: absorbing,
          onTopDrag: () {
            // absorbing = true;
            setState(() {});
          },
          offsetX: offsetX,
          offsetY: offsetY,
          header: widget.header, //头
          tabBar: widget.tabBar, //标签页
          isStack: !widget.hasBottomPadding, //没有底部填充,将页面置为 Stack
          page: widget.page,
        ),
        //右侧平移页面效果
        _RightPageTransform(
          offsetX: offsetX,
          offsetY: offsetY,
          content: widget.rightPage,
        ),
      ],
    );
    // 主体页面  增加手势控制
    body = GestureDetector(
      //垂直滑动
      onVerticalDragUpdate: calculateOffsetY,
      onVerticalDragEnd: (_) async {
        //如果不起用手势
        if (!widget.enableGesture) return;
        absorbing = false;
        //如果偏移y不等于0
        if (offsetY != 0) {
          //动画置为顶部
          await animateToTop();
          //回调调用
          widget.onPullDownRefresh?.call();
          //设置状态
          setState(() {});
        }
      },
      //水平滑动时
      onHorizontalDragEnd: (details) => onHorizontalDragEnd(
        details,
        screenWidth,
      ),
      // 水平方向滑动开始
      onHorizontalDragStart: (_) {
        if (!widget.enableGesture) return;
        //水平滑动开始时,x 和y停止
        animationControllerX?.stop();
        animationControllerY?.stop();
      },
      //水平滑动过程中
      onHorizontalDragUpdate: (details) => onHorizontalDragUpdate(
        details,
        screenWidth,
      ),
      child: body,
    );
    body = WillPopScope(
      onWillPop: () async {
        if (!widget.enableGesture) return true;
        if (inMiddle == 0) {
          return true;
        }
        widget.controller.animateToMiddle();
        return false;
      },
      child: Scaffold(
        body: body,
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
      ),
    );
    return body;
  }

  // 水平方向滑动中
  void onHorizontalDragUpdate(details, screenWidth) {
    if (!widget.enableGesture) return;
    // 控制 offsetX 的值在 -screenWidth 到 screenWidth 之间
    if (offsetX + details.delta.dx >= screenWidth) {
      setState(() {
        offsetX = screenWidth;
      });
    } else if (offsetX + details.delta.dx <= -screenWidth) {
      setState(() {
        offsetX = -screenWidth;
      });
    } else {
      setState(() {
        offsetX += details.delta.dx;
      });
    }
  }

  // 水平方向滑动结束
  onHorizontalDragEnd(details, screenWidth) {
    if (!widget.enableGesture) return;
    print('velocity:${details.velocity}');
    var vOffset = details.velocity.pixelsPerSecond.dx;

    // 速度很快时
    if (vOffset > scrollSpeed && inMiddle == 0) {
      // 去右边页面
      return animateToPage(TikTokPagePositon.left);
    } else if (vOffset < -scrollSpeed && inMiddle == 0) {
      // 去左边页面
      return animateToPage(TikTokPagePositon.right);
    } else if (inMiddle > 0 && vOffset < -scrollSpeed) {
      return animateToPage(TikTokPagePositon.middle);
    } else if (inMiddle < 0 && vOffset > scrollSpeed) {
      return animateToPage(TikTokPagePositon.middle);
    }
    // 当滑动停止的时候 根据 offsetX 的偏移量进行动画
    if (offsetX.abs() < screenWidth * 0.8) {
      // 中间页面
      return animateToPage(TikTokPagePositon.middle);
    } else if (offsetX > 0) {
      // 去左边页面
      return animateToPage(TikTokPagePositon.left);
    } else {
      // 去右边页面
      return animateToPage(TikTokPagePositon.right);
    }
  }

  /// 滑动到顶部
  ///
  /// [offsetY] to 0.0
  Future animateToTop() {
    animationControllerY = AnimationController(
        duration: Duration(milliseconds: offsetY.abs() * 1000 ~/ 60),
        vsync: this);
    final curve = CurvedAnimation(
        parent: animationControllerY, curve: Curves.easeOutCubic);
    animationY = Tween(begin: offsetY, end: 0.0).animate(curve)
      ..addListener(() {
        setState(() {
          offsetY = animationY.value;
        });
      });
    return animationControllerY.forward();
  }

  CurvedAnimation curvedAnimation() {
    animationControllerX = AnimationController(
        //动画控制器
        duration: Duration(milliseconds: max(offsetX.abs(), 60) * 1000 ~/ 500),
        vsync: this);
    return CurvedAnimation(
        parent: animationControllerX, curve: Curves.easeOutCubic);
  }

  Future animateTo([double end = 0.0]) {
    final curve = curvedAnimation();
    animationX = Tween(begin: offsetX, end: end).animate(curve)
      ..addListener(() {
        setState(() {
          offsetX = animationX.value;
        });
      });
    inMiddle = end;
    return animationControllerX.animateTo(1);
  }

  bool absorbing = false;
  double endOffset = 0.0;

  /// 计算[offsetY]
  ///
  /// 手指上滑,[absorbing]为false，不阻止事件，事件交给底层PageView处理
  /// 处于第一页且是下拉，则拦截滑动���件
  void calculateOffsetY(DragUpdateDetails details) {
    if (!widget.enableGesture) return;
    //当处于第一页,并且是下拉,则拦截事件
    if (inMiddle != 0) {
      setState(() => absorbing = false);
      return;
    }
    final tempY = offsetY + details.delta.dy / 2;
    //当前在第一页
    if (widget.currentIndex == 0) {
      //absorbing = true; // TODO:暂时屏蔽了下拉刷新
      if (tempY > 0) {
        if (tempY < 40) {
          offsetY = tempY; //偏移y设定
        } else if (offsetY != 40) {
          offsetY = 40; //偏移y设定
          // vibrate();
        }
      } else {
        absorbing = false;
      }
      setState(() {});
    }
    //不在第一页面下,下拉取消。
    else {
      absorbing = false;
      offsetY = 0;
      setState(() {});
    }
    print(absorbing.toString());
  }

  @override
  void dispose() {
    animationControllerX?.dispose();
    animationControllerY?.dispose();
    super.dispose();
  }
}

class _MiddlePage extends StatelessWidget {
  final bool absorbing;
  final bool isStack;
  final Widget page;

  final double offsetX;
  final double offsetY;
  final Function onTopDrag;

  final Widget header;
  final Widget tabBar;

  const _MiddlePage({
    Key key,
    this.absorbing,
    this.onTopDrag,
    this.offsetX,
    this.offsetY,
    this.isStack: false,
    @required this.header,
    @required this.tabBar,
    this.page,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    Widget tabBarContainer = tabBar ??
        Container(
          height: 44,
          child: Placeholder(
            color: Colors.red,
          ),
        );
    Widget mainVideoList = Container(
      color: ColorPlate.back1,
      padding: EdgeInsets.only(
        bottom: isStack ? 0 : 44 + MediaQuery.of(context).padding.bottom,
      ),
      child: page,
    );
    // 刷新标志
    Widget _headerContain;
    if (offsetY >= 20) {
      _headerContain = Opacity(
        opacity: (offsetY - 20) / 20,
        child: Transform.translate(
          offset: Offset(0, offsetY),
          child: Container(
            height: 44,
            child: Center(
              child: const Text(
                "下拉刷新内容",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: SysSize.normal,
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      _headerContain = Opacity(
        opacity: max(0, 1 - offsetY / 20),
        child: Transform.translate(
          offset: Offset(0, offsetY),
          child: SafeArea(
            child: Container(
              height: 44,
              child: header ?? Placeholder(color: Colors.green),
            ),
          ),
        ),
      );
    }

    Widget middle = Transform.translate(
      offset: Offset(offsetX > 0 ? offsetX : offsetX / 5, 0),
      child: Stack(
        children: <Widget>[
          Container(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: <Widget>[
                mainVideoList,
                tabBarContainer,
              ],
            ),
          ),
          _headerContain,
        ],
      ),
    );
    if (page is! PageView) {
      return middle;
    }
    return AbsorbPointer(
      absorbing: absorbing,
      child: NotificationListener<OverscrollIndicatorNotification>(
        onNotification: (notification) {
          notification.disallowGlow();
          return;
        },
        child: NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            // 当手指离开时，并且处于顶部则拦截PageView的滑动事件 TODO: 没有触发下拉刷新
            if (notification.direction == ScrollDirection.idle &&
                notification.metrics.pixels == 0.0) {
              onTopDrag?.call();
              return false;
            }
            return null;
          },
          child: middle,
        ),
      ),
    );
  }
}

/// 左侧Widget
///
/// 通过 [Transform.scale] 进行根据 [offsetX] 缩放
/// 最小 0.88 最大为 1
class _LeftPageTransform extends StatelessWidget {
  final double offsetX;
  final Widget content;

  const _LeftPageTransform({Key key, this.offsetX, this.content})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    //屏幕宽度
    final screenWidth = MediaQuery.of(context).size.width;

    //对子组件绘制时产生的一些特效
    //进行放大缩小效果
    //只针对绘制阶段,而不是布局阶段，所以无论组件做什么变化，其占用空间的大小和屏幕位置都是不变的，因为已经在布局阶段确认好了。
    //scale 放大的倍数
    return Transform.scale(
      scale: 0.80 + 0.20 * offsetX / screenWidth < 0.80
          ? 0.80
          : 0.80 + 0.20 * offsetX / screenWidth,
      //Placeholder 占位控件
      child: content ?? Placeholder(color: Colors.pink, strokeWidth: 5),
    );
  }
}

class _RightPageTransform extends StatelessWidget {
  final double offsetX;
  final double offsetY;

  final Widget content;

  const _RightPageTransform({
    Key key,
    this.offsetX,
    this.offsetY,
    this.content,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width; //屏幕的宽度
    final screenHeight = MediaQuery.of(context).size.height; //屏幕的高度
    //右侧页面平移效果
    return Transform.translate(
        offset: Offset(max(0, offsetX + screenWidth), 0), //偏移x+屏幕高度
        child: Container(
          width: screenWidth,
          height: screenHeight,
          color: Colors.transparent,
          //占位控件
          child: content ?? Placeholder(fallbackWidth: screenWidth),
        ));
  }
}
