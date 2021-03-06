//
//  SHScrollView.m
//  SHScrollView
//
//  Created by CSH on 2018/8/15.
//  Copyright © 2018年 CSH. All rights reserved.
//

#import "SHScrollView.h"
#import "UIImageView+WebCache.h"

@interface SHScrollView ()<UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, weak) NSTimer *timer;
//内容视图
@property (nonatomic, weak) UICollectionView *mainView;

@end

@implementation SHScrollView

static NSString *cellId = @"SHScrollView";

#pragma mark - 初始化
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.isHorizontal = YES;
    }
    return self;
}
#pragma mark - 懒加载
- (UICollectionView *)mainView{
    
    if (!_mainView) {
        //UICollectionView的自动布局
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
        //设置滑动方向
        layout.scrollDirection = self.isHorizontal;
        //设置水平间距（内部）
        layout.minimumInteritemSpacing = 0;
        //设置竖直间距（内部）
        layout.minimumLineSpacing = 0;
        //设置外框间距 (外部)
        layout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);
        //设置内容大小
        layout.itemSize = self.frame.size;
        
        //内容
        UICollectionView *mainView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:layout];
        mainView.backgroundColor = [UIColor clearColor];
        mainView.showsHorizontalScrollIndicator = NO;
        mainView.showsVerticalScrollIndicator = NO;
        mainView.dataSource = self;
        mainView.delegate = self;
        mainView.scrollsToTop = NO;
        mainView.bounces = NO;
        mainView.pagingEnabled = YES;
        
        [self addSubview:mainView];
        
        //注册
        [mainView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:cellId];
        
        _mainView = mainView;
    }
    
    return _mainView;
}

#pragma mark - 复制
- (id)sh_copyWithObj:(id)obj{
    
    NSData *tempArchive = [NSKeyedArchiver archivedDataWithRootObject:obj];
    return [NSKeyedUnarchiver unarchiveObjectWithData:tempArchive];
}

#pragma mark - UICollectionViewDelegate
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    
    return 1;
}

- (NSInteger )collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return (self.timeInterval < 0)?self.contentArr.count:3;
}

#pragma mark 实例化UICollectionView
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellId forIndexPath:indexPath];
    
    id obj;
    
    if ((self.timeInterval < 0)) {//界面不循环
        
        obj = self.contentArr[indexPath.row];
        
    }else{//界面循环
        
        switch (indexPath.row) {
            case 0://左边
            {
                if (self.currentIndex == 0) {//第一个
                    obj = self.contentArr.lastObject;
                }else{
                    obj = self.contentArr[self.currentIndex - 1];
                }
            }
                break;
            case 1://中间
            {
                obj = self.contentArr[self.currentIndex];
            }
                break;
            case 2://右边
            {
                if (self.currentIndex == self.contentArr.count - 1) {//最后一个
                    obj = self.contentArr.firstObject;
                }else{
                    obj = self.contentArr[self.currentIndex + 1];
                }
            }
                break;
                
            default:
                break;
        }
    }
    
    //配置数据源
    [self configCell:cell obj:obj];
    
    return cell;
}

