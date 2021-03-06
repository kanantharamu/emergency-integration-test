//
//  AppDelegate.h
// UMassEmergenxy
//
//  Created by Görkem Güclü on 01.03.15.
//  Copyright (c) 2015 University of Massachusetts.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you
//  may not use this file except in compliance with the License. You
//  may obtain a copy of the License at
//  
//  http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
//  implied. See the License for the specific language governing
//  permissions and limitations under the License.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"
#import "GGApp.h"
#import "GGNotificationView.h"
#import <AudioToolbox/AudioToolbox.h>
#import <Google/Analytics.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, GGNotificationViewDelegate>

@property (strong, nonatomic) UIWindow *window;

-(void)createNotificationView:(GGNotification *)notification;
-(void)showNextNotification;

-(void)updateDeveloperStatus;

@end
