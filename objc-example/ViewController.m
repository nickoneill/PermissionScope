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
    self.singlePscope = [PermissionScope new];
    self.multiPscope = [PermissionScope new];
    
    PermissionConfig* configNotifications = [[PermissionConfig alloc] initWithType:PermissionTypeNotifications demands:PermissionDemandsRequired message:@"We use this to send you\r\nspam and love notes" notificationCategories:UIUserNotificationTypeNone];
    
    PermissionConfig* configContacts = [[PermissionConfig alloc] initWithType:PermissionTypeContacts demands:PermissionDemandsRequired message:@"We use this to steal\r\nyour friends" notificationCategories:UIUserNotificationTypeNone];
    
    PermissionConfig* configLocationInUse = [[PermissionConfig alloc] initWithType:PermissionTypeLocationInUse demands:PermissionDemandsRequired message:@"We use this to track\r\nwhere you live" notificationCategories:UIUserNotificationTypeNone];
    
//    PermissionConfig* configBluetooth = [[PermissionConfig alloc] initWithType:PermissionTypeBluetooth demands:PermissionDemandsRequired message:@"We use this to drain your battery" notificationCategories:UIUserNotificationTypeNone];
    
    
    [self.singlePscope addPermission:configNotifications];
    
    [self.multiPscope addPermission:configContacts];
    [self.multiPscope addPermission:configNotifications];
    [self.multiPscope addPermission:configLocationInUse];
    
}

- (IBAction)single {
    [self.singlePscope showWithAuthChange:^(BOOL completed, NSArray *results) {
        NSLog(@"Changed: %@ - %@", @(completed), results);
    } cancelled:^(NSArray *x) {
        NSLog(@"cancelled");
    }];
}

- (IBAction)multiple {
    [self.multiPscope showWithAuthChange:^(BOOL completed, NSArray *results) {
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
