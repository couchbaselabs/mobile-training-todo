//
//  CBLTaskImageViewController.m
//  Todo
//
//  Created by Pasin Suriyentrakorn on 1/27/17.
//  Copyright © 2017 Pasin Suriyentrakorn. All rights reserved.
//

#import "CBLTaskImageViewController.h"
#import "AppDelegate.h"
#import "CBLUi.h"
#import "CBLImage.h"

@interface CBLTaskImageViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    __weak IBOutlet UIImageView *imageView;
    CBLDatabase *_database;
}

@end

@implementation CBLTaskImageViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
    _database = app.database;
    
    [self reload];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Database

- (void)reload {
    CBLDocument* task = [_database documentWithID:self.taskID];
    CBLBlob *imageBlob = [task blobForKey:@"image"];
    if (imageBlob)
        imageView.image = [UIImage imageWithData:imageBlob.content scale:[UIScreen mainScreen].scale];
    else
        imageView.image = nil;
}

- (void)updateImage:(UIImage *)image {
    NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
    if (!imageData) {
        [CBLUi showErrorOn:self message:@"Invalid image format" error:nil];
        return;
    }
    
    CBLMutableDocument *task = [[_database documentWithID:self.taskID] toMutable];
    CBLBlob *imageBlob = [[CBLBlob alloc] initWithContentType:@"image/jpg" data:imageData];
    [task setValue:imageBlob forKey:@"image"];
    
    NSError *error;
    if ([_database saveDocument:task error:&error]) {
        [self reload];
    } else
        [CBLUi showErrorOn:self message:@"Couldn't update image" error:error];
}

- (void)deleteImage {
    CBLMutableDocument *task = [[_database documentWithID:self.taskID] toMutable];
    [task setValue:nil forKey:@"image"];
    
    NSError *error;
    if ([_database saveDocument: task error: &error]) {
        [self reload];
    } else
        [CBLUi showErrorOn:self message:@"Couldn't delete image" error:error];
}

#pragma mark - Actions

- (IBAction)editAction:(id)sender {
    [CBLUi showImageActionSheet:self imagePickerDelegate:self onDelete:^{
        [self deleteImage];
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

- (IBAction)closeAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{ }];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [self updateImage: info[@"UIImagePickerControllerOriginalImage"]];
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
