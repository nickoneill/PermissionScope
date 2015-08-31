//
//  ViewController.m
//  objc-example
//
//  Created by Nick O'Neill on 6/26/15.
//  Copyright (c) 2015 That Thing in Swift. All rights reserved.
//

#import "ViewController.h"
#import <PermissionScope/PermissionScope-Swift.h>

@interface ObjCViewController ()
@property (nonatomic, strong) PermissionScope *singlePscope;
@property (nonatomic, strong) PermissionScope *multiPscope;
@end

@implementation ObjCViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.singlePscope = [[PermissionScope alloc]init];
    self.multiPscope = [[PermissionScope alloc]init];
    
    [self.singlePscope addPermission:[[NotificationsPermission alloc]initWithNotificationCategories:nil] message:@"We use this to send you\r\nspam and love notes"];
    
    [self.multiPscope addPermission:[[ContactsPermission alloc]init] message:@"We use this to steal\r\nyour friends"];
    [self.multiPscope addPermission:[[NotificationsPermission alloc]initWithNotificationCategories:nil] message:@"We use this to send you\r\nspam and love notes"];
    [self.multiPscope addPermission:[[LocationWhileInUsePermission alloc]init] message:@"We use this to track\r\nwhere you live"];
//    [self.multiPscope addPermission:[[BluetoothPermission alloc]init] message:@"We use this to drain your battery"];
//    [self.multiPscope addPermission:[[MotionPermission alloc]init] message:@"We use this to detect if you are\r\nThe Flash"];
}

- (IBAction)single {
    [self.singlePscope show:^(BOOL completed, NSArray *results) {
        NSLog(@"Changed: %@ - %@", @(completed), results);
    } cancelled:^(NSArray *x) {
        NSLog(@"cancelled");
    }];
}

- (IBAction)multiple {
    [self.multiPscope show:^(BOOL completed, NSArray *results) {
        NSLog(@"Changed: %@ - %@", @(completed), results);
    } cancelled:^(NSArray *x) {
        NSLog(@"cancelled");
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
