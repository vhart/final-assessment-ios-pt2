//
//  HUGameViewController.m
//  HeadsUpper
//
//  Created by Varindra Hart on 2/21/16.
//  Copyright © 2016 Michael Kavouras. All rights reserved.
//

#import "HUGameViewController.h"
#import "HUInstructionsView.h"
#import "HUData.h"
#import "UIColor+FadeColor.h"
#import <CoreMotion/CoreMotion.h>

@interface HUGameViewController ()<HUInstructionsProtocol>

@property (weak, nonatomic) IBOutlet UILabel *questionLabel;
@property (weak, nonatomic) IBOutlet UILabel *timerLabel;

@property (nonatomic) BOOL inAnswerState;
@property (nonatomic) HUInstructionsView *instructionView;
@property (nonatomic) NSArray *questionsArray;
@property (nonatomic) NSTimer *gameTimer;
@property (nonatomic) NSInteger currentIndex;
@property (nonatomic) NSMutableDictionary *correctQuestion;
@property (nonatomic) NSInteger timerLoopCount;
@property (nonatomic) CMMotionManager *motionManager;

@end

@implementation HUGameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.questionsArray = [[HUData sharedData] dataForCategory:self.category];
    self.currentIndex = 0;
    self.correctQuestion = [NSMutableDictionary new];
    self.timerLoopCount = 30;
    [self shuffle];
    [self trackAccelerometer];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (!self.gameTimer) {
        [self setupInstructionView];
    }

}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.instructionView = nil;
    if (self.gameTimer) {
        [self formatTimer];
    }
}
#pragma mark - In Game Methods

- (void)startGame {
    [self displayQuestionForIndex:self.currentIndex];
    [self formatTimer];
}

- (void)displayQuestionForIndex:(NSInteger)index {
    self.questionLabel.text = self.questionsArray[index];
}

- (void)nextQuestion {
    self.currentIndex++;
    [self displayQuestionForIndex:self.currentIndex];
}

- (void)skipQuestion{
    [self animateToColorFade:OrangeColor];
}

- (void)correctlyAnswered{
    self.correctQuestion[@(self.currentIndex)] = @(self.currentIndex);
    [self animateToColorFade:GreenColor];

}

- (void)formatTimer{
    if (!self.gameTimer) {
        self.gameTimer = [NSTimer timerWithTimeInterval:1.0f target:self selector:@selector(updateTimerLabel) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop]addTimer:self.gameTimer forMode:NSRunLoopCommonModes];
    } else{
        [self.gameTimer invalidate];
        self.gameTimer = nil;
    }
}

- (void)updateTimerLabel {
    self.timerLoopCount--;
    self.timerLabel.text = [NSString stringWithFormat:@"%ld",self.timerLoopCount];

    if (self.timerLoopCount == 0) {
        [self formatTimer];
    }
}

#pragma mark - Fade Animation

- (void)animateToColorFade:(ColorFade)fade {

    __weak typeof(self) weakSelf = self;

    [UIView animateWithDuration:.35 animations:^{
        weakSelf.view.backgroundColor = [UIColor colorForFadeType:fade];
    } completion:^(BOOL finished) {

        [UIView animateWithDuration:.35 animations:^{
            weakSelf.view.backgroundColor = [UIColor whiteColor];
        }
            completion:^(BOOL finished) {
                [weakSelf nextQuestion];

        }];
    }];
}

- (void)shuffle {

    NSMutableArray *shuffled = [NSMutableArray arrayWithArray:self.questionsArray];

    for (int i = 0; i < shuffled.count; i++) {
        int j = arc4random_uniform((int)shuffled.count);
        NSString *temp = shuffled[j];
        [shuffled replaceObjectAtIndex:j withObject:shuffled[i]];
        [shuffled replaceObjectAtIndex:i withObject:temp];
    }

    self.questionsArray = (NSArray *)shuffled;
}

#pragma mark - Instruction View Setup/Delegate

- (void)didTapStartButton{

    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:.2 animations:^{
    
        weakSelf.instructionView.frame = CGRectMake(weakSelf.view.center.x,weakSelf.view.center.y,0,0);
    }completion:^(BOOL finished) {
        [weakSelf.instructionView removeFromSuperview];
        weakSelf.instructionView = nil;
        [weakSelf startGame];
    }];

}

- (void)setupInstructionView {
    self.instructionView = [[[NSBundle mainBundle] loadNibNamed:@"HUInstructionsView" owner:self options:nil] firstObject];
    self.instructionView.frame = CGRectMake(0, 74, self.view.bounds.size.width-70, self.view.bounds.size.height - 150);
    self.instructionView.center = self.view.center;
    self.instructionView.layer.cornerRadius = 20;

    [self.view addSubview:self.instructionView];

    self.instructionView.delegate = self;
}

- (void)trackAccelerometer {
    self.motionManager = [[CMMotionManager alloc]init];
    self.motionManager.accelerometerUpdateInterval = 1.0f/20.0f;

    [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
            withHandler:^(CMAccelerometerData  *accelerometerData, NSError *error) {
                    [self handleAccelerometer:accelerometerData.acceleration];
                        if(error){
                            NSLog(@"No Data for accel");
                        }
        }];
}

- (void)handleAccelerometer:(CMAcceleration)acceleration {
    if (self.gameTimer) {
        if (!self.inAnswerState) {
            if (acceleration.z > 0.75f) {
                self.inAnswerState = YES;
                [self correctlyAnswered];
            }
            else if(acceleration.z < -0.75f){
                self.inAnswerState = YES;
                [self skipQuestion];
            }
        }
        else{
            if (acceleration.z < .2f && acceleration.z > -.2f) {
                self.inAnswerState = NO;
            }
        }
    }
}
@end