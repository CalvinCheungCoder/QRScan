//
//  ScanViewController.m
//  Scan
//
//  Created by 张丁豪 on 16/9/14.
//  Copyright © 2016年 张丁豪. All rights reserved.
//

#import "ScanViewController.h"
#import <AVFoundation/AVFoundation.h>

#define kBorderW 100
#define kMargin 30

#define Width [UIScreen mainScreen].bounds.size.width
#define Height [UIScreen mainScreen].bounds.size.height

@interface ScanViewController ()<AVCaptureMetadataOutputObjectsDelegate,UIAlertViewDelegate>{
    
    UILabel * tipLabel;
    // 闪光灯
    UIButton * flashBtn;
}

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) UIView *maskView;
@property (nonatomic, strong) UIView *scanWindow;
@property (nonatomic, strong) UIImageView *scanNetImageView;

@end

@implementation ScanViewController

-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    [self resumeAnimation];
}

-(void)viewWillDisappear:(BOOL)animated{
    
    [self turnTorchOn:NO];
    [super viewWillDisappear:animated];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor grayColor];
    
    // 这个属性必须打开否则返回的时候会出现黑边
    self.view.clipsToBounds = YES;
    
    // 1.设置遮罩
    [self setupMaskView];
    // 2.设置导航
    [self setupNavView];
    // 3.扫描区域
    [self setupScanWindowView];
    // 4.开始扫描
    [self beginScanning];
    
    [self resumeAnimation];
}

#pragma mark -
#pragma mark - 设置遮罩
- (void)setupMaskView{
    
    // 遮罩
    _maskView = [[UIView alloc] init];
    _maskView.layer.borderColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7].CGColor;
    _maskView.layer.borderWidth = kBorderW;
    _maskView.bounds = CGRectMake(0, 0, Width + kBorderW + kMargin, Width + kBorderW + kMargin);
    _maskView.center = self.view.center;
    [self.view addSubview:_maskView];
    
    // 补充遮罩
    UIView *mask = [[UIView alloc]initWithFrame:CGRectMake(0, _maskView.frame.origin.y + _maskView.frame.size.height, Width, kBorderW + 100)];
    mask.backgroundColor=[UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
    [self.view addSubview:mask];
    
    UIView *mask2 = [[UIView alloc]initWithFrame:CGRectMake(0, 0, Width, kBorderW - 19)];
    mask2.backgroundColor=[UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
    [self.view addSubview:mask2];
    
    // 操作提示
    tipLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, Height - kBorderW*2, self.view.bounds.size.width, kBorderW)];
    tipLabel.text = @"将取景框对准二维码，即可自动扫描";
    tipLabel.textColor = [UIColor colorWithRed:252 green:206 blue:74 alpha:1];
    tipLabel.textAlignment = NSTextAlignmentCenter;
    tipLabel.lineBreakMode = NSLineBreakByWordWrapping;
    tipLabel.numberOfLines = 2;
    tipLabel.font=[UIFont systemFontOfSize:14];
    tipLabel.backgroundColor = [UIColor clearColor];
    [self.view addSubview:tipLabel];
}

#pragma mark -
#pragma mark - 导航
-(void)setupNavView{
    
    // 返回
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.frame = CGRectMake(20, 30, 20, 20);
    [backBtn setBackgroundImage:[UIImage imageNamed:@"qrcode_scan_titlebar_back_nor"] forState:UIControlStateNormal];
    backBtn.contentMode=UIViewContentModeScaleAspectFit;
    [backBtn addTarget:self action:@selector(disMiss) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backBtn];
    
    // 闪光灯
    flashBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    flashBtn.frame = CGRectMake(0,0, 60, 78);
    flashBtn.center = CGPointMake(Width/2, Height - 100);
    [flashBtn setBackgroundImage:[UIImage imageNamed:@"qrcode_scan_btn_flash_down"] forState:UIControlStateNormal];
    [flashBtn setBackgroundImage:[UIImage imageNamed:@"qrcode_scan_btn_scan_off"] forState:UIControlStateSelected];
    flashBtn.contentMode = UIViewContentModeScaleAspectFit;
    [flashBtn addTarget:self action:@selector(openFlash:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:flashBtn];
}

#pragma mark --
#pragma mark -- 闪光灯
-(void)openFlash:(UIButton*)button{
    
    button.selected = !button.selected;
    if (button.selected) {
        [self turnTorchOn:YES];
    }
    else{
        [self turnTorchOn:NO];
    }
    
}

- (void)turnTorchOn:(BOOL)on{
    
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        if ([device hasTorch] && [device hasFlash]){
            
            [device lockForConfiguration:nil];
            if (on) {
                [device setTorchMode:AVCaptureTorchModeOn];
                [device setFlashMode:AVCaptureFlashModeOn];
                
            } else {
                [device setTorchMode:AVCaptureTorchModeOff];
                [device setFlashMode:AVCaptureFlashModeOff];
            }
            [device unlockForConfiguration];
        }
    }
}


