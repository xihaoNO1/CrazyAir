//
//  ViewController.m
//  CrazyAir
//
//  Created by xixixi on 15/9/7.
//  Copyright (c) 2015年 xihao. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import "ViewController.h"
#import "FKBlast.h"

@interface ViewController ()

@end
#define BACK_HEIGHT 860
@implementation ViewController
{
    NSTimer *timer;
    CALayer *bgLayer1;
    CALayer *bgLayer2;
    CALayer *myPlane;
    CATextLayer *scoreLayer;
    NSMutableArray *ePlaneArray;
    NSMutableArray *bulletArray;
    NSMutableArray *blastArray;
    AVAudioPlayer *bgMusicPlayer;
    SystemSoundID blastSound;
    NSInteger count;
    NSMutableArray *blastImageArray;
    UIImage *planeImage0;
    UIImage *planeImage1;
    UIImage *ePlaneImage0;
    UIImage *ePlaneImage1;
    UIImage *ePlaneImage2;
    UIImage *bulletImage;
    UIImage *bgImage;
    NSInteger score;
    //定义获取屏幕的宽度，高度的变量
    NSInteger screenWidth, screenHeight;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //获取屏幕宽度和高度
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    screenHeight = screenBounds.size.height;
    screenWidth = screenBounds.size.width;
    blastImageArray = [[NSMutableArray alloc] initWithObjects:
                       [UIImage imageNamed:@"blast0"],
                       [UIImage imageNamed:@"blast1"],
                       [UIImage imageNamed:@"blast2"],
                       [UIImage imageNamed:@"blast3"],
                       [UIImage imageNamed:@"blast4"],
                       [UIImage imageNamed:@"blast5"],nil];
    //初始化显示自己的飞机动画所需的两张图片
    planeImage0 = [UIImage imageNamed:@"plane0"];
    planeImage1 = [UIImage imageNamed:@"plane1"];
    //初始化3种敌机的图片
    ePlaneImage0 = [UIImage imageNamed:@"e0"];
    ePlaneImage1 = [UIImage imageNamed:@"e1"];
    ePlaneImage2 = [UIImage imageNamed:@"e2"];
    //初始化子弹图片
    bulletImage = [UIImage imageNamed:@"bullet"];
    //初始化背景图片
    bgImage = [UIImage imageNamed: @"bg.jpg"];
    //获取背景音乐的URL
    NSURL *bgURL = [[NSBundle mainBundle] URLForResource:@"s3" withExtension:@"wav"];
    //创建AVAudioPlayer对象
    bgMusicPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:bgURL
                                                           error:nil];
    bgMusicPlayer.numberOfLoops = -1;
    //播放背景音乐
    [bgMusicPlayer play];
    //获取要播放的音乐文件的URL
    NSURL *blasetURL = [[NSBundle mainBundle] URLForResource:@"b0" withExtension:@"mp3"];
    //加载音效
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)blasetURL,
                                     &blastSound);
    //初始化容纳所有敌机，子弹，爆炸效果的集合
    ePlaneArray = [[NSMutableArray alloc] init];
    bulletArray = [[NSMutableArray alloc] init];
    blastArray = [[NSMutableArray alloc] init];
    //创建代表背景的CAPlayer
    bgLayer1 = [CALayer layer];
    //设置该bgLayer1.contents显示的图片
    bgLayer1.contents = (id)[bgImage CGImage];
    bgLayer1.frame = CGRectMake(0, screenHeight - BACK_HEIGHT, screenWidth, BACK_HEIGHT);
    [self.view.layer addSublayer:bgLayer1];
    //创建代表背景的CAlayer
    bgLayer2 =[CALayer layer];
    bgLayer2.contents = (id)[bgImage CGImage];
    bgLayer2.frame = CGRectMake(0, screenHeight - BACK_HEIGHT * 2, screenWidth, BACK_HEIGHT);
    [self.view.layer addSublayer:bgLayer2];
    //创建代表自己飞机的calayer对象
    myPlane = [CALayer layer];
    myPlane.frame = CGRectMake((screenWidth - 56) / 2, screenHeight - 80, 56, 61);
    [self.view.layer addSublayer:myPlane ];
    //创建显示积分的calayer对象
    scoreLayer = [CATextLayer layer];
    scoreLayer.frame = CGRectMake(10, 10, 120, 30);
    scoreLayer.fontSize = 16;
    //使用NSUserDefaults读取系统已经保存的积分
    NSNumber *scoreNumber ;
    if ((scoreNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"score"])) {
        score = scoreNumber.integerValue;
    }
    scoreLayer.string = [NSString stringWithFormat:@"累计积分：%ld",score];
    [self.view.layer addSublayer:scoreLayer];
    //启动定时器
    timer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                             target:self
                                           selector:@selector(move)
                                           userInfo:nil repeats:YES];
}

