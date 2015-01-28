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
#import <string>

// custom
#import "ViewController.h"
#import <math.h>
#import "mo-audio.h"
#import "mo-touch.h"
#import "mo-fun.h"
#import "mo-gfx.h"

#import "Globals.h"

// global define
#define SRATE 44100
// global variables
Float32 g_t = 0.0;
Float32 g_micGain = 0;

int g_octave = 4;
int g_highestOctave = 6;
int g_lowestOctave = 1;
int lowestNote = g_octave * 12;
float micCutoff = 0.0001;
float gainBoost = 0;

float g_freqSlewRate = 0.5;
Vector3D g_freqSlewer = Vector3D(MoFun::midi2freq(lowestNote), MoFun::midi2freq(lowestNote), g_freqSlewRate);

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

// scale
std::vector<int> majorScale = {0, 2, 4, 5, 7, 9, 11, 12};
std::vector<int> minorScale = {0, 2, 3, 5, 7, 8, 10, 12};
bool g_scaleIsMajor = true;
int g_scaleRoot = 2;
std::vector<std::string> scaleRoots = {
    "C",
    "C#",
    "D",
    "D#",
    "E",
    "F",
    "F#",
    "G",
    "G#",
    "A",
    "A#",
    "B"
};

bool g_isBlowing = false;


@interface ViewController ()

@end


// the audio callback
void the_callback( Float32 * buffer, UInt32 frameSize, void * userData )
{
    g_freqSlewer.slew = g_freqSlewRate;
    g_freqSlewer.interp();
//    NSLog(@"freq: %f", g_freqSlewer.value);
    
    rev->setT60(g_revDecay);
    
    instrument->setFrequency( g_freqSlewer.value );
    if (g_output > micCutoff)
        instrument->startBlowing(1, 1);      // amplitude, rate
    else
        instrument->stopBlowing(0.25);
    
    instrument->controlChange(1, g_vibratoGain);
    instrument->controlChange(11, g_vibratoRate);
    
//    NSLog( @"output: %f", g_output );
    
    // loop over frames
    for( UInt32 i = 0; i < frameSize; i++ )
    {
        // mic monitor
        g_lastOutput = g_output;
        g_input = buffer[i*2] * buffer[i*2]; // + fabs(buffer[i*2+1]);
        g_output = g_input * sqrt((1 - g_factor)) + (g_factor * g_lastOutput);
        
        // synthesize
        buffer[i*2] = buffer[i*2+1] = rev->tick(instrument->tick() * g_output);
        
        // advance time
        g_t += 1.0;
    }
}

void touchToFreq(float x, float y, bool vibrato = false) {
//    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = Globals::fingerboardWidth;
    CGFloat screenHeight = Globals::fingerboardHeight;
    
    // touch outside fingerboard area
    if (x >= screenWidth)
        return;
    
    // compute midi
    int midi;
    int octaveOffset = g_octave * 12;
    int notesPerStrip = (int)Globals::scale.size();
    float stripWidth = screenHeight / notesPerStrip;
    int offsetPosition = y / stripWidth;
    midi = octaveOffset + Globals::scale[offsetPosition] + ((int)(x / (screenWidth / 2)) * 12);
    Globals::currentNote.octave = (int)(x / (screenWidth / 2));
    Globals::currentNote.key = offsetPosition;
//    NSLog(@"midi: %d", midi);
    
    // compute vibrato
    float scaleWidth = (screenWidth / 2);
    float xOffset = fmodf(x, scaleWidth);
    float vibratoAmt = xOffset / scaleWidth;
    g_vibratoGain = 90.0 * vibratoAmt + 38.0;
    g_vibratoRate = 75.0 * vibratoAmt;

    g_freqSlewer.goal = MoFun::midi2freq(midi);
    return;
//    return MoFun::midi2freq(midi);
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
//    NSUInteger n = [touches count];
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
                touchToFreq(pt.x, pt.y);
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
                touchToFreq(pt.x, pt.y, true);
                break;
            }
                // ended or cancelled
            case UITouchPhaseEnded:
            {
//                NSLog( @"touch ended... %f %f", pt.x, pt.y );
                break;
            }
            case UITouchPhaseCancelled:
            {
//                NSLog( @"touch cancelled... %f %f", pt.x, pt.y );
                break;
            }
                // should not get here
            default:
                break;
        }
        break;
    }
}

// implementation for view controller
@implementation ViewController

// we'll do audio init here
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // rotate UI elements
    CGAffineTransform trans = CGAffineTransformMakeRotation(M_PI * -0.5);
    _portamentoSlider.transform = trans;
    
    trans = CGAffineTransformMakeRotation(M_PI * 0.5);
    _portamentoLabel.transform = trans;
    
    _octaveStepperLabel.transform = trans;

    _reverbLabel.transform = trans;
    _reverbSlider.transform = trans;
    
    _scaleModeSwitch.transform = trans;
    _majorLabel.transform = trans;
    _minorLabel.transform = trans;
    
    _scaleRootLabel.transform = trans;
    
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
    
    // init scale (to D major)
    for (int i = 0; i < majorScale.size(); i++)
        Globals::scale.push_back(g_scaleRoot + majorScale[i]);
    
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

- (IBAction)portamentoSliderChanged:(id)sender {
    g_freqSlewRate = self.portamentoSlider.value;
}

- (IBAction)octaveUp:(id)sender {
    if (g_octave < g_highestOctave)
        g_octave++;
}

- (IBAction)octaveDown:(id)sender {
    if (g_octave > g_lowestOctave)
        g_octave--;
}

- (IBAction)reverbSliderChanged:(id)sender {
    g_revDecay = self.reverbSlider.value;
}

- (IBAction)scaleModeChanged:(id)sender {
    Globals::scale.clear();
    if (self.scaleModeSwitch.isOn) {
        g_scaleIsMajor = true;
        for (int i = 0; i < majorScale.size(); i++)
            Globals::scale.push_back(g_scaleRoot + majorScale[i]);
    }
    else {
        g_scaleIsMajor = false;
        for (int i = 0; i < minorScale.size(); i++)
            Globals::scale.push_back(g_scaleRoot + minorScale[i]);
    }
}

- (IBAction)scaleRootUp:(id)sender {
    g_scaleRoot = (g_scaleRoot + 1) % scaleRoots.size();
    
    self.scaleRootLabel.text = [NSString stringWithCString:scaleRoots[g_scaleRoot].c_str() encoding:[NSString defaultCStringEncoding]];
    
    Globals::scale.clear();
    if (g_scaleIsMajor) {
        for (int i = 0; i < majorScale.size(); i++)
            Globals::scale.push_back(g_scaleRoot + majorScale[i]);
    }
    else {
        for (int i = 0; i < minorScale.size(); i++)
            Globals::scale.push_back(g_scaleRoot + minorScale[i]);
    }
}

- (IBAction)scaleRootDown:(id)sender {
    if (g_scaleRoot == 0)
        g_scaleRoot = (int)(scaleRoots.size() - 1);
    else
        g_scaleRoot--;
    
    self.scaleRootLabel.text = [NSString stringWithCString:scaleRoots[g_scaleRoot].c_str() encoding:[NSString defaultCStringEncoding]];
    
    Globals::scale.clear();
    if (g_scaleIsMajor) {
        for (int i = 0; i < majorScale.size(); i++)
            Globals::scale.push_back(g_scaleRoot + majorScale[i]);
    }
    else {
        for (int i = 0; i < minorScale.size(); i++)
            Globals::scale.push_back(g_scaleRoot + minorScale[i]);
    }
}

@end
