//
//  DetailViewController.m
//  SDAutoLayoutDemo
//
//  Created by housenkui on 2018/1/23.
//  Copyright © 2018年 gsd. All rights reserved.
//

#import "DetailViewController.h"
#import "ThreeModel.h"


@interface DetailViewController ()

@property (nonatomic,strong)UITextView *textView;

@property (nonatomic,strong)UILabel *lable;


@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"DetailViewController";
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.textView];
    self.textView.text = self.model.article;
    self.title = self.model.title;

    
    
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(UITextView *)textView {
    
    if (!_textView) {
        _textView = [[UITextView alloc]initWithFrame:self.view.bounds];
        _textView.editable = NO;
        _textView.font = [UIFont systemFontOfSize:17];
    }
    return _textView;
}
-(UILabel *)lable{
    
    if (_lable) {
        _lable = [[UILabel alloc]init];
    }
    return _lable;
}
@end
