//
//  DIDrawView.m
//  PNFPenTest
//
//  Created by PNF on 5/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DIDrawView.h"
#import "PNFPenLib.h"

@interface DIDrawView ()
{
    UIColor* penColor;
    UILabel* hoveringFocus;
    NSTimer* hoveringTimer;
}
@property (retain) UIColor* penColor;
@property (readwrite, retain) UILabel* hoveringFocus;
@end

@implementation DIDrawView
@synthesize penColor;
@synthesize hoveringFocus;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.penColor = [UIColor blackColor];
        [self InitCanvas];
    }
    return self;
}
-(void) awakeFromNib {
    [super awakeFromNib];
    [self InitCanvas];
}
-(void) dealloc {
    [self releaseHoverHideTimer];
    [self.hoveringFocus removeFromSuperview];
    self.hoveringFocus = nil;
    self.penColor = nil;
    if (m_LyrMain) CGLayerRelease(m_LyrMain);
    if (m_CtxMain) CGContextRelease(m_CtxMain);
    [super dealloc];
}
-(void) changeDrawingSize {
    [self clear];
    if (m_LyrMain) CGLayerRelease(m_LyrMain);
    if (m_CtxMain) CGContextRelease(m_CtxMain);
    m_LyrMain = nil;
    m_CtxMain = nil;
    [self InitCanvas];
}

-(void) InitCanvas
{
    hoveringTimer = nil;
    self.hoveringFocus = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 6, 6)] autorelease];
    self.hoveringFocus.backgroundColor = [UIColor colorWithRed:0/255.0 green:0 blue:0 alpha:1.0];
    self.hoveringFocus.layer.cornerRadius = 4.0f;
    self.hoveringFocus.clipsToBounds = YES;
    [self addSubview:self.hoveringFocus];
    self.hoveringFocus.hidden = YES;
    
    [self CreateBitmap];
}

-(void) clear
{
    CGRect frame = scaleRect(self.bounds);
    CGContextClearRect(m_CtxLyr, frame);
    [self setNeedsDisplay];
}

-(void) CreateBitmap
{
    CGRect frame = scaleRect(self.bounds);
    if (m_CtxMain) {
        CGContextRelease(m_CtxMain);
    }
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    m_CtxMain = CGBitmapContextCreate(nil,
                                      frame.size.width,
                                      frame.size.height,
                                      8,
                                      4*frame.size.width,
                                      colorspace,
                                      kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big);
    m_LyrMain = CGLayerCreateWithContext(m_CtxMain, frame.size, nil);
    m_CtxLyr = CGLayerGetContext(m_LyrMain);
    CGColorSpaceRelease(colorspace);
    CGContextSetLineDash(m_CtxLyr, 0, nil, 0);
    CGContextSetAllowsAntialiasing(m_CtxLyr, YES);
    CGContextSetShouldAntialias(m_CtxLyr, YES);
    CGContextSetRGBStrokeColor(m_CtxLyr, 0.0,0,0,1.0);
    CGContextSetLineWidth(m_CtxLyr, 2.0);
    CGContextSetLineJoin(m_CtxLyr, kCGLineJoinRound);
    CGContextSetLineCap(m_CtxLyr, kCGLineCapRound);
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextDrawLayerInRect(ctx, [self bounds], m_LyrMain);
}

-(void) DoPenProcess:(int) penTip pressure:(int)pressure X:(float) x Y:(float) y color:(UIColor*)color erase:(BOOL)erase eraseSize:(float)eraseSize
{
    if (isnan(x) || isnan(y))
        return;
    
    switch (penTip) {
        case PEN_DOWN: {
            self.hoveringFocus.hidden = YES;
            m_ptNew=CGPointMake(x, y);    
            m_ptOld = m_ptNew;
            if (erase) {
                CGContextSetRGBStrokeColor(m_CtxLyr, 1,1,1,1);
                CGContextSetLineWidth(m_CtxLyr, eraseSize);
            }
            else {
                if (color) {
                    CGFloat r, g, b, a;
                    [color getRed:&r green:&g blue:&b alpha:&a];
                    CGContextSetRGBStrokeColor(m_CtxLyr, r, g, b, 1.0);
                }
                else {
                    CGContextSetRGBStrokeColor(m_CtxLyr, 0.0,0,0,1.0);
                }
                CGContextSetLineWidth(m_CtxLyr, 2.0);
            }
            break;
        }
        case PEN_MOVE: {
            self.hoveringFocus.hidden = YES;
            m_ptNew=CGPointMake(x, y);
            CGContextBeginPath(m_CtxLyr);
            CGContextMoveToPoint(m_CtxLyr, m_ptOld.x, m_ptOld.y);
            CGContextAddLineToPoint(m_CtxLyr, m_ptNew.x, m_ptNew.y);
            CGContextClosePath(m_CtxLyr);
            CGContextStrokePath(m_CtxLyr);
            m_ptOld = m_ptNew;        
            [self setNeedsDisplay];
            break;
        }
        case PEN_UP: {
            self.hoveringFocus.hidden = YES;
            m_ptNew=CGPointMake(x, y);    
            CGContextBeginPath(m_CtxLyr);
            CGContextMoveToPoint(m_CtxLyr, m_ptOld.x, m_ptOld.y);
            CGContextAddLineToPoint(m_CtxLyr, m_ptNew.x, m_ptNew.y);
            CGContextClosePath(m_CtxLyr);
            CGContextStrokePath(m_CtxLyr);
            m_ptOld = m_ptNew;        
            [self setNeedsDisplay];
            break;
        }
        case PEN_HOVER: {
            self.hoveringFocus.hidden = NO;
            self.hoveringFocus.center = scaleDownPoint(CGPointMake(x, y));
            [self initHoverHideTimer];
            break;
        }
        default:
            break;
    }
}
-(void) releaseHoverHideTimer {
    if(hoveringTimer != nil){
        [hoveringTimer invalidate];
        [hoveringTimer release];
        hoveringTimer = nil;
    }
}
-(void) initHoverHideTimer {
    [self releaseHoverHideTimer];
    if (hoveringTimer == nil) {
        hoveringTimer = [[NSTimer scheduledTimerWithTimeInterval:0.5f
                                                          target:self
                                                        selector:@selector(onTimer:)
                                                        userInfo:nil
                                                         repeats:NO] retain];
    }
}
- (void) onTimer:(NSTimer *)timer {
    self.hoveringFocus.hidden = YES;
}
@end