#pragma mark -
#pragma mark - 扫描区域
- (void)setupScanWindowView
{
    CGFloat scanWindowH = Width - kMargin * 2;
    CGFloat scanWindowW = Width - kMargin * 2;
    _scanWindow = [[UIView alloc] initWithFrame:CGRectMake(0,0, scanWindowW, scanWindowH)];
    _scanWindow.center = self.view.center;
    _scanWindow.clipsToBounds = YES;
    [self.view addSubview:_scanWindow];
    
    _scanNetImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"scan_net"]];
    _scanNetImageView.frame = _scanWindow.frame;
    _scanNetImageView.center = self.view.center;
    CGFloat buttonWH = 18;
    [_scanWindow addSubview:_scanNetImageView];
    
    UIButton *topLeft = [[UIButton alloc] initWithFrame:CGRectMake(1, 0, buttonWH, buttonWH)];
    [topLeft setImage:[UIImage imageNamed:@"scan_1"] forState:UIControlStateNormal];
    [_scanWindow addSubview:topLeft];
    
    UIButton *topRight = [[UIButton alloc] initWithFrame:CGRectMake(scanWindowW - buttonWH - 1, 0, buttonWH, buttonWH)];
    [topRight setImage:[UIImage imageNamed:@"scan_2"] forState:UIControlStateNormal];
    [_scanWindow addSubview:topRight];
    
    UIButton *bottomLeft = [[UIButton alloc] initWithFrame:CGRectMake(1, scanWindowH - buttonWH, buttonWH, buttonWH)];
    [bottomLeft setImage:[UIImage imageNamed:@"scan_3"] forState:UIControlStateNormal];
    [_scanWindow addSubview:bottomLeft];
    
    UIButton *bottomRight = [[UIButton alloc] initWithFrame:CGRectMake(topRight.frame.origin.x, bottomLeft.frame.origin.y, buttonWH, buttonWH)];
    [bottomRight setImage:[UIImage imageNamed:@"scan_4"] forState:UIControlStateNormal];
    [_scanWindow addSubview:bottomRight];
}

#pragma mark -
#pragma mark - 开始扫描
- (void)beginScanning{
    
    // 获取摄像设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    // 创建输入流
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    if (!input) return;
    // 创建输出流
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc]init];
    // 设置代理 在主线程里刷新
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    // 设置有效扫描区域
    CGRect scanCrop = [self getScanCrop:_scanWindow.bounds readerViewBounds:self.view.frame];
    output.rectOfInterest = scanCrop;
    // 初始化链接对象
    _session = [[AVCaptureSession alloc]init];
    // 高质量采集率
    [_session setSessionPreset:AVCaptureSessionPresetHigh];
    
    [_session addInput:input];
    [_session addOutput:output];
    // 设置扫码支持的编码格式(如下设置条形码和二维码兼容)
    output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code];
    
    AVCaptureVideoPreviewLayer *layer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    layer.frame = self.view.layer.bounds;
    [self.view.layer insertSublayer:layer atIndex:0];
    // 开始捕获
    [_session startRunning];
}

#pragma mark --
#pragma mark -- 获取扫描区域的比例关系
-(CGRect)getScanCrop:(CGRect)rect readerViewBounds:(CGRect)readerViewBounds
{
    CGFloat x,y,width,height;
    x = (CGRectGetHeight(readerViewBounds)-CGRectGetHeight(rect))/2/CGRectGetHeight(readerViewBounds);
    y = (CGRectGetWidth(readerViewBounds)-CGRectGetWidth(rect))/2/CGRectGetWidth(readerViewBounds);
    width = CGRectGetHeight(rect)/CGRectGetHeight(readerViewBounds);
    height = CGRectGetWidth(rect)/CGRectGetWidth(readerViewBounds);
    
    return CGRectMake(x, y, width, height);
}

#pragma mark -- 动画
- (void)resumeAnimation{
    
    CAAnimation *anim = [_scanNetImageView.layer animationForKey:@"translationAnimation"];
    if(anim){
        // 1.将动画的时间偏移量作为暂停时的时间点
        CFTimeInterval pauseTime = _scanNetImageView.layer.timeOffset;
        // 2.根据媒体时间计算出准确的启动动画时间，对之前暂停动画的时间进行修正
        CFTimeInterval beginTime = CACurrentMediaTime() - pauseTime;
        
        // 3.要把偏移时间清零
        [_scanNetImageView.layer setTimeOffset:0.0];
        // 4.设置图层的开始动画时间
        [_scanNetImageView.layer setBeginTime:beginTime];
        
        [_scanNetImageView.layer setSpeed:1.0];
        
    }else{
        
        CGFloat scanNetImageViewH = 241;
        CGFloat scanWindowH = self.view.frame.size.width - kMargin * 2;
        CGFloat scanNetImageViewW = _scanWindow.frame.size.width;
        
        _scanNetImageView.frame = CGRectMake(0, -scanNetImageViewH, scanNetImageViewW, scanNetImageViewH);
        CABasicAnimation *scanNetAnimation = [CABasicAnimation animation];
        scanNetAnimation.keyPath = @"transform.translation.y";
        scanNetAnimation.byValue = @(scanWindowH);
        scanNetAnimation.duration = 1.0;
        scanNetAnimation.repeatCount = MAXFLOAT;
        [_scanNetImageView.layer addAnimation:scanNetAnimation forKey:@"translationAnimation"];
        [_scanWindow addSubview:_scanNetImageView];
    }
}

#pragma mark --
#pragma mark -- 返回
- (void)disMiss{
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark --
#pragma mark -- 获取二维码
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    
    if (metadataObjects.count > 0) {
        
        [_session stopRunning];
        AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects objectAtIndex : 0 ];
        
        // 二维码信息
        NSString *str = metadataObject.stringValue;
        
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"二维码信息：" message:str delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        [alert show];
        
    }
}

#pragma mark --
#pragma mark -- UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if (buttonIndex == 0) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else if (buttonIndex == 1) {
        [_session startRunning];
    }
}

@end
