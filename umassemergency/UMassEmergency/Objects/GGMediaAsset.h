//
//  GGMediaAsset.h
//  UMassEmergency
//
//  Created by Görkem Güclü on 24.08.16.
//  Copyright © 2016 University of Massachusetts.
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

@interface GGMediaAsset : NSObject

@property (nonatomic, strong) NSString *assetID;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, readwrite) BOOL isVideo;
@property (nonatomic, strong) NSData *assetData;

- (instancetype)initWithImage:(UIImage *)image;
- (instancetype)initWithURL:(NSURL *)url;

-(void)loadImageWithCompletion:(void (^)(UIImage *image))completion;

@end
