import 'package:flutter_tiktok/mock/video.dart';
import 'package:flutter_tiktok/pages/cameraPage.dart';
import 'package:flutter_tiktok/pages/followPage.dart';
import 'package:flutter_tiktok/pages/searchPage.dart';
import 'package:flutter_tiktok/pages/userPage.dart';
import 'package:flutter_tiktok/views/tikTokCommentBottomSheet.dart';
import 'package:flutter_tiktok/views/tikTokHeader.dart';
import 'package:flutter_tiktok/views/tikTokScaffold.dart';
import 'package:flutter_tiktok/views/tikTokVideo.dart';
import 'package:flutter_tiktok/views/tikTokVideoButtonColumn.dart';
import 'package:flutter_tiktok/views/tikTokVideoPlayer.dart';
import 'package:flutter_tiktok/views/tiktokTabBar.dart';
import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:safemap/safemap.dart';

import 'msgPage.dart';

/// 单独修改了bottomSheet组件的高度
import 'package:flutter_tiktok/other/bottomSheet.dart' as CustomBottomSheet;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  TikTokPageTag tabBarType = TikTokPageTag.home; //底部bar

  TikTokScaffoldController tkController = TikTokScaffoldController();

  PageController _pageController = PageController();

  VideoListController _videoListController = VideoListController();

  /// 记录点赞
  Map<int, bool> favoriteMap = {};

  List<UserVideo> videoDataList = [];

  /// 生命周期改变回调时候。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    //当应用不是可见，可响应用户输入状态下，将视频当前播放器进行暂停播放
    if (state != AppLifecycleState.resumed) {
      _videoListController.currentPlayer.pause();
    }
  }

  @override
  void dispose() {
    //WidgetsBinding 可监听每一帧绘制
    //移除释放
    WidgetsBinding.instance.removeObserver(this);
    //暂停视图播放
    _videoListController.currentPlayer.pause();
    //进行释放
    super.dispose();
  }

  @override
  void initState() {
    //组装视频数据列表
    videoDataList = UserVideo.fetchVideo();
    //将监听绑定当前
    WidgetsBinding.instance.addObserver(this);
    //初始化视频列表控制器,将页面控制和视频对象列表放进去
    _videoListController.init(
      _pageController,
      videoDataList,
    );
    //对主对象进行监听
    tkController.addListener(
      () {
        //如果对象的当前值在局中位置,则将视频控制对象的当前播放进行播放
        if (tkController.value == TikTokPagePositon.middle) {
          _videoListController.currentPlayer.start();
        } else {
          //否则暂停播放。
          _videoListController.currentPlayer.pause();
        }
      },
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //根据当前tabbarType判断所在点击页面,并且将当前页面切换
    Widget currentPage;
    //判断当前tabbar标签
    switch (tabBarType) {
      case TikTokPageTag.home:
        break;
      case TikTokPageTag.follow:
        currentPage = FollowPage();
        break;
      case TikTokPageTag.msg:
        currentPage = MsgPage();
        break;
      case TikTokPageTag.me:
        currentPage = UserPage(isSelfPage: true);
        break;
    }
    //a:硬件的纵横比
    double a = MediaQuery.of(context).size.aspectRatio;
    //页面组件小于0.55?TODO 0.55什么含义? 平板手机？
    bool hasBottomPadding = a < 0.55;

    bool hasBackground = hasBottomPadding;
    //并且当前页面不是首页
    hasBackground = tabBarType != TikTokPageTag.home;
    if (hasBottomPadding) {
      hasBackground = true;
    }
    Widget tikTokTabBar = TikTokTabBar(
      hasBackground: hasBackground,
      current: tabBarType,
      onTabSwitch: (type) async {
        //内部函数切换页面,根据类型
        setState(() {
          tabBarType = type;
          //判断类型等于首页时
          if (type == TikTokPageTag.home) {
            //视频播放
            _videoListController.currentPlayer.start();
          } else {
            //视频暂停
            _videoListController.currentPlayer.pause();
          }
        });
      },
      //新增视频 触发后回调函数
      onAddButton: () {
        //页面跳转
        Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => CameraPage(),
          ),
        );
      },
    );

    var userPage = UserPage(
      isSelfPage: false, //是否自己议案
      canPop: true, //是否弹开
      onPop: () {
        tkController.animateToMiddle();
      },
    );
    var searchPage = SearchPage(
      onPop: tkController.animateToMiddle,
    );

    var header = tabBarType == TikTokPageTag.home
        ? TikTokHeader(
            onSearch: () {
              tkController.animateToLeft();
            },
          )
        : Container();

    // 组合
    return TikTokScaffold(
      controller: tkController,
      hasBottomPadding: hasBackground,
      tabBar: tikTokTabBar,
      header: header,
      leftPage: searchPage,
      rightPage: userPage,
      enableGesture: tabBarType == TikTokPageTag.home,
      // onPullDownRefresh: _fetchData,
      page: Stack(
        // index: currentPage == null ? 0 : 1,
        children: <Widget>[
          PageView.builder(
            key: Key('home'),
            controller: _pageController,
            pageSnapping: true,
            physics: ClampingScrollPhysics(),
            scrollDirection: Axis.vertical,
            itemCount: _videoListController.videoCount,
            itemBuilder: (context, i) {
              // 拼一个视频组件出来
              var data = videoDataList[i];
              bool isF = SafeMap(favoriteMap)[i].boolean ?? false;
              var player = _videoListController.playerOfIndex(i);
              // 右侧按钮列
              Widget buttons = TikTokButtonColumn(
                isFavorite: isF,
                onAvatar: () {
                  tkController.animateToPage(TikTokPagePositon.right);
                },
                onFavorite: () {
                  setState(() {
                    favoriteMap[i] = !isF;
                  });
                  // showAboutDialog(context: context);
                },
                onComment: () {
                  CustomBottomSheet.showModalBottomSheet(
                    backgroundColor: Colors.white.withOpacity(0),
                    context: context,
                    builder: (BuildContext context) =>
                        TikTokCommentBottomSheet(),
                  );
                },
                onShare: () {},
              );
              // video
              Widget currentVideo = Center(
                child: FijkView(
                  fit: FijkFit.fitHeight,
                  player: player,
                  color: Colors.black,
                  panelBuilder: (_, __, ___, ____, _____) => Container(),
                ),
              );

              currentVideo = TikTokVideoPage(
                hidePauseIcon: player.state != FijkState.paused,
                aspectRatio: 9 / 16.0,
                key: Key(data.url + '$i'),
                tag: data.url,
                bottomPadding: hasBottomPadding ? 16.0 : 16.0,
                userInfoWidget: VideoUserInfo(
                  desc: data.desc,
                  bottomPadding: hasBottomPadding ? 16.0 : 50.0,
                  // onGoodGift: () => showDialog(
                  //   context: context,
                  //   builder: (_) => FreeGiftDialog(),
                  // ),
                ),
                onSingleTap: () async {
                  if (player.state == FijkState.started) {
                    await player.pause();
                  } else {
                    await player.start();
                  }
                  setState(() {});
                },
                onAddFavorite: () {
                  setState(() {
                    favoriteMap[i] = true;
                  });
                },
                rightButtonColumn: buttons,
                video: currentVideo,
              );
              return currentVideo;
            },
          ),
          Opacity(
            opacity: 1,
            child: currentPage ?? Container(),
          ),
          // Center(
          //   child: Text(_currentIndex.toString()),
          // )
        ],
      ),
    );
  }
}