#pragma mark 配置数据源
- (void)configCell:(UICollectionViewCell *)cell obj:(id)obj{
    
    //移除所有子视图
    [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    //设置默认视图
    UIImageView *imageView = [[UIImageView alloc]init];
    imageView.frame = self.bounds;
    
    if ([obj isKindOfClass:[NSString class]]) {//字符串
        
        NSString *str = (NSString *)obj;
        
        if ([str hasPrefix:@"http"]) {//网络图片
            
            [imageView sd_setImageWithURL:[NSURL URLWithString:str] placeholderImage:self.placeholderImage];
        }else{
            
            //资源图片
            UIImage *image = [UIImage imageNamed:str];
            
            if (!image) {//本地图片
                
                image = [UIImage imageWithContentsOfFile:str];
            }
            if (!image) {//默认图片
                
                image = self.placeholderImage;
            }
            imageView.image = image;
        }
        
        [cell.contentView addSubview:imageView];
        
    } else if ([obj isKindOfClass:[UIImage class]]) {//图片
        
        UIImage *image = (UIImage *)obj;
        imageView.image = image;
        
        [cell.contentView addSubview:imageView];
        
    } else if ([obj isKindOfClass:[UIViewController class]]) {//控制器
        
        UIViewController *vc = (UIViewController *)obj;
        vc.view.frame = imageView.bounds;
        [cell.contentView addSubview:vc.view];
    }else if ([obj isKindOfClass:[UIView class]]){//视图
        
        UIView *view = (UIView *)[self sh_copyWithObj:obj];
        [cell.contentView addSubview:view];
    }else{//展示默认图片
        
        imageView.image = self.placeholderImage;
        [cell.contentView addSubview:imageView];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    
    if (self.endRollingBlock) {
        self.endRollingBlock(YES, self.currentIndex);
    }
}

#pragma mark UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    //开始滚动
    if (self.startRollingBlock) {
        self.startRollingBlock();
    }
    
    [self timeStop];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    
    [self dealTime];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    CGFloat index;
    if (self.isHorizontal) {
        index = scrollView.contentOffset.x/(scrollView.frame.size.width);
    }else{
        index = scrollView.contentOffset.y/(scrollView.frame.size.height);
    }
    
    if (index == (NSInteger)index) {//滑动了一页
        
        if (self.timeInterval < 0) {//界面不循环
            
            self.currentIndex = (NSInteger)index;
            
        }else{//界面循环
            
            switch ((NSInteger)index) {
                case 0://左
                {
                    if (self.currentIndex <= 0) {//第一页
                        self.currentIndex = self.contentArr.count - 1;
                    }else{
                        self.currentIndex -= 1;
                    }
                }
                    break;
                case 2://右
                {
                    if (self.currentIndex >= self.contentArr.count - 1) {//最后一页
                        self.currentIndex = 0;
                    }else{
                        self.currentIndex += 1;
                    }
                }
                    break;
                default:
                    break;
            }
        }
        
        index = self.currentIndex;
        
    }else{//滑动中
        
        if (self.timeInterval >= 0) {//界面循环
            
            if ((NSInteger)index == 0) {//右滑
                
                if (self.currentIndex == 0) {//第一个
                    
                    index = self.contentArr.count - 1 + index;
                }else{
                    index = self.currentIndex - 1 + index;
                }
                
            }else if ((NSInteger)index == 1){//左滑
                
                index = self.currentIndex - 1 + index;
            }
        }
    }
    
    //滚动中
    if (self.rollingBlock) {
        self.rollingBlock(index);
    }
}

#pragma mark - SET
- (void)setCurrentIndex:(NSInteger)currentIndex{
    
    //超过数组限制，不进行处理
    if (currentIndex >= self.contentArr.count) {
        return;
    }
    
    _currentIndex = currentIndex;
    
    //刷新内容
    [self.mainView reloadData];
    
    if (self.timeInterval < 0) {
        //界面不循环
        [self.mainView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:currentIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
    }else{
        //界面循环
        [self.mainView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
    }
    
    //滚动了一页
    if (self.endRollingBlock) {
        self.endRollingBlock(NO, currentIndex);
    }
}

#pragma mark - 时间操作
#pragma mark 时间处理
- (void)dealTime{
    
    if (self.timeInterval > 0) {//存在间隔时间
        //先处理之前的时间
        [self timeStop];
        
        //创建新的时间
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:self.timeInterval target:self selector:@selector(nextPage) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        self.timer = timer;
    }else{
        //停止
        [self timeStop];
    }
}

#pragma mark 时间停止
- (void)timeStop{
    
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

#pragma mark 下一页
- (void)nextPage{
    
    //数组为空
    if (!self.contentArr.count) {
        return;
    }
    
    //滚动到下一页
    [self.mainView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:2 inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:YES];
}

#pragma mark - 刷新视图
- (void)reloadView{
    
    //数组为空
    if (!self.contentArr.count) {
        return;
    }
    
    //超出数组则重置
    if (!self.currentIndex || self.currentIndex >= self.contentArr.count) {
        self.currentIndex = 0;
    }
    
    //处理时间
    [self dealTime];
}

@end
