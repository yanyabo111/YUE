//
//  ViewController.m
//  YUI
//
//  Created by 晏亚博 on 15/10/12.
//  Copyright © 2015年 晏亚博. All rights reserved.
//

#import "ViewController.h"
#import "MBProgressHUD.h"
#import "GPXParser.h"
#import "BlocksKit.h"

@interface ViewController ()

@property (nonatomic) GPX *gpx;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSString *filepath = [[NSBundle mainBundle] pathForResource:@"demo" ofType:@"gpx"];
        NSError *error;
        NSData *fileData = [NSData dataWithContentsOfFile:filepath
                                                  options:NSDataReadingMappedIfSafe
                                                    error:&error];
        
        if (error)
            NSLog(@"Error reading file: %@", error.localizedDescription);
        
        [GPXParser parse:fileData completion:^(BOOL success, GPX *gpx) {
            dispatch_async(dispatch_get_main_queue(), ^{
                // 绘制路线
                [_mapView addOverlays:[gpx.tracks bk_map:^id(Track *track) {
                    return track.path;
                }]];
                
                // gpx 文件内未标明起止点，手动设置
                Track *track = (Track *)[gpx.tracks firstObject];
                [_mapView addAnnotations:@[[self annotationWithFix:(Fix *)[track.fixes firstObject] title:@"始"],
                                           [self annotationWithFix:(Fix *)[track.fixes lastObject] title:@"终"]]];
                
                // 随意的选定了一个缩放范围
                MKCoordinateSpan span = {
                    gpx.region.span.latitudeDelta + 2,
                    gpx.region.span.longitudeDelta + 2
                };
                
                gpx.region = MKCoordinateRegionMake(
                    gpx.region.center,
                    span
                );

                [_mapView setRegion:gpx.region];
                
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            });
        }];
    });
}

#pragma mark MapView Delegate
- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];

    renderer.strokeColor = [UIColor redColor];
    renderer.lineWidth = 4.0;

    return  renderer;
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKAnnotationView *annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation
                                                                    reuseIdentifier:@"annotation"];

    annotationView.annotation = annotation;
    annotationView.image = [self imageFromText:annotation.title width:25 height:25];
    annotationView.backgroundColor = [UIColor clearColor];
    
    annotationView.canShowCallout = YES;
    annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    
    return annotationView;
}

#pragma mark 帮助函数
// 随便画的地图标记
-(UIImage *)imageFromText:(NSString *)text width:(float)width height:(float)height
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, 0.0);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetRGBFillColor(ctx, 1, 1 , 1 , 1);
    CGContextFillEllipseInRect(ctx , CGRectMake(0, 0, width, height));
    
    if ([text isEqualToString:@"始"]) {
        CGContextSetRGBFillColor(ctx, 1, 0 , 0 , 1);
    } else {
        CGContextSetRGBFillColor(ctx, 0, 0 , 1 , 1);
    }
    CGContextFillEllipseInRect(ctx , CGRectMake(2, 2, width - 4, height - 4));
    
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    paragraphStyle.lineSpacing = 5;
    
    [text drawInRect:CGRectMake(0, 5, width, height)
      withAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12.0],
                       NSForegroundColorAttributeName: [UIColor whiteColor],
                       NSParagraphStyleAttributeName: paragraphStyle}];

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();
    
    return image;
}

// 奇葩的库，需要手动生成 MKPointAnnotation
- (MKPointAnnotation *)annotationWithFix:(Fix *)fix title:(NSString *)title
{
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(fix.latitude, fix.longitude);
    
    MKPointAnnotation *annotation = [MKPointAnnotation new];
    
    annotation.coordinate = coordinate;
    annotation.title      = title;
    
    return annotation;
}

@end