- (void)move
{
    //控制飞机的图片交替显示,实现动画效果
    myPlane.contents = (id)((count % 2 == 0) ? [planeImage0 CGImage] : [planeImage1 CGImage]);
    //控制背景向下移动
    bgLayer1.frame = CGRectOffset(bgLayer1.frame, 0, 5);
    bgLayer2.frame = CGRectOffset(bgLayer2.frame, 0, 5);
    //如果bgLayer1已经到了最下面，将其移到最上面
    if(bgLayer1.position.y == BACK_HEIGHT / 2 + screenHeight + 20)
    {
        [bgLayer1 removeFromSuperlayer];
        bgLayer1.position = CGPointMake(screenWidth / 2, screenHeight - BACK_HEIGHT * 3 / 2 +20);
        [self.view.layer insertSublayer:bgLayer1 below:bgLayer2 ];
    }
    //如果bgLayer2已经到了最下面，将其移动到最上面
    if (bgLayer2.position.y == BACK_HEIGHT / 2 + screenHeight + 20) {
        [bgLayer2 removeFromSuperlayer];
        bgLayer2.position = CGPointMake(screenWidth / 2, screenHeight - BACK_HEIGHT * 3 / 2 + 20);
        [self.view.layer insertSublayer:bgLayer2  below:bgLayer1];
    }
    //遍历所有爆炸效果
    for (int i = 0 ; i < blastArray.count; i ++) {
        FKBlast *blast = [blastArray objectAtIndex:i];
        //控制爆炸效果CALayer显示下一张图片，从而显示爆炸动画
        blast.imageIndex = (blast.imageIndex + 1) % blastImageArray.count;
        blast.layer.contents = (id)[[blastImageArray objectAtIndex:blast.imageIndex] CGImage];
    }
    //便利所有子弹
    for (int i = 0 ; i < bulletArray.count; i ++) {
        CALayer *bullet = [bulletArray objectAtIndex:i];
        //控制所有子弹向上移动
        bullet.frame = CGRectOffset(bullet.frame, 0, -15);
        //如果子弹已经移到屏幕外
        if (bullet.position.y < - 10) {
            //删除该子弹
            [bullet removeFromSuperlayer];
            //从bulletArray集合中删除子弹CALayer
            [bulletArray removeObject:bullet];
        }
     }
    //遍历所有敌机
    for (int i = 0; i < ePlaneArray.count; i++) {
        CALayer *eplane = [ePlaneArray objectAtIndex:i];
        //控制所有敌机向下移动
        eplane.frame = CGRectOffset(eplane.frame, 0, 15);
        //如果敌机移到屏幕外,删除敌机
        if (eplane.position.y > screenHeight + 50) {
            //删除该敌机
            [eplane removeFromSuperlayer];
            //从ePlane集合中删除敌机CALayer
            [ePlaneArray removeObject:eplane];
        }
    }
    //遍历所有子弹
    for (int i = 0 ; i < bulletArray.count; i++) {
        //处理第i颗子弹
        CALayer *bullet = [bulletArray objectAtIndex:i];
        CGPoint bulletPos = [bullet position];
        //遍历所有的敌机
        for (int j = 0; j < ePlaneArray.count; j++) {
            CALayer *eplane = [ePlaneArray objectAtIndex:j];
            CGPoint ePlanePos = [eplane position];
            //如果敌机与子弹发生碰撞
            if (CGRectContainsPoint(eplane.frame, bulletPos)) {
                //创建CALayer来显示爆炸效果
                CALayer *blastLayer = [CALayer layer];
                //设置显示爆炸效果的CALayer的大小和效果
                blastLayer.frame = CGRectMake(ePlanePos.x - 40, ePlanePos.y - 20, 78, 72);
                //设置爆炸效果显示一张图片
                blastLayer.contents = (id)[[blastImageArray objectAtIndex:0] CGImage];
                [self.view.layer addSublayer:blastLayer];
                //以显示爆炸效果的CALayer,正在显示的图片索引创建FKBlast对象
                FKBlast *blast = [[FKBlast alloc] initWithLayer:blastLayer imageIndex:0];
                [blastArray addObject:blast];
                //播放爆炸音效
                AudioServicesPlaySystemSound(blastSound);
                //控制0.6秒之后删除该爆炸效果
                [self performSelector:@selector(removeBlast:) withObject:blast afterDelay:0.6];
                //删除这颗子弹
                [bulletArray removeObject:bullet];
                [bullet removeFromSuperlayer];
                //删除这架敌机
                [ePlaneArray removeObject:eplane];
                [eplane removeFromSuperlayer];
                //积分加10
                score += 10;
                //显示最新积分
                scoreLayer.string = [NSString stringWithFormat:@"累计积分:%ld",score];
                //跳出循环,判断下一颗子弹
                break;
            }
        }
    }
    count++;
    //控制count为5的倍数时发射一颗子弹
    if (count % 5 == 0) {
        //创建代表子弹的的CALayer
        CALayer *bulletLayer = [CALayer layer];
        bulletLayer.frame = CGRectMake(myPlane.position.x - 12, myPlane.position.y - 50, 25, 25);
        //设置子弹的图片
        bulletLayer.contents = (id)[bulletImage CGImage];
        [self.view.layer addSublayer:bulletLayer];
        [bulletArray addObject:bulletLayer];
    }
    //控制count为10的倍数时添加一架敌机
    if (count % 10 == 0) {
        //创建代表敌机的CALayer
        CALayer *ePlayer = [CALayer layer];
        //根据rand随机数添加不同的敌机
        int rand = arc4random() % 3;
        //使用随机数来设置敌机的坐标
        int randx = arc4random() % (screenWidth - 40) + 20;
        switch (rand) {
            case 0:
                //设置第一种敌机所用的图片
                ePlayer.contents = (id)[ePlaneImage0 CGImage];
                ePlayer.frame = CGRectMake(randx, -80, 65, 75);
                break;
            case 1:
                //设置第一种敌机所用的图片
                ePlayer.contents = (id)[ePlaneImage1 CGImage];
                ePlayer.frame = CGRectMake(randx, -80, 88, 75);
                break;
                
            case 2:
                //设置第一种敌机所用的图片
                ePlayer.contents = (id)[ePlaneImage2 CGImage];
                ePlayer.frame = CGRectMake(randx, -80, 66, 75);
                break;
        }
        [self.view.layer addSublayer:ePlayer];
        [ePlaneArray addObject:ePlayer];
    }
    
}

//重写该方法,控制手指移动时,飞机跟着移动
- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    //获取触碰点的坐标
    UITouch *touch = [touches anyObject];
    CGPoint touchPt = [touch locationInView:self.view];
    //将飞机的x坐标移动到手指的x坐标
    myPlane.position = CGPointMake(touchPt.x, myPlane.position.y);
}

//控制删除爆炸动画CALayer的方法
- (void)removeBlast:(FKBlast *)blast
{
    [blastArray removeObject:blast.layer];
    [blast.layer removeFromSuperlayer];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
