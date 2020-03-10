//
//  AliyunPlayerView.m
//  AliyunPlayerDemo
//
//  Created by 何晏波 on 2019/5/15.
//

#import "AliyunPlayerView.h"
#define WeakObj(o) __weak typeof(o) o##Weak = o;

@interface AliyunPlayerView ()

@property (nonatomic, strong) NSDictionary *prepareAsyncParams;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation AliyunPlayerView {
    UIView *mView;
    AVPTrackInfo *mTrackInfo;
    AVPMediaInfo *mMediaInfo;
}

- (void)dealloc {
  if (_aliPlayer) {
      // 销毁
      [self.aliPlayer destroy];
    [_aliPlayer destroy];
    _aliPlayer = nil;
  }
}

#pragma mark - Props config
- (void)setPrepareAsyncParams:(NSDictionary *)prepareAsyncParams {
  _prepareAsyncParams = prepareAsyncParams;
  [self setupAliPlayer];
}

- (void)setMuteMode:(BOOL)muteMode {
    self.aliPlayer.muted = muteMode;
}

- (void)setQuality:(NSInteger)quality {
//    self.aliPlayer.quality = quality;
}

- (void)setVolume:(float)volume {
    self.aliPlayer.volume = volume;
}

- (void)setBrightness:(float)brightness {
//    self.aliPlayer.brightness = brightness;
}

- (void)setupAliPlayer {
    self.aliPlayer.playerView = self;
  
  NSString *type = [_prepareAsyncParams objectForKey:@"type"];
  if ([type isEqualToString:@"vidSts"]) {
    NSString *vid = [_prepareAsyncParams objectForKey:@"vid"];
    NSString *accessKeyId = [_prepareAsyncParams objectForKey:@"accessKeyId"];
    NSString *accessKeySecret = [_prepareAsyncParams objectForKey:@"accessKeySecret"];
    NSString *securityToken = [_prepareAsyncParams objectForKey:@"securityToken"];

    AVPVidStsSource *stsSrc = [[AVPVidStsSource alloc] init];
    [stsSrc setVid:vid];
      [stsSrc setAccessKeyId:accessKeyId];
    [stsSrc setAccessKeySecret:accessKeySecret];
    [stsSrc setSecurityToken:securityToken];
      
    [self.aliPlayer setStsSource:stsSrc];
  } else if ([type isEqualToString:@"url"]) {
      NSString *urlStr = [_prepareAsyncParams objectForKey:@"url"];
      NSURL *url = [NSURL URLWithString:urlStr];
      
      AVPUrlSource *urlSrc = [[AVPUrlSource alloc] init];
      [urlSrc setPlayerUrl:url];
      [self.aliPlayer setUrlSource:urlSrc];
  } else if([type isEqualToString:@"vidAuth"]) {
      NSString *vid = [_prepareAsyncParams objectForKey:@"vid"];
      NSString *playAuth = [_prepareAsyncParams objectForKey:@"playAuth"];
      AVPVidAuthSource *vidAuthSrc = [[AVPVidAuthSource alloc] init];
      [vidAuthSrc setVid:vid];
      [vidAuthSrc setPlayAuth:playAuth];
      [vidAuthSrc setRegion:@"cn-shanghai"];
      
      [self.aliPlayer setAuthSource:vidAuthSrc];
  }
    
    [self.aliPlayer prepare];
}

- (void) layoutSubviews {
  [super layoutSubviews];
  for(UIView* view in self.subviews) {
    [view setFrame:self.bounds];
  }
}

#pragma mark - 播放器初始化
-(AliPlayer *)aliPlayer{
  if (!_aliPlayer) {
    _aliPlayer = [[AliPlayer alloc] init];
    _aliPlayer.delegate = self;
    _aliPlayer.autoPlay = YES;
    NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [pathArray objectAtIndex:0];
  }
  return _aliPlayer;
}

