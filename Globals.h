//
//  Globals.h
//  Fingerboard
//
//  Created by Trijeet Mukhopadhyay on 1/27/15.
//  Copyright (c) 2015 Trijeet Mukhopadhyay. All rights reserved.
//

#ifndef Fingerboard_Globals_h
#define Fingerboard_Globals_h

#import <vector>

struct Note {
    int octave;
    int key;
};

class Globals {
    
public:
    static std::vector <int> scale;
    static float fingerboardWidth;
    static float fingerboardHeight;
    static Note currentNote;
};

#endif
