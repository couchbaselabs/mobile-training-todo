//
// CBLTaskImageViewController.m
//
// Copyright (c) 2023 Couchbase, Inc All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "CBLTaskImageViewController.h"
#import "CBLDB.h"
#import "CBLUi.h"
#import "CBLImage.h"

@interface CBLTaskImageViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    __weak IBOutlet UIImageView *imageView;
    UIImage* _image;
}

@end

@implementation CBLTaskImageViewController

#pragma mark - UIViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    [self reload];
}

#pragma mark - Database

- (void) reload {
    if (_image) {
        imageView.image = nil;
    } else if (_imageBlob) {
        imageView.image = [UIImage imageWithData: _imageBlob.content scale: [UIScreen mainScreen].scale];
    } else {
        imageView.image = nil;
    }
}

- (void) updateImage: (UIImage*)image {
    NSError* error;
    if (![CBLDB.shared updateTaskWithID: _taskID image: image error: &error]) {
        [CBLUi showErrorOn: self message: @"Couldn't update image" error: error];
        return;
    }
    
    _image = image;
    _imageBlob = nil;
    [self reload];
}

- (void) deleteImage {
    NSError* error;
    if (![CBLDB.shared updateTaskWithID: _taskID image: nil error: &error]) {
        [CBLUi showErrorOn: self message: @"Couldn't update image" error: error];
        return;
    }
    
    _image = nil;
    _imageBlob = nil;
    [self reload];
}

#pragma mark - Actions

- (IBAction) editAction: (id)sender {
    [CBLUi showImageActionSheet: self imagePickerDelegate: self onDelete: ^{
        [self deleteImage];
        [self dismissViewControllerAnimated: YES completion: nil];
    }];
}

- (IBAction) closeAction:(id)sender {
    [self dismissViewControllerAnimated: YES completion: ^{ }];
}

#pragma mark - UIImagePickerControllerDelegate

- (void) imagePickerController: (UIImagePickerController*)picker didFinishPickingMediaWithInfo: (NSDictionary<NSString*,id>*)info {
    [self updateImage: info[@"UIImagePickerControllerOriginalImage"]];
    [picker.presentingViewController dismissViewControllerAnimated: YES completion: nil];
}

@end
