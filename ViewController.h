//
//  ViewController.h
//  Fingerboard
//
//  Created by Trijeet Mukhopadhyay on 1/19/15.
//  Copyright (c) 2015 Trijeet Mukhopadhyay. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (strong, nonatomic) IBOutlet UISlider *portamentoSlider;
@property (strong, nonatomic) IBOutlet UILabel *portamentoLabel;
@property (strong, nonatomic) IBOutlet UILabel *octaveStepperLabel;
@property (strong, nonatomic) IBOutlet UIButton *octaveDownButton;
@property (strong, nonatomic) IBOutlet UIButton *octaveUpButton;
@property (strong, nonatomic) IBOutlet UILabel *reverbLabel;
@property (strong, nonatomic) IBOutlet UISlider *reverbSlider;
@property (strong, nonatomic) IBOutlet UISwitch *scaleModeSwitch;
@property (strong, nonatomic) IBOutlet UILabel *minorLabel;
@property (strong, nonatomic) IBOutlet UILabel *majorLabel;
@property (strong, nonatomic) IBOutlet UIButton *scaleRootUpButton;
@property (strong, nonatomic) IBOutlet UIButton *scaleRootDownButton;
@property (strong, nonatomic) IBOutlet UILabel *scaleRootLabel;


@end

