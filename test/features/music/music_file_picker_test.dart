import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/features/music/data/music_file_picker.dart';

void main() {
  group('trackNameFromPath：由路径推导曲目展示名', () {
    test('取文件名并去掉扩展名', () {
      expect(trackNameFromPath('/Users/hu/Music/大理城·风花雪月.mp3'), '大理城·风花雪月');
    });

    test('支持 Windows 风格分隔符与多点文件名', () {
      expect(trackNameFromPath(r'D:\Music\苏州·烟雨行舟.flac'), '苏州·烟雨行舟');
      expect(trackNameFromPath('/a/b/song.part1.m4a'), 'song.part1');
    });

    test('无扩展名 / 隐藏文件时保留原名', () {
      expect(trackNameFromPath('/a/b/洛神'), '洛神');
      expect(trackNameFromPath('/a/b/.hidden'), '.hidden');
    });
  });
}
