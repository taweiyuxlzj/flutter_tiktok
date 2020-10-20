import 'dart:io';

Socket socket;
const mockImage =
    'http://baishan.oversketch.com/2019/11/05/1f676c8e4036fa5080892c5294c8e90b.PNG';
const mockVideo =
    'http://baishan.oversketch.com/2019/11/05/d07f2f1440e51b9680f4bcfe63b0ab67.MP4';
const mV2 =
    'http://baishan.oversketch.com/2020/05/14/32f5e6da40947c9880598b4d8b3671f4.MP4';
const mV3 =
    'http://baishan.oversketch.com/2020/05/14/55eae3664003437b80a159a9f2369474.MP4';
const mV4 =
    'http://baishan.oversketch.com/2020/05/14/59e0c1dd40bd4f41804f33814ad4b67a.MP4';


class UserVideo {
  final String url;
  final String image;
  final String desc;

  UserVideo({
    this.url: mockVideo,
    this.image: mockImage,
    this.desc,
  });

  static UserVideo get test =>
      UserVideo(image: '', url: mV2, desc: 'MV_TEST_2');

  static List<UserVideo> fetchVideo() {
    List<UserVideo> list = [];
    list.add(UserVideo(image: '', url: mockVideo, desc: '罗永浩'));
    list.add(UserVideo(image: '', url: mV2, desc: 'MV_TEST_2'));
    list.add(UserVideo(image: '', url: mV3, desc: 'MV_TEST_3'));
    list.add(UserVideo(image: '', url: mV4, desc: 'MV_TEST_4'));
    return list;
  }

  @override
  String toString() {
    return 'image:$image' '\nvideo:$url';
  }
}
