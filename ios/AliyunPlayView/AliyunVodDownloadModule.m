//
//  AliyunVodDownloadModule.m
//  AliyunPlayView
//
//  Created by vun on 2020/1/11.
//

#import "AliyunVodDownloadModule.h"

@implementation AliyunVodDownloadModule {
    Boolean mAuthInfoSet;
    NSCondition *mAuthInfoLock;
    NSString *mAuthInfoVidId;
    NSString *mAuthInfoAuthStr;
    NSString *mSavePath;
    NSMutableDictionary *mCurrentDownloadMediaInfo;
    AliMediaDownloader *mDownloader;
}

NSString *const EVENT_UPDATE_AUTH = @"AliyunVod.Downloader.UpdateAuth";
NSString *const EVENT_PREPARED = @"AliyunVod.Downloader.Prepared";
NSString *const ALI_DL_EVENT_START = @"AliyunVod.Downloader.Start";
NSString *const EVENT_DOWNLOAD_PROGRESS = @"AliyunVod.Downloader.Progress";
NSString *const EVENT_COMPLETE = @"AliyunVod.Downloader.Completed";
NSString *const EVENT_STOP = @"AliyunVod.Downloader.Stop";
NSString *const EVENT_ERROR = @"AliyunVod.Downloader.Error";

RCT_EXPORT_MODULE()

- (instancetype)init
{
    self = [super init];
    if (self) {
        mAuthInfoLock = [[NSCondition alloc] init];
        mAuthInfoSet = NO;

        mSavePath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        mCurrentDownloadMediaInfo = [[NSMutableDictionary alloc] init];
    }
    return self;
}

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

-(void) initalize {
    NSLog(@"ios initialize");

    mAuthInfoLock = [[NSCondition alloc] init];
    mAuthInfoSet = NO;
}

- (NSArray<NSString *> *)supportedEvents {
    return @[EVENT_UPDATE_AUTH, EVENT_STOP, ALI_DL_EVENT_START, EVENT_ERROR, EVENT_COMPLETE, EVENT_PREPARED, EVENT_DOWNLOAD_PROGRESS];
}

-(NSString*) onGetPlayAuth:(NSString*)vid format:(NSString*)format quality:(AliyunVodPlayerVideoQuality)quality {
    [self sendEventWithName:EVENT_UPDATE_AUTH body:@{@"vidId": vid}];
    [mAuthInfoLock lock];
    while(!mAuthInfoSet) {
        [mAuthInfoLock wait];
    }

    return mAuthInfoAuthStr;
}

RCT_EXPORT_METHOD(setAuth:(NSString*)vidId authStr:(NSString*)authStr) {
    [mAuthInfoLock lock];

    mAuthInfoVidId = vidId;
    mAuthInfoAuthStr = authStr;
    mAuthInfoSet = YES;

    [mAuthInfoLock signal];
    [mAuthInfoLock unlock];
}

-(void) onPrepare:(NSArray<AliyunDownloadMediaInfo*>*)mediaInfos {
    [self sendEventWithName:EVENT_PREPARED body:mediaInfos];
}

-(void)onPrepared:(AliMediaDownloader *)downloader mediaInfo:(AVPMediaInfo *)info {
    NSArray<AVPTrackInfo*>* tracks = info.tracks;
    [downloader selectTrack:[tracks objectAtIndex:0].trackIndex];
    [downloader start];

    [self sendEventWithName:EVENT_PREPARED body:@{@"@items": @[info]}];
}

-(void) onStart:(AliyunDownloadMediaInfo*)mediaInfo {
    [self sendEventWithName:ALI_DL_EVENT_START body:@{@"@items": @[mediaInfo]}];
}

-(void) onProgress:(AliyunDownloadMediaInfo*)mediaInfo {
    [self sendEventWithName:EVENT_DOWNLOAD_PROGRESS body:@[mediaInfo]];
}

-(void)onDownloadingProgress:(AliMediaDownloader *)downloader percentage:(int)percent {
    NSNumber *x = [NSNumber numberWithFloat:((float)percent/100.0)];

    [mCurrentDownloadMediaInfo setValue:x forKey:@"progress"];
    [mCurrentDownloadMediaInfo setValue:downloader.downloadedFilePath forKey:@"savePath"];
    [self sendEventWithName:EVENT_DOWNLOAD_PROGRESS body:@{@"media":@{@"@items": @[mCurrentDownloadMediaInfo]}, @"progress": x}];
}

-(void) onStop:(AliyunDownloadMediaInfo*)mediaInfo {
    [self sendEventWithName:EVENT_STOP body:@[mediaInfo]];
}

-(void)onCompletion:(AliMediaDownloader *)downloader {


    [mCurrentDownloadMediaInfo setValue:downloader.downloadedFilePath forKey:@"savePath"];

    [mDownloader destroy];
    downloader = nil;
    mDownloader = nil;

    [self sendEventWithName:EVENT_COMPLETE body:@{@"@items": @[mCurrentDownloadMediaInfo]}];
}

-(void)onError:(AliMediaDownloader *)downloader errorModel:(AVPErrorModel *)errorModel {
    [self sendEventWithName:EVENT_ERROR body:@{
        @"media": mCurrentDownloadMediaInfo,
        @"i": [NSString stringWithFormat:@"%lu", errorModel.code],
        @"s1": errorModel.message
    }];
}

RCT_EXPORT_METHOD(startAuthDownload:(NSString*)vidId authStr:(NSString*)authStr format:(NSString*)format quality:(NSString*)quality encrypted:(BOOL*)encrypted) {
    AVPVidAuthSource* authSrc = [[AVPVidAuthSource alloc] init];
    [authSrc setVid:vidId];
    [authSrc setPlayAuth:authStr];
    [authSrc setQuality:quality];
    [authSrc setRegion:@"cn-shanghai"];

    authSrc.vid = vidId;

    mDownloader = [[AliMediaDownloader alloc] init];

    NSString *savePath = [NSString stringWithFormat:@"%@/%@.%@", mSavePath, vidId, format];
    NSLog(savePath);

    [mCurrentDownloadMediaInfo setValue:vidId forKey:@"vid"];
    [mCurrentDownloadMediaInfo setValue:0 forKey:@"progress"];
    [mCurrentDownloadMediaInfo setValue:savePath forKey:@"savePath"];
    [mCurrentDownloadMediaInfo setValue:format forKey:format];

    [mDownloader setDelegate:self];
    [mDownloader setSaveDirectory:mSavePath];
    [mDownloader prepareWithPlayAuth:authSrc];
}

@end
