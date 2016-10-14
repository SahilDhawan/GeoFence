//
//  ViewController.m
//  geofence01
//
//  Created by Sahil Dhawan on 15/06/16.
//  Copyright © 2016 Sahil Dhawan. All rights reserved.
//

#import "ViewController.h"
#import <MapKit/MapKit.h>

@interface ViewController ()<CLLocationManagerDelegate,MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *checkStatus;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *eventLabel;
@property (weak, nonatomic) IBOutlet UISwitch *switchStatus;
@property (strong,nonatomic)CLLocationManager *locationManager;
@property (nonatomic,assign)BOOL mapIsMoving;
@property (strong,nonatomic)MKPointAnnotation *current;
@property (strong,nonatomic)CLCircularRegion *geoRegion;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.switchStatus.enabled = NO;
    self.checkStatus.enabled = NO;
    self.locationManager = [[CLLocationManager alloc]init];
    self.locationManager.delegate = self;
    self.locationManager.allowsBackgroundLocationUpdates = YES;
    self.locationManager.pausesLocationUpdatesAutomatically = YES;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter = 3;
    // self.locationManager.activityType = CLActivityTypeAutomotiveNavigation;

    
    self.mapIsMoving = NO;
    
    
    [self addAnnoation];
    [self setUpGeoRegion];
    self.statusLabel.text = @"";
    self.eventLabel.text = @"";

    //zoom the map;
    
    CLLocationCoordinate2D dummyCoordinate;
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(dummyCoordinate, 500, 500);
    MKCoordinateRegion adjustRegion = [self.mapView regionThatFits:region];
    [self.mapView setRegion:adjustRegion animated:YES];
    
    
    
    //check if the device can do geofence
    if([CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]])
    {
        CLAuthorizationStatus currentStatus = [CLLocationManager authorizationStatus];
        if((currentStatus == kCLAuthorizationStatusAuthorizedWhenInUse)||(currentStatus == kCLAuthorizationStatusAuthorizedAlways))
        {
            self.switchStatus.enabled = YES;
        }
        else
        {
            [self.locationManager requestAlwaysAuthorization];
        }
        UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeAlert | UIUserNotificationTypeSound;
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        [[UIApplication sharedApplication]registerUserNotificationSettings:settings];
    }
    else
    {
        self.statusLabel.text = @"Geofencing is not possible";
    }
}
//Longitude: 77.229512 Latitude: 28.612951
//<wpt lat="37.310806" lon="-122.053353">
//<wpt lat="37.310396" lon="-122.053009">

-(void)setUpGeoRegion
{
    self.geoRegion = [[CLCircularRegion alloc]
                      initWithCenter:CLLocationCoordinate2DMake(37.310396,-122.053009)
                      radius:5
                      identifier:@"MyRegionIdentifier"];
    
}
-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    CLAuthorizationStatus currentStatus = [CLLocationManager authorizationStatus];
    if((currentStatus == kCLAuthorizationStatusAuthorizedWhenInUse)||(currentStatus == kCLAuthorizationStatusAuthorizedAlways))
    {
        self.switchStatus.enabled = YES;
    }

}

-(void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    self.mapIsMoving = YES;
}
-(void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    self.mapIsMoving = NO;
}

- (IBAction)switchTapped:(id)sender {
    if(self.switchStatus.isOn)
    {
        self.mapView.showsUserLocation = YES;
        [self.locationManager startUpdatingLocation];
        [self.locationManager startMonitoringForRegion:self.geoRegion];
        self.checkStatus.enabled = YES;
    }
    else
    {
        self.mapView.showsUserLocation = NO;
        [self.locationManager stopUpdatingLocation];
        self.checkStatus.enabled = NO;
        [self.locationManager stopMonitoringForRegion:self.geoRegion];

    }
}
-(void)addAnnoation{
    self.current = [[MKPointAnnotation alloc]init];
    self.current.coordinate = CLLocationCoordinate2DMake(0.0,0.0);
    self.current.title = @"Current Location";
    //[self.mapView addAnnotation:self.current];
}
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    self.current.coordinate = locations.lastObject.coordinate;
    if(self.mapIsMoving == NO)
    {
        [self.mapView setCenterCoordinate:self.current.coordinate animated:YES];
    }
}
- (IBAction)statusCheckTapped:(id)sender {
    [self.locationManager requestStateForRegion:self.geoRegion];
}

-(void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    UILocalNotification *notif = [[UILocalNotification alloc]init];
    notif.fireDate = nil;
    notif.repeatInterval = 0;
    notif.alertTitle = @"GeoRegion Alert";
    notif.alertBody = [NSString stringWithFormat:@"Entered the region"];
    [[UIApplication sharedApplication]scheduleLocalNotification:notif];
    self.eventLabel.text = @"Entered";
}
-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    UILocalNotification *notif = [[UILocalNotification alloc]init];
    notif.fireDate = nil;
    notif.repeatInterval = 0;
    notif.alertTitle = @"GeoRegion Alert";
    notif.alertBody = [NSString stringWithFormat:@"Exited the region"];
    [[UIApplication sharedApplication]scheduleLocalNotification:notif];
    self.eventLabel.text = @"Exited";
}
-(void)locationManager:(CLLocationManager *)manager
     didDetermineState:(CLRegionState)state
             forRegion:(CLRegion *)region
{
    if(state == CLRegionStateUnknown)
    {
        self.statusLabel.text = @"Unknown";
    }
    else if (state == CLRegionStateInside)
    {
        self.statusLabel.text = @"Inside";
    }
    else if (state == CLRegionStateOutside)
    {
        self.statusLabel.text = @"Outside";
    }
    else
    {
        self.statusLabel.text = @"Mystery";
    }
}

@end
