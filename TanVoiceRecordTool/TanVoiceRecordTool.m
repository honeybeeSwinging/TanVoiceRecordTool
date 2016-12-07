//
//  YCRecordTool.m
//  Truelove
//
//  Created by Tan on 16/2/29.
//  Copyright © 2016年 YCTime. All rights reserved.
//

#import "TanVoiceRecordTool"
#import <AVFoundation/AVFoundation.h>

@interface TanVoiceRecordTool ()<AVAudioRecorderDelegate>

@property(nonatomic, strong) AVAudioRecorder *recorder;
@property(nonatomic, strong) NSTimer *recorderSoundLevelListenerTimer; //  监听录音时的音量大小的变化的频率
@property(nonatomic, assign) BOOL isCancelRecord;
@property(nonatomic, assign) BOOL isTimeTooShort;
@property(nonatomic, strong) NSTimer *timer;  //  录音计时器
@property(nonatomic, assign) NSTimeInterval seconds;  //  录音总秒数

@end

@implementation TanVoiceRecordTool

#pragma mark - lazy
-(NSString *)recordAudioSavePath
{
    if (!_recordAudioSavePath) {
        //  获得默认录音名称
        NSString *defaultPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
        formatter.dateFormat = @"YYYY-MM-dd-HH-mm-ss";
        NSString *defaultName = [NSString stringWithFormat:@"%@%@",[formatter stringFromDate:[NSDate date]],AUDIO_PATH_SUFFIX];
        _recordAudioSavePath = [defaultPath stringByAppendingPathComponent:defaultName];
    }
    return _recordAudioSavePath;
}

-(AVAudioRecorder *)recorder
{
    if (!_recorder) {
        [self initRecordSession];
        NSError *error = nil;
        _recorder = [[AVAudioRecorder alloc]initWithURL:[NSURL fileURLWithPath:self.recordAudioSavePath] settings:[self getRecordSetting] error:&error];
        _recorder.delegate = self;
        _recorder.meteringEnabled = YES;  //  如果要监控声波则必须设置为YES
        [_recorder peakPowerForChannel:0];
        if (error) {
            NSLog(@"ERROR!-- MESSAGE-->(%@)",error.localizedDescription);
            return nil;
        }
    }
    return _recorder;
}

-(NSTimer *)recorderSoundLevelListenerTimer
{
    if (!_recorderSoundLevelListenerTimer) {
        //  采样频率为100
        _recorderSoundLevelListenerTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(soundLevelListenerChange) userInfo:nil repeats:YES];
    }
    return _recorderSoundLevelListenerTimer;
}

-(NSTimeInterval)maxRecorderTime
{
    if (!_maxRecorderTime) {
        _maxRecorderTime = 20.0;
    }
    return _maxRecorderTime;
}

-(NSTimeInterval)minRecorderTime
{
    if (!_minRecorderTime) {
        _minRecorderTime = 1.0;
    }
    return _minRecorderTime;
}

-(NSTimer *)timer
{
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timeFly) userInfo:nil repeats:YES];
    }
    return _timer;
}

-(int)timeIsUpRemainReconds
{
    if (!_timeIsUpRemainReconds) {
        _timeIsUpRemainReconds = 10;  //  默认倒数10秒
    }
    return _timeIsUpRemainReconds;
}

#pragma mark - life
+(instancetype)shareRecordTool
{
    static YCRecordTool *instance;
    if (!instance) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            instance = [[YCRecordTool alloc]init];
        });
    }
    return instance;
}

#pragma mark - public
/**
 *  准备开始录音
 */
-(void)prepareRecord
{
    if (!self.recorder.isRecording) {
        self.isTimeTooShort = NO;
        [self.recorder record];//  首次使用应用时如果调用record方法会询问用户是否允许使用麦克风
        self.recorderSoundLevelListenerTimer.fireDate = [NSDate distantPast];
        self.timer.fireDate = [NSDate distantPast];
        self.seconds = 0;
        if (self.delegate) {
            [self.delegate recordToolDidBeginRecord:self];
        }
    }
}

/**
 *  结束录音
 */
-(void)endRecord
{
    self.isCancelRecord = NO;
    //  如果录音时长小于最小秒则取消录音
    if (self.seconds < self.minRecorderTime + 1) {
        self.isTimeTooShort = YES;
        [self cancelRecord];
        return;
    }
    if (self.recorder.isRecording) {
        [self.recorder stop];
        self.recorderSoundLevelListenerTimer.fireDate = [NSDate distantFuture];
        self.timer.fireDate = [NSDate distantFuture];
    }
}

/**
 *  取消录音
 */
-(void)cancelRecord
{
    self.isCancelRecord = YES;
    if (self.recorder.isRecording) {
        [self.recorder stop];
        self.recorderSoundLevelListenerTimer.fireDate = [NSDate distantFuture];
        self.timer.fireDate = [NSDate distantFuture];
    }
}

#pragma mark - private
//  配置录音会话
-(void)initRecordSession
{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    //  设置为录音状态
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [session setActive:YES error:nil];
}

//  获取录音设置,都在这里进行设置
-(NSDictionary *)getRecordSetting
{
    NSMutableDictionary *setting = [NSMutableDictionary dictionary];
    
    //  设置录音格式
    [setting setObject:@(kAudioFormatLinearPCM) forKey:AVFormatIDKey];
    //  设置录音采样率,8000是电话采样率，对于一般录音就已经够了
    [setting setObject:@(8000) forKey:AVSampleRateKey];
    //  设置通道，这里采用单声道
    [setting setObject:@(1) forKey:AVNumberOfChannelsKey];
    //  每个采样点位数，分为8,16,24,32
    [setting setObject:@(8) forKey:AVLinearPCMBitDepthKey];
    //  是否使用浮点数采样
    [setting setObject:@(YES) forKey:AVLinearPCMIsFloatKey];
    
    return setting;
}

//  在这里监听录音音量
-(void)soundLevelListenerChange
{
    //  更新测量值
    [self.recorder updateMeters];
    float power = [self.recorder averagePowerForChannel:0];  //  取得第一个通道的音频
    //  音频强度范围为-160到0
    CGFloat progress = (1.0/160.0)*(power + 160);
    if (self.delegate) {
        [self.delegate recordTool:self responseSoundLevel:progress];
    }
}

#pragma mark - delegate
-(void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    if (flag) {
        if (self.isCancelRecord) {
            //  删除掉已经创建好的录音文件
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if ([fileManager fileExistsAtPath:self.recordAudioSavePath]) {
                NSError *error = nil;
                [fileManager removeItemAtPath:self.recordAudioSavePath error:&error];
                if (error) {
                    NSLog(@"ERROR! -- MESSAGE --> (%@)",error.localizedDescription);
                }
            }
            if (self.delegate) {
                [self.delegate recordToolRecordDidCancel:self isRecordTimeTooShort:self.isTimeTooShort];
            }
        }else{
            if (self.delegate) {
                [self.delegate recordToolRecord:self DidCompleteWithPath:[NSURL fileURLWithPath:self.recordAudioSavePath]];
            }
        }
    }
    //  要清空，以便切换输出地址
    self.recorder = nil;
}

#pragma mark - event
-(void)timeFly
{
    self.seconds++;
    if (self.seconds > self.maxRecorderTime + 1) {
        [self endRecord];
    }
    if (self.seconds > self.maxRecorderTime - self.timeIsUpRemainReconds) {
        if (self.delegate) {
            [self.delegate recordTool:self timeIsUpRemainReconds:self.maxRecorderTime + 1 - (int)self.seconds];
        }
    }
}

@end
