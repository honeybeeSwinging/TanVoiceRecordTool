# TanVoiceRecordTool
## 一个录音的小工具类
## 使用
### 1.得到录音工具类单例:
TanVoiceRecordTool* tool = [TanVoiceRecordTool shareRecordTool];
### 2.准备开始录音:
[tool prepareRecord];
### 3.完成录音或取消录音
[tool endRecord];      [tool cancelRecord];

### 另外，可设置其最小录音时长和最大录音时长，当小于最小录音时长，将自动取消录音，当大于最大录音时长，将自动完成录音。

### 其代理的回调方法：
#### 当开始录音时回调
-(void)recordToolDidBeginRecord:(TanVoiceRecordTool *)recordTool;
#### 完成录音时回调，输出录音文件存储url
-(void)recordToolRecord:(TanVoiceRecordTool *)recordTool DidCompleteWithPath:(NSURL *)url;
#### 取消录音时回调，输出标志位为是否是录音时长太短导致的录音取消
-(void)recordToolRecordDidCancel:(TanVoiceRecordTool *)recordTool isRecordTimeTooShort:(BOOL)flag;
#### 输出录音时录音音量大小，范围为0到1.0
-(void)recordTool:(TanVoiceRecordTool *)recordTool responseSoundLevel:(CGFloat)level;
#### 当录音接近最大录音时长时，进行倒计时的回调
-(void)recordTool:(TanVoiceRecordTool *)recordTool timeIsUpRemainReconds:(int)reconds;
