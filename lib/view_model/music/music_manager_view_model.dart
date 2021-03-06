import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:re_re_ca/model/entity/music/music.dart';
import 'package:re_re_ca/model/repository_imf/music_repository.dart';
import 'package:re_re_ca/state/music_state.dart';
import 'package:re_re_ca/view_model/music/audio_handler.dart';

class MusicManagerViewModel extends StateNotifier<MusicState> {
  final AudioHandlerViewModel _audioHandlerViewModel;
  final IMusicRepository _musicRepository;

  MusicManagerViewModel(this._audioHandlerViewModel, this._musicRepository)
      : super(const MusicState());

  void init() async {
    await _loadPlayList();
    _listenToCurrentPosition();
    _listenToBufferedPosition();
    _listenToTotalDuration();
    _listenToChangeMusic();
    _listenToIsPlay();
    _listenToMusic();
  }

  Future<void> _loadPlayList() async {
    final List<Music> musicList = await _musicRepository.getListMusics();
    state = state.copyWith(musicList: musicList);
    final List<MediaItem> mediaItems = musicList
        .map((music) => MediaItem(id: music.title, title: music.title))
        .toList();
    await _audioHandlerViewModel.addQueueItems(mediaItems);
  }

  void _listenToMusic() {
    _audioHandlerViewModel.mediaItem.listen((value) {
      print(value?.title);
    });
  }

  void _listenToCurrentPosition() {
    AudioService.position.listen((position) {
      final newState = ProgressBarState(
          current: position,
          buffered: state.progressBarState.buffered,
          total: state.progressBarState.total);
      state = state.copyWith(progressBarState: newState);
    });
  }

  void _listenToBufferedPosition() {
    _audioHandlerViewModel.playbackState.listen((playbackState) {
      final newState = ProgressBarState(
          current: state.progressBarState.current,
          buffered: playbackState.bufferedPosition,
          total: state.progressBarState.total);
      state = state.copyWith(progressBarState: newState);
    });
  }

  void _listenToTotalDuration() {
    _audioHandlerViewModel.mediaItem.listen((mediaItem) {
      final newState = ProgressBarState(
          current: state.progressBarState.current,
          buffered: state.progressBarState.buffered,
          total: mediaItem?.duration ?? Duration.zero);
      state = state.copyWith(progressBarState: newState);
    });
  }

  void _listenToChangeMusic() {
    _audioHandlerViewModel.mediaItem.listen((value) {
      state = state.copyWith(musicTitle: value?.title ?? "");
    });
  }

  void _listenToIsPlay() {
    _audioHandlerViewModel.playbackState.listen((backState) {
      state = state.copyWith(isPlaying: backState.playing);
    });
  }

  Future<void> tapMusic(int index) async {
    await _audioHandlerViewModel.tapMusic(index);
  }

  Future<void> play() async {
    await _audioHandlerViewModel.play();
  }

  Future<void> stop() async {
    _audioHandlerViewModel.stop();
  }

  Future<void> pause() async {
    _audioHandlerViewModel.pause();
  }

  Future<void> skipToNext() async {
    _audioHandlerViewModel.skipToNext();
  }

  Future<void> skipToPrevious() async {
    _audioHandlerViewModel.skipToPrevious();
  }

  Future<void> addQueueItems() async {
    final List<Music> musicList = await _musicRepository.getListMusics();
    final List<MediaItem> mediaItems = musicList
        .map((music) => MediaItem(id: music.title, title: music.title))
        .toList();
    _audioHandlerViewModel.addQueueItems(mediaItems);
  }

  // Future<void> confirmPlayList() async {
  //   _audioHandlerViewModel.confirmPlayList();
  // }

  Future<void> clear() async {
    _audioHandlerViewModel.clear();
  }

  //Music?????????????????????
  Future<void> setPlayList() async {
    final List<Music> musicList = state.musicList;
    final List<MediaItem> mediaItems = musicList
        .map((music) => MediaItem(id: music.title, title: music.title))
        .toList();
    await _audioHandlerViewModel.setPlayList(mediaItems);
  }

  Future<void> downLoadMusic(String url) async {
    final Music newMusic = await _musicRepository.downLoadMusic(url);
    final MediaItem mediaItem =
        MediaItem(id: newMusic.title, title: newMusic.title);
    await _audioHandlerViewModel.addQueueItem(mediaItem);
    state.musicList.add(newMusic);
    final newMusicList = state.musicList;
    state = state.copyWith(musicList: newMusicList);
  }

  Future<void> getMusicList() async {
    final List<Music> _musicList = await _musicRepository.getListMusics();
    state = state.copyWith(musicList: _musicList);
  }

  Future<void> seek(Duration position) => _audioHandlerViewModel.seek(position);

  Future<void> removeMusic(int index) async {
    //queue?????????????????????
    await _audioHandlerViewModel.removeQueueItemAt(index);
    //???????????????????????????
    await _musicRepository.deleteMusic(state.musicList[index].title);
    //????????????????????????
    state.musicList.removeAt(index);
    //???????????????List?????????
    state = state.copyWith(musicList: state.musicList);
    //???????????????????????????
    await _musicRepository.saveListMusic(state.musicList);
  }
}