#pragma mark - AliyunVodPlayerDelegate
- (void)onPlayerEvent:(AliPlayer *)vodPlayer eventType:(AVPEventType)event{
  NSLog(@"onEventCallback: %ld", event);
  
  NSMutableDictionary *callbackExt = [NSMutableDictionary dictionary];
  //这里监控播放事件回调
  //主要事件如下：
  switch (event) {
    case AVPEventPrepareDone:
      //播放准备完成时触发
      [_aliPlayer start];
//      [_aliPlayer setCirclePlay:false];
      if (self.onGetAliyunMediaInfo) {
          NSMutableDictionary *info = [NSMutableDictionary dictionary];
          mTrackInfo = [self.aliPlayer getCurrentTrack:AVPTRACK_TYPE_VIDEO];
          mMediaInfo = [vodPlayer getMediaInfo];
//          info[@"videoId"] = vidInfo.videoId;
          info[@"title"] = mMediaInfo.title;
          info[@"duration"] = @(mMediaInfo.duration);
          info[@"coverUrl"] = mMediaInfo.coverURL;
//          info[@"videoQuality"] = @(video.videoQuality);
//          info[@"videoDefinition"] = video.videoDefinition;
//          info[@"allSupportQualitys"] = video.allSupportQualitys;
          self.onGetAliyunMediaInfo(info);
      }
      break;
    case AVPEventAutoPlayStart:
      //暂停后恢复播放时触发
//      [self setupTimer];
      break;
    case AVPEventFirstRenderedStart:
      //播放视频首帧显示出来时触发
//      [self setupTimer];
      break;
    case AliyunVodPlayerEventPause:
      //视频暂停时触发
//      [self clearTimer];
      break;
    case AliyunVodPlayerEventStop:
      //主动使用stop接口时触发
//      [self clearTimer];
      break;
    case AliyunVodPlayerEventFinish:
      //视频正常播放完成时触发
      NSLog(@"视频播放完毕");
//       [self clearTimer];
      break;
    case AliyunVodPlayerEventBeginLoading:
      //视频开始载入时触发
      break;
    case AliyunVodPlayerEventEndLoading:
      //视频加载完成时触发
      break;
    case AliyunVodPlayerEventSeekDone:
      //视频Seek完成时触发
      break;
    default:
      break;
  }

  
  NSLog(@"视频播放事件%d",event);
  [callbackExt setObject:@(event) forKey:@"event"];
  if (self.onEventCallback) {
    self.onEventCallback(callbackExt);
  }
}

- (void)vodPlayer:(AliyunVodPlayer *)vodPlayer playBackErrorModel:(AliyunPlayerVideoErrorModel *)errorModel{
  //播放出错时触发，通过errorModel可以查看错误码、错误信息、视频ID、视频地址和requestId。
  NSLog(@"errorModel: %d", errorModel.errorCode);
    if (self.onPlayBackErrorModel) {
        self.onPlayBackErrorModel(@{
                                 @"errorCode": @(errorModel.errorCode),
                                 @"errorMsg": errorModel.errorMsg,
                                 @"errorVid": errorModel.errorVid,
                                 @"errorUrl": errorModel.errorUrl,
                                 @"errorRequestId": errorModel.errorRequestId
                                 }
                                );
    }
}
- (void)vodPlayer:(AliyunVodPlayer*)vodPlayer willSwitchToQuality:(AliyunVodPlayerVideoQuality)quality videoDefinition:(NSString*)videoDefinition{
  //将要切换清晰度时触发
  NSLog(@"willSwitchToQuality:%@", videoDefinition);
    if (self.onSwitchToQuality) {
        self.onSwitchToQuality(@{
                                 @"type": @"will",
                                 @"quality": @(quality),
                                 @"videoDefinition": videoDefinition}
                               );
    }
}
- (void)vodPlayer:(AliyunVodPlayer *)vodPlayer didSwitchToQuality:(AliyunVodPlayerVideoQuality)quality videoDefinition:(NSString*)videoDefinition{
    //清晰度切换完成后触发
    if (self.onSwitchToQuality) {
        self.onSwitchToQuality(@{
                                 @"type": @"did",
                                 @"quality": @(quality),
                                 @"videoDefinition": videoDefinition}
                                );
    }
    
}
- (void)vodPlayer:(AliyunVodPlayer*)vodPlayer failSwitchToQuality:(AliyunVodPlayerVideoQuality)quality videoDefinition:(NSString*)videoDefinition{
  //清晰度切换失败触发
    if (self.onSwitchToQuality) {
        self.onSwitchToQuality(@{
                                 @"type": @"fail",
                                 @"quality": @(quality),
                                 @"videoDefinition": videoDefinition}
                               );
    }
    
}
- (void)onCircleStartWithVodPlayer:(AliyunVodPlayer*)vodPlayer{
  //开启循环播放功能，开始循环播放时接收此事件。
}
- (void)onTimeExpiredErrorWithVodPlayer:(AliyunVodPlayer *)vodPlayer{
  //播放器鉴权数据过期回调，出现过期可重新prepare新的地址或进行UI上的错误提醒。
}

- (void)vodPlayerPlaybackAddressExpiredWithVideoId:(NSString *)videoId quality:(AliyunVodPlayerVideoQuality)quality videoDefinition:(NSString*)videoDefinition{
  //鉴权有效期为2小时，在这个回调里面可以提前请求新的鉴权，stop上一次播放，prepare新的地址，seek到当前位置
}

- (void)onCurrentPositionUpdate:(AliPlayer*)player position:(int64_t)position {
    NSDictionary *eventParams = @{@"currentTime": [NSNumber numberWithLong:position], @"duration": [NSNumber numberWithLong:player.duration]};
    self.onPlayingCallback(eventParams);
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

@end
