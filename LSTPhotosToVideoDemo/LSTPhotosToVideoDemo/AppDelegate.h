//
//  AppDelegate.h
//  LSTPhotosToVideoDemo
//
//  Created by 刘士天 on 2017/12/26.
//  Copyright © 2017年 刘士天. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

