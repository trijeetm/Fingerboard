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
#import "ADSR.h"
#import "JCRev.h"

// stdlib
#import <vector>

// custom
#import "ViewController.h"
#import <math.h>
#import "mo-audio.h"
#import "mo-touch.h"
#import "mo-fun.h"

// global define
#define SRATE 44100
// global variables
Float32 g_t = 0.0;
Float32 g_f = 0;
Float32 g_micGain = 0;

int lowestNote = 4 * 12;
float micCutoff = 0.0001;
float gainBoost = 0;

stk::Clarinet *instrument;
stk::ADSR *adsr;
float g_attack = 0.1;
float g_release = 0.5;
float g_vibratoRate = 40;
float g_vibratoGain = 0;
stk::JCRev *rev;
float g_revDecay = 1;

// leaky integrator
float g_factor = 0.9995;
float g_input = 0;
float g_lastInput = 0;
float g_output = 0;
float g_lastOutput = 0;

bool g_isBlowing = false;

std::vector <int> scale;

@interface ViewController ()

@end


@interface ViewController ()

@end


// the audio callback
void the_callback( Float32 * buffer, UInt32 frameSize, void * userData )
{
//    if (g_f != 0)
//        adsr->keyOn();
//    else
//        adsr->keyOff();
    
//    if( !g_isBlowing )
//    {
//        instrument->startBlowing(0, 0.5);
//        g_isBlowing = true;
//    }
    
//    if( g_f > .1 ) instrument->setFrequency( g_f );

    instrument->setFrequency( g_f );
    if (g_output > micCutoff)
        instrument->startBlowing(1, 1);
    else
        instrument->stopBlowing(0.25);
    
    instrument->controlChange(1, g_vibratoGain);
    instrument->controlChange(11, g_vibratoRate);
    
//    NSLog( @"output: %f", g_output );
    // loop over frames
    for( UInt32 i = 0; i < frameSize; i++ )
    {
        // instrument params
//        instrument->noteOn(g_f, (g_micGain / 50));
        
        // mic monitor
        g_lastOutput = g_output;
        g_input = buffer[i*2] * buffer[i*2]; // + fabs(buffer[i*2+1]);
        g_output = g_input * sqrt((1 - g_factor)) + (g_factor * g_lastOutput);
//        NSLog(@"gain: %f", g_input);

        
        // input monitor
//        float inputAggregator = 0;
        
        float gain = g_output;
        
//        // instrument params
//        if ((gain > micCutoff) && (g_f != 0) && !g_isBlowing) {
////            float _gain = gainBoost + gain - micCutoff;
////                    NSLog( @"gain: %f", _gain);
//            
////            instrument->setFrequency(g_f);
//            instrument->startBlowing( 1, .1 );
//            //instrument->startBlowing(_gain, 0.1);
////            instrument->noteOn(g_f, 1);
//            g_isBlowing = true;
//        }
//        else {
//            instrument->stopBlowing(0.9);
//            g_isBlowing = false;
////            instrument->noteOff(0);
//        }
        
        // synthesize
        buffer[i*2] = buffer[i*2+1] = rev->tick(instrument->tick() * g_output);
//        buffer[i*2] = buffer[i*2+1] = instrument->tick() * adsr->tick();
//        buffer[i*2] = buffer[i*2+1] = instrument->tick();
        
        // advance time
        g_t += 1.0;
    }
//    g_micGain = inputAggregator + (0.75 * g_micGain);
}

//float midiToFreq(int midi) {
////    float midiNotes[127];
//    float a4 = 440; // a is 440 hz...
//    float freq = pow(2.0, (midi - 69) / 12.0) * a4;;
////    NSLog( @"midi: %d", midi );
////    NSLog( @"freq: %f", freq);
//    return freq;
//}

int touchToFreq(float x, float y, bool vibrato = false) {
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    x = screenWidth - x;
    y = screenHeight - y;
    
    // compute midi
    int midi;
    int octaveOffset = lowestNote;
    int notesPerStrip = (int)scale.size();
    float stripWidth = screenHeight / notesPerStrip;
    int offsetPosition = y / stripWidth;
    midi = octaveOffset + scale[offsetPosition] + ((int)(x / (screenWidth / 2)) * 12);
    NSLog(@"midi: %d", midi);
    
    // compute vibrato
    float scaleWidth = (screenWidth / 2);
    float xOffset = fmodf(x, scaleWidth);
    float vibratoAmt = xOffset / scaleWidth;
    g_vibratoGain = 100.0 * vibratoAmt + 28.0;
    g_vibratoRate = 100.0 * vibratoAmt;
//    instrument->controlChange(2, 128.0 * vibratoAmt);
//    instrument->controlChange(4, 128.0 * vibratoAmt);
    NSLog(@"vibrato: %f", vibratoAmt);
//    if (vibrato) {
//        float fingerOffset = fmodf(y, stripWidth) - (stripWidth / 2);
////        NSLog(@"vibrato: %f", fingerOffset);
//        return MoFun::midi2freq(midi) + (MoFun::midi2freq(g_vibratoRange) * (fingerOffset / (stripWidth / 2)) * g_vibratoSensitivity);
//    }
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
                g_f = touchToFreq(pt.x, pt.y, true);
//                instrument->noteOn(touchToFreq(pt.x, pt.y), g_micGain / 100);
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
    
    adsr = new stk::ADSR();
    adsr->setReleaseTime(g_release);
    adsr->setAttackTime(g_attack);
    
    rev = new stk::JCRev(g_revDecay);
    
    // init scale
//    scale.push_back(0);
////    scale.push_back(1);
//    scale.push_back(2);
////    scale.push_back(3);
//    scale.push_back(4);
//    scale.push_back(5);
////    scale.push_back(6);
//    scale.push_back(7);
////    scale.push_back(8);
//    scale.push_back(9);         // A
////    scale.push_back(10);
//    scale.push_back(11);
//    scale.push_back(12);

    scale.push_back(2);
    scale.push_back(4);
    scale.push_back(6);
    scale.push_back(7);
    scale.push_back(9);
    scale.push_back(11);
    scale.push_back(13);
    scale.push_back(14);

    
    
    bool result = MoAudio::init( SRATE, 384, 2 );
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
    
    // add drawing code
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
