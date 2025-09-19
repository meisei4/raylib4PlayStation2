
/*******************************************************************************************
*
*   raylib [shapes] example - collision area
*
*   Example originally created with raylib 2.5, last time updated with raylib 2.5
*
*   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
*   BSD-like license that allows static linking with closed source software
*
*   Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
*
********************************************************************************************/

#include <raylib.h>

#define ATTR_PLAYSTATION2_WIDTH 640
#define ATTR_PLAYSTATION2_HEIGHT 448

static bool done = false;
static bool paused = false;
int xflag;

static int x;
static int y;

static void updateController(void) {
    bool dpadLeftDown;
    bool dpadRightDown;
    bool dpadDownDown;
    bool dpadUpDown;
    bool startPressed;
    bool xPressed;
    bool oPressed;


   if(!IsGamepadAvailable(0))
        return;

    dpadLeftDown = IsGamepadButtonDown(0, GAMEPAD_BUTTON_LEFT_FACE_LEFT);
    dpadRightDown = IsGamepadButtonDown(0, GAMEPAD_BUTTON_LEFT_FACE_RIGHT);
    dpadDownDown = IsGamepadButtonDown(0, GAMEPAD_BUTTON_LEFT_FACE_DOWN);
    dpadUpDown = IsGamepadButtonDown(0, GAMEPAD_BUTTON_LEFT_FACE_UP);
    startPressed = IsGamepadButtonPressed(0, GAMEPAD_BUTTON_MIDDLE_RIGHT);
    xPressed = IsGamepadButtonPressed(0, GAMEPAD_BUTTON_RIGHT_FACE_DOWN);
    oPressed = IsGamepadButtonPressed(0, GAMEPAD_BUTTON_RIGHT_FACE_RIGHT);


    if(startPressed)
        done = true;

    if(dpadUpDown)
        y = y - 10;

    if(dpadDownDown)
        y = y + 10;

    if(dpadRightDown)
        x = x + 10;

    if(dpadLeftDown)
        x = x - 10;
    
    if(xPressed) 
        xflag=1;

    if(oPressed)
        paused = !paused;
}

