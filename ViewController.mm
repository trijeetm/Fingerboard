//
//  ViewController.m
//  Fingerboard
//
//  Created by Trijeet Mukhopadhyay on 1/19/15.
//  Copyright (c) 2015 Trijeet Mukhopadhyay. All rights reserved.
//

#undef PI
#undef TWO_PI

// stk includes
#import "Clarinet.h"

#import <vector>

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

int lowestNote = 4 * 12;
float micCutoff = 0.2;
float gainBoost = 0;
stk::Clarinet *instrument;

std::vector <int> scale;

// the audio callback
void the_callback( Float32 * buffer, UInt32 frameSize, void * userData )
{
    // input monitor
    float inputAggregator = 0;
    
    float gain = g_micGain / 75.0;
    
    // instrument params
    if ((gain > micCutoff) && (g_f != 0)) {
        
        float _gain = gainBoost + gain - micCutoff;
//        NSLog( @"gain: %f", _gain);
        
        if (_gain < 2)
            instrument->noteOn(g_f, _gain);
        else
            instrument->noteOn(g_f, 2);
        
    }
//        instrument->noteOn(g_f, 0.5);
    else
        instrument->noteOff(0.5);
    
    // loop over frames
    for( UInt32 i = 0; i < frameSize; i++ )
    {
        // instrument params
//        instrument->noteOn(g_f, (g_micGain / 50));
        
        // mic monitor
        inputAggregator += fabs(buffer[i*2]) + fabs(buffer[i*2+1]);
        
        // synthesize
        buffer[i*2] = buffer[i*2+1] = instrument->tick();
        
        // advance time
        g_t += 1.0;
    }
    g_micGain = inputAggregator + (0.5 * g_micGain);
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
    x = screenWidth - x;
    y = screenHeight - y;
    int midi;
    int octaveOffset = 4 * 12 + scale[0];
    int notesPerStrip = (int)scale.size();
    int offsetPosition = y / (screenHeight / notesPerStrip);
    midi = octaveOffset + scale[offsetPosition];
    NSLog(@"midi: %d", midi);
//    if (x <= screenWidth / 2) {
//        midi =  ((y / screenHeight) * notesPerStrip) + octaveOffset;
//    }
//    else {
//        midi = ((y / screenHeight) * notesPerStrip) + octaveOffset + notesPerStrip;
//    }
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
//    NSLog( @"total number of touches: %d", (int)n );

    
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
//                instrument->noteOn(touchToFreq(pt.x, pt.y), g_micGain / 100);
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
//                instrument->noteOn(touchToFreq(pt.x, pt.y), g_micGain / 100);
                break;
            }
                // ended or cancelled
            case UITouchPhaseEnded:
            {
                g_f = 0;
//                NSLog( @"touch ended... %f %f", pt.x, pt.y );
                break;
            }
            case UITouchPhaseCancelled:
            {
                g_f = 0;
//                instrument->noteOff(0.5);
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
    
    // init instrument
    instrument = new stk::Clarinet(MoFun::midi2freq(lowestNote));
    instrument->setFrequency(0);
    
    // init scale
    scale.push_back(0);
    scale.push_back(2);
    scale.push_back(4);
    scale.push_back(5);
    scale.push_back(7);
    scale.push_back(9);
    scale.push_back(11);
    
    
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
