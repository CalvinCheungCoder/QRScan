//
//  RootViewController.m
//  Scan
//
//  Created by 张丁豪 on 16/9/14.
//  Copyright © 2016年 张丁豪. All rights reserved.
//

#import "RootViewController.h"
#import "ScanViewController.h"

@interface RootViewController ()

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"Scan";
    
    UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(50, 200, [UIScreen mainScreen].bounds.size.width - 100, 50)];
    [btn setTitle:@"Scan" forState:UIControlStateNormal];
    btn.backgroundColor = [UIColor grayColor];
    btn.layer.cornerRadius = 3;
    btn.layer.masksToBounds = YES;
    [btn addTarget:self action:@selector(btnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

-(void)btnClicked{
    
    ScanViewController *scan = [[ScanViewController alloc]init];
    [self presentViewController:scan animated:YES completion:nil];
}


@end
