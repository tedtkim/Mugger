//
//  ScoringConstants.h
//  Mugger
//
//  Created by Ted Kim on 12/8/13.
//  Copyright (c) 2013 CS193p. All rights reserved.
//

#ifndef Mugger_ScoringConstants_h
#define Mugger_ScoringConstants_h


// Categories for combined faces in a mug
#define SCORE_NO_FACES_PENALTY -100
#define SCORE_TOO_MANY_FACES_PENALTY -25
#define SCORE_NO_POSITIVE_FACES_PENALTY -10
#define SCORE_FACE_BONUS 1
#define SCORE_POSITIVE_FACE_BONUS 2
#define SCORE_ALL_POSITIVE_FACE_BONUS 10

// Categories for combined features of a face
// Potential additions: optimal eyes/mouth triangle calculation
#define SCORE_FACE_ANGLE_BONUS 2    // cute :)

// Categories for eyes
#define SCORE_EYES_BONUS 1
#define SCORE_EYES_MISSING_PENALTY -10  // scary!
#define SCORE_EYES_BOTH_OPEN_BONUS 1
#define SCORE_EYES_WINK_BONUS 2
#define SCORE_EYES_BOTH_CLOSED_PENALTY -3

// Categories for mouth
#define SCORE_MOUTH_SMILE_BONUS 4
#define SCORE_MOUTH_BONUS 1
#define SCORE_MOUTH_MISSING_PENALTY -2

#endif
