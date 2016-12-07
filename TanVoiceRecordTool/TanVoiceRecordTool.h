//
//  YCRecordTool.h
//  Truelove
//
//  Created by Tan on 16/2/29.
//  Copyright © 2016年 YCTime. All rights reserved.
//  录音工具

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class YCRecordTool;

#define AUDIO_PATH_SUFFIX @".caf"  //  录音文件后缀名

@protocol YCRecordToolDelegate <NSObject>

-(void)recordToolDidBeginRecord:(YCRecordTool *)recordTool;
-(void)recordToolRecord:(YCRecordTool *)recordTool DidCompleteWithPath:(NSURL *)url;
-(void)recordToolRecordDidCancel:(YCRecordTool *)recordTool isRecordTimeTooShort:(BOOL)flag;
-(void)recordTool:(YCRecordTool *)recordTool responseSoundLevel:(CGFloat)level;
-(void)recordTool:(YCRecordTool *)recordTool timeIsUpRemainReconds:(int)reconds;

@end

@interface YCRecordTool : NSObject

@property(nonatomic, weak) id<YCRecordToolDelegate> delegate;
@property(nonatomic, copy) NSString *recordAudioSavePath; //  录音文件保存地址，默认是在用户沙盒中，以时间戳命名
@property(nonatomic, assign) NSTimeInterval maxRecorderTime;  //  最大录音时长
@property(nonatomic, assign) NSTimeInterval minRecorderTime;  //  最小录音时长
@property(nonatomic, assign) int timeIsUpRemainReconds;  //  倒计时数

/**
 *  获得录音工具单例
 */
+(instancetype)shareRecordTool;

/**
 *  准备开始录音
 */
-(void)prepareRecord;

/**
 *  结束录音
 */
-(void)endRecord;

/**
 *  取消录音
 */
-(void)cancelRecord;

@end
