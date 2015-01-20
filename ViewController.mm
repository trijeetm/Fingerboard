//
//  ViewController.m
//  Fingerboard
//
//  Created by Trijeet Mukhopadhyay on 1/19/15.
//  Copyright (c) 2015 Trijeet Mukhopadhyay. All rights reserved.
//

#import "ViewController.h"
#import <math.h>
#import "mo-audio.h"
#import "mo-touch.h"
#import "mo-fun.h"

@interface ViewController ()

@end


@interface ViewController ()

@end


// global define
#define SRATE 44100
// global variables
Float32 g_t = 0.0;
Float32 g_f = 0;
Float32 g_micGain = 0;

// the audio callback
void the_callback( Float32 * buffer, UInt32 frameSize, void * userData )
{
    float inputAggregator = 0;
    // loop over frames
    for( UInt32 i = 0; i < frameSize; i++ )
    {
        inputAggregator += fabs(buffer[i*2]) + fabs(buffer[i*2+1]);
        // generate sine wave
        buffer[i*2] = buffer[i*2+1] = ::sin(TWO_PI * g_f * g_t / SRATE);
        // advance time
        g_t += 1.0;
    }
    g_micGain = inputAggregator / frameSize;
    NSLog( @"gain: %f", g_micGain);
}

//float midiToFreq(int midi) {
////    float midiNotes[127];
//    float a4 = 440; // a is 440 hz...
//    float freq = pow(2.0, (midi - 69) / 12.0) * a4;;
////    NSLog( @"midi: %d", midi );
////    NSLog( @"freq: %f", freq);
//    return freq;
//}

int touchToFreq(float x, float y) {
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    int midi;
    int octaveOffset = 4 * 12;
    int notesPerStrip = 12;
    if (x <= screenWidth / 2) {
        midi =  ((y / screenHeight) * notesPerStrip) + octaveOffset;
    }
    else {
        midi = ((y / screenHeight) * notesPerStrip) + octaveOffset + notesPerStrip;
    }
//    NSLog( @"midi: %d", midi );
//    NSLog( @"freq: %f", midiToFreq(midi) );
    return MoFun::midi2freq(midi);
}

// touch callback
void touch_callback( NSSet * touches, UIView * view,
                    std::vector<MoTouchTrack> & tracks,
                    void * data)
{
    // points
    CGPoint pt;
    CGPoint prev;
    
    // number of touches in set
    NSUInteger n = [touches count];
    NSLog( @"total number of touches: %d", (int)n );

    
    // iterate over all touch events
    for( UITouch * touch in touches )
    {
        // get the location (in window)
        pt = [touch locationInView:view];
        prev = [touch previousLocationInView:view];
        
        // check the touch phase
        switch( touch.phase )
        {
            // begin
            case UITouchPhaseBegan:
            {
//                NSLog( @"touch began... %f %f", pt.x, pt.y );
                g_f = touchToFreq(pt.x, pt.y);
                break;
            }
            case UITouchPhaseStationary:
            {
//                NSLog( @"touch stationary... %f %f", pt.x, pt.y );
                break;
            }
            case UITouchPhaseMoved:
            {
//                NSLog( @"touch moved... %f %f", pt.x, pt.y );
                g_f = touchToFreq(pt.x, pt.y);
                break;
            }
                // ended or cancelled
            case UITouchPhaseEnded:
            {
//                g_f = 0;
//                NSLog( @"touch ended... %f %f", pt.x, pt.y );
                break;
            }
            case UITouchPhaseCancelled:
            {
//                g_f = 0;
//                NSLog( @"touch cancelled... %f %f", pt.x, pt.y );
                break;
            }
                // should not get here
            default:
                break;
        }
    }
}

// implementation for view controller
@implementation ViewController

// we'll do audio init here
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSLog( @"initializing MOTouch" );
    
    // set touch callback
    MoTouch::addCallback( touch_callback, NULL );
    
    // log
    NSLog( @"starting real-time audio..." );
    
    // init the audio layer
    bool result = MoAudio::init( SRATE, 1024, 2 );
    if( !result )
    {
        // something went wrong
        NSLog( @"cannot initialize real-time audio!" );
        // bail out
        return;
    }
    
    // start the audio layer, registering a callback method
    result = MoAudio::start( the_callback, NULL );
    if( !result )
    {
        // something went wrong
        NSLog( @"cannot start real-time audio!" );
        // bail out
        return;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