int main(int argc, char** argv) {

    // Initialization
    //--------------------------------------------------------------------------------------
    const int screenWidth = ATTR_PLAYSTATION2_WIDTH;
    const int screenHeight = ATTR_PLAYSTATION2_HEIGHT;

    InitWindow(screenWidth, screenHeight, "raylib [shapes] example - raylib collision area");
    
    float rotation = 0.0f;


    int logoPositionX = screenWidth/2 - 128;
    int logoPositionY = screenHeight/2 - 128;

    int framesCounter = 0;
    int lettersCount = 0;

    int topSideRecWidth = 16;
    int leftSideRecHeight = 16;

    int bottomSideRecWidth = 16;
    int rightSideRecHeight = 16;

    int state = 0;                  // Tracking animation states (State Machine)
    float alpha = 1.0f;             // Useful for fading



    // Box A: Moving box
    Rectangle boxA = { 10, GetScreenHeight()/2.0f - 50, 200, 100 };
    int boxASpeedX = 4;

    // Box B: Mouse moved box
   
    x = screenWidth/2;
    y = screenHeight/2;

    Rectangle boxCollision = { 0 }; // Collision rectangle
    Rectangle boxB = { GetScreenWidth()/2.0f - 30, GetScreenHeight()/2.0f - 30, 60, 60 };

    int screenUpperLimit = 40;      // Top menu limits

    bool collision = false;         // Collision detection





    SetTargetFPS(60);               // Set our game to run at 60 frames-per-second
    //----------------------------------------------------------

    // Main game loop
    while(!done) {    // Detect window start button
        // Update
        //-----------------------------------------------------
        updateController();

        if (state == 0)                 // State 0: Small box blinking
        {
            framesCounter++;

            if (framesCounter == 120)
            {
                state = 1;
                framesCounter = 0;      // Reset counter... will be used later...
            }
        }
        else if (state == 1)            // State 1: Top and left bars growing
        {
            topSideRecWidth += 4;
            leftSideRecHeight += 4;

            if (topSideRecWidth == 256) state = 2;
        }
        else if (state == 2)            // State 2: Bottom and right bars growing
        {
            bottomSideRecWidth += 4;
            rightSideRecHeight += 4;

            if (bottomSideRecWidth == 256) state = 3;
        }
        else if (state == 3)            // State 3: Letters appearing (one by one)
        {
            framesCounter++;

            if (framesCounter/12)       // Every 12 frames, one more letter!
            {
                lettersCount++;
                framesCounter = 0;
            }

            if (lettersCount >= 10)     // When all letters have appeared, just fade out everything
            {
                alpha -= 0.02f;

                if (alpha <= 0.0f)
                {
                    alpha = 0.0f;
                    state = 4;
                }
            }
        }
        else if (state == 4)            // State 4: Reset and Replay
        {
            if (xflag)
            {
                framesCounter = 0;
                lettersCount = 0;

                topSideRecWidth = 16;
                leftSideRecHeight = 16;

                bottomSideRecWidth = 16;
                rightSideRecHeight = 16;

                alpha = 1.0f;
                state = 5;          // Return to State 0
                xflag = 0;
            }
        }
        else if (state == 5)
        {
            if (xflag)
            {
                    state=6;
                    xflag=0;
            }

        }
        else if(state ==6)
        {
            rotation += 0.2f;
        }

        // Move box if not paused
        if(!paused) 
            boxA.x += boxASpeedX;

        // Bounce box on x screen limits
        if(((boxA.x + boxA.width) >= GetScreenWidth()) || (boxA.x <= 0)) 
            boxASpeedX *= -1;

        // Update player-controlled-box (box02)
        boxB.x = x - boxB.width/2;
        boxB.y = y - boxB.height/2;

        // Make sure Box B does not go out of move area limits
        if((boxB.x + boxB.width) >= GetScreenWidth()) 
            boxB.x = GetScreenWidth() - boxB.width;
        else if(boxB.x <= 0) 
            boxB.x = 0;

        if ((boxB.y + boxB.height) >= GetScreenHeight()) 
            boxB.y = GetScreenHeight() - boxB.height;
        else if(boxB.y <= screenUpperLimit) 
            boxB.y = (float)screenUpperLimit;

        // Check boxes collision
        collision = CheckCollisionRecs(boxA, boxB);

        // Get collision rectangle (only on collision)
        if(collision) 
            boxCollision = GetCollisionRec(boxA, boxB);

        //-----------------------------------------------------

        // Draw
        //-----------------------------------------------------
        BeginDrawing();

            ClearBackground(RAYWHITE);


            ClearBackground(RAYWHITE);
   
            if (state == 0)
            {
                if ((framesCounter/15)%2) DrawRectangle(logoPositionX, logoPositionY, 16, 16, BLACK);
            }
            else if (state == 1)
            {
                DrawRectangle(logoPositionX, logoPositionY, topSideRecWidth, 16, BLACK);
                DrawRectangle(logoPositionX, logoPositionY, 16, leftSideRecHeight, BLACK);
            }
            else if (state == 2)
            {
                DrawRectangle(logoPositionX, logoPositionY, topSideRecWidth, 16, BLACK);
                DrawRectangle(logoPositionX, logoPositionY, 16, leftSideRecHeight, BLACK);

                DrawRectangle(logoPositionX + 240, logoPositionY, 16, rightSideRecHeight, BLACK);
                DrawRectangle(logoPositionX, logoPositionY + 240, bottomSideRecWidth, 16, BLACK);
            }
            else if (state == 3)
            {
                DrawRectangle(logoPositionX, logoPositionY, topSideRecWidth, 16, Fade(BLACK, alpha));
                DrawRectangle(logoPositionX, logoPositionY + 16, 16, leftSideRecHeight - 32, Fade(BLACK, alpha));

                DrawRectangle(logoPositionX + 240, logoPositionY + 16, 16, rightSideRecHeight - 32, Fade(BLACK, alpha));
                DrawRectangle(logoPositionX, logoPositionY + 240, bottomSideRecWidth, 16, Fade(BLACK, alpha));

                DrawRectangle(GetScreenWidth()/2 - 112, GetScreenHeight()/2 - 112, 224, 224, Fade(RAYWHITE, alpha));
                DrawText(TextSubtext("raylib", 0, lettersCount), GetScreenWidth()/2 - 44, GetScreenHeight()/2 + 48, 50, Fade(BLACK, alpha));
            }
            else if (state == 4)
            {
                DrawText("March 31st, my 50th birthday :) giving some love to raylib", screenWidth/2-200-100, screenHeight/2-38-40, 20, BLACK);
                DrawText("powered by raylib4Playstation2 [X] CONTINUE", screenWidth/2-200-60, screenHeight/2-38, 20, RED);
            }
            else if(state == 5)
            {
                DrawRectangle(0, 0, screenWidth, screenUpperLimit, collision? RED : BLACK);

                DrawRectangleRec(boxA, GOLD);
                DrawRectangleRec(boxB, BLUE);

                if(collision) 
                {
                    // Draw collision area
                    DrawRectangleRec(boxCollision, LIME);

                    // Draw collision message
                    DrawText("COLLISION!", GetScreenWidth()/2 - MeasureText("COLLISION!", 20)/2, screenUpperLimit/2 - 10, 20, BLACK);

                    // Draw collision area
                    DrawText(TextFormat("Collision Area: %i", (int)boxCollision.width*(int)boxCollision.height), GetScreenWidth()/2 - 100, screenUpperLimit + 10, 20, BLACK);
                }

                // Draw help instructions
                DrawText("Press O to PAUSE/RESUME X CONTINUE", 20, screenHeight - 35, 20, LIGHTGRAY);

            }
            else if(state == 6)
            {
                DrawText("some basic shapes available on raylib", 20, 20, 20, DARKGRAY);

            // Circle shapes and lines
            DrawCircle(screenWidth/5, 75, 30, DARKBLUE);
            DrawCircleGradient(screenWidth/5, 145, 35, GREEN, SKYBLUE);
            DrawCircleLines(screenWidth/5, 220, 37, DARKBLUE); //not supported on Dreamcast

            // Rectangle shapes and lines
            DrawRectangle(screenWidth/4*2 - 60, 60, 120, 60, RED);
            DrawRectangleGradientH(screenWidth/4*2 - 70, 130, 160, 80, MAROON, GOLD);
            DrawRectangleLines(screenWidth/4*2 - 40, 220, 80, 40, ORANGE);  // NOTE: Uses QUADS internally, not lines

            // Triangle shapes and lines
            DrawTriangle((Vector2){ screenWidth/4.0f *3.0f+30.0f, 60.0f },
                         (Vector2){ screenWidth/4.0f *3.0f, 110.0f },
                         (Vector2){ screenWidth/4.0f *3.0f + 60.0f, 110.0f }, VIOLET);

            DrawTriangleLines((Vector2){ screenWidth/4.0f*3.0f+30.0f, 120.0f },
                              (Vector2){ screenWidth/4.0f*3.0f +10.0f, 170.0f },
                              (Vector2){ screenWidth/4.0f*3.0f + 50.0f, 170.0f }, DARKBLUE);

            // Polygon shapes and lines
            DrawPoly((Vector2){ screenWidth/4.0f*3+30.0f, 220 }, 6, 30, rotation, BROWN);
            DrawPolyLines((Vector2){ screenWidth/4.0f*3+30.0f, 220 }, 6, 35, rotation, BROWN); 
            DrawPolyLinesEx((Vector2){ screenWidth/4.0f*3+30.0f, 220 }, 6, 45, rotation, 6, BEIGE);

            // NOTE: We draw all LINES based shapes together to optimize internal drawing,
            // this way, all LINES are rendered in a single draw pass
            DrawLine(18, 42, screenWidth - 18, 42, BLACK); 
            }

            

            DrawFPS(10, 10);

        EndDrawing();
        //-----------------------------------------------------
    }

    // De-Initialization
    //---------------------------------------------------------
    CloseWindow();        // Close window and OpenGL context
    //----------------------------------------------------------

    return 0;
}
