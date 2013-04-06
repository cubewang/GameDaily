//
//  ZTextField.h
//  TestForInput
//
//  Created by curer on 11-10-16.
//  Copyright 2011 Dreaming Team. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HPGrowingTextView.h"

@interface ZTextField : UIView <HPGrowingTextViewDelegate>{
}

- (void)setView:(UIView *)aParentView;

@property (nonatomic, retain) HPGrowingTextView *textView;
@property (nonatomic, retain) UIView *parentView;
@property (nonatomic, retain) UIView *brotherView;
@property (nonatomic, retain) UIButton *doneBtn;

@property (nonatomic, retain) UIImage *textImage;
@property (nonatomic, retain) UIImageView *entryImageView;

@property (nonatomic, assign) id delegate;

@property (nonatomic, assign) CGRect keyboardRect;

@end

@protocol ZTextFieldDelegate <NSObject>

- (void)ZTextFieldButtonDidClicked:(ZTextField *)sender;
- (void)ZTextFieldKeyboardPopup:(ZTextField *)sender;
- (void)ZTextFieldKeyboardDrop:(ZTextField *)sender;
- (void)ZTextFieldSoundRecordButtonClicked;
- (void)ZTextFieldSoundRecordButtonTouchup;

@end
