//
//  ViewController.m
//  EVLaunchProtectionDemo
//
//  Created by Ever on 2019/4/9.
//  Copyright © 2019 Ever. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *tipLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (IBAction)shallowCanRepair:(UIButton *)sender {
    [[NSUserDefaults standardUserDefaults] setObject:@(1) forKey:@"appVersion"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    self.tipLabel.text = [NSString stringWithFormat:@"%@\n已%@",self.tipLabel.text,[sender titleForState:UIControlStateNormal]];
}

- (IBAction)deepCanRepair:(UIButton *)sender {
    [[NSUserDefaults standardUserDefaults] setObject:@(1) forKey:@"cacheVersion"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    self.tipLabel.text = [NSString stringWithFormat:@"%@\n已%@",self.tipLabel.text,[sender titleForState:UIControlStateNormal]];
}

- (IBAction)hotfixCanRepair:(UIButton *)sender {
    [[NSUserDefaults standardUserDefaults] setObject:@(1) forKey:@"uuid"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    self.tipLabel.text = [NSString stringWithFormat:@"%@\n已%@",self.tipLabel.text,[sender titleForState:UIControlStateNormal]];
}

@end
