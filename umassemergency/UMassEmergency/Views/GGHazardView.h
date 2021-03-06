//
//  GGHazardView.h
// UMassEmergenxy
//
//  Created by Görkem Güclü on 11.05.15.
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

#import <Foundation/Foundation.h>
#import "GGHazard.h"
#import "GGHazardAnnotation.h"

@interface GGHazardView : NSObject

@property (nonatomic, strong) GGHazard *hazard;
@property (nonatomic, strong) NSArray *annotations;
@property (nonatomic, strong) NSArray *overlays;
@property (nonatomic, strong) NSArray *subHazardCenterAnnotations;
@property (nonatomic, strong) GGAnnotation *centerAnnotation;

- (instancetype)initWithHazard:(GGHazard *)hazard;

@end
