/*******************************************************************************************
*
* im trying to make a game fml
*
********************************************************************************************/

#include "raylib.h"

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>

//#define PLATFORM_WEB
#define MY_DEBUG

#if defined(PLATFORM_WEB)
    #include <emscripten/emscripten.h>
#endif

//----------------------------------------------------------------------------------
// Some Defines
//----------------------------------------------------------------------------------

#define PLAYER_MAX_LIFE         5
#define FOOD_INTERVAL           1
#define FOOD_AMOUNT             50
#define CONSOLE_BG              (Color){ 0, 0, 0, 200 }              // Transparent black
//#define CONSOLE_FG              (Color){ 255, 255, 255, 200 }        // Transparent white

//----------------------------------------------------------------------------------
// Some Defines
//----------------------------------------------------------------------------------
#define ARRAY_LENGTH(arr) (sizeof(arr) / sizeof(arr[0]))

//----------------------------------------------------------------------------------
// Types and Structures Definition
//----------------------------------------------------------------------------------
typedef enum GameScreen { LOGO, TITLE, GAMEPLAY, ENDING } GameScreen;

typedef struct Player {
    Vector2 position;
    Vector2 size;
    int life;
} Player;

typedef struct Food {
    Vector2 position;
    float   radius;
    bool shouldBeDrawn;
    int value;
} Food;

typedef struct Console {
    char* text;
    bool shown;
    bool mouseOnText;
    int letterCount;
} Console;

//----------------------------------------------------------------------------------
// Global Variables Definition
//----------------------------------------------------------------------------------
static int  screenWidth = 800;
static int  screenHeight = 450;

static int  framesCounter;
static bool gameOver;
static bool pause;

static Console console;
static Rectangle textBox;

static Food foodArray[FOOD_AMOUNT];
//static bool timeOut;

static Player player;

static clock_t startTime;



// TODO: Represent food as an array of circles or an array of Vector2s.
//       We can then iterate over the array in GameUpdate(), update the shouldBeDrawn property each Timer() iteration,
//       and in DrawGame draw each food if it's shouldBeDrawn property is true.

//------------------------------------------------------------------------------------
// Module Functions Declaration (local)
//------------------------------------------------------------------------------------
static void InitGame(void);         // Initialize game
static void UpdateGame(void);       // Update game (one frame)
static void DrawGame(void);         // Draw game (one frame)
static void UnloadGame(void);       // Unload game
static void UpdateDrawFrame(void);  // Update and Draw (one frame)

// Additional module functions
static void UpdateFood(void);
static void DrawFood(void);
static bool Timer(int seconds);
static void DrawConsole(void);
static void UpdateConsole(void);
static Rectangle GetGround(void);
static int  CompareFoodLocations(const Food* food1, const Food* food2);


//----------------------------------------------------------------------------------
// Main Enry Point
//----------------------------------------------------------------------------------
int main()
{
    // Initialization
    //--------------------------------------------------------------------------------------
    InitWindow(screenWidth, screenHeight, "what should i name this piece of s##t game");
    
    InitGame();
    
#if defined(PLATFORM_WEB)
    emscripten_set_main_loop(UpdateDrawFrame, 0, 1);
#else
    
    SetTargetFPS(60);   // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------
    
    // Main game loop
    while (!WindowShouldClose())    // Detect window close button or ESC key
    {
        // Update
        //----------------------------------------------------------------------------------
        UpdateGame();
        //----------------------------------------------------------------------------------
        
        // Draw
        //----------------------------------------------------------------------------------
        DrawGame();
        //----------------------------------------------------------------------------------
        
    }
#endif

    // De-Initialization
    //--------------------------------------------------------------------------------------
    UnloadGame();         // Unload loaded data (textures, sounds, models etc)
    
    CloseWindow();        // Close window and OpenGL context
    //--------------------------------------------------------------------------------------

    return 0;
}

//----------------------------------------------------------------------------------
// Module Functions Definition
//----------------------------------------------------------------------------------
void InitGame(void)
{
    // Initialize player
    player.position = (Vector2){ screenWidth/2, screenHeight - screenHeight/8 };
    player.size = (Vector2){ screenWidth/10, screenHeight/22.5 };
    player.life = PLAYER_MAX_LIFE;
    
    // Initialize console
    textBox = (Rectangle){ screenWidth/40, screenHeight-screenHeight/20 - screenHeight/40, screenWidth - screenWidth/20, screenHeight/20 };
    console.shown = false;
    console.text = "hh";
    console.mouseOnText = false;
    console.letterCount = 0;
    int framesCounter = 0;

    // Initialize food
    for (int i = 0; i < FOOD_AMOUNT; i++)
    {
        float tempRadius = GetRandomValue(10, GetScreenWidth()/60);
        do foodArray[i] = (Food){ (Vector2){ GetRandomValue(tempRadius, GetScreenWidth() - tempRadius), GetGround().y - tempRadius }, tempRadius, false, GetRandomValue(1, 15) };
        while (!CheckCollisionCircleRec(foodArray[i].position, foodArray[i].radius, (Rectangle) { player.position.x, player.position.y, player.size.x, player.size.y }));
    #ifdef MY_DEBUG
        TraceLog(INFO, FormatText("%d ", foodArray[i]));
    #endif
    }
    
#ifdef MY_DEBUG
    TraceLog(INFO, "\n\n\n");
#endif

    qsort(foodArray, FOOD_AMOUNT, sizeof(Food), (*CompareFoodLocations));

#ifdef MY_DEBUG
    for (int i = 0; i < FOOD_AMOUNT; i++)
    {
        TraceLog(INFO, FormatText("%d ", foodArray[i]));    
    }
    TraceLog(INFO, "\n\n\n");
#endif

}

// Update game (one frame)
void UpdateGame(void)
{
    if (IsKeyPressed('C')) console.shown = !console.shown;
    if (!gameOver)
    {
        if (IsKeyPressed('P')) pause = !pause;
        
        if (!pause)
        {
            // Player Movement
            if (IsKeyDown(KEY_LEFT))                                  player.position.x -= 5;
            if ((player.position.x - player.size.x/2) <= 0)           player.position.x =  player.size.x/2;
            if (IsKeyDown(KEY_RIGHT))                                 player.position.x += 5;
            if ((player.position.x + player.size.x/2) >= screenWidth) player.position.x =  screenWidth - player.size.x/2;
            
            // Update food
            UpdateFood();
            
            if (player.life <= 0) gameOver = true;
        }
    }
    else
    {
        if (IsKeyPressed(KEY_ENTER))
        {
            InitGame();
            gameOver = false;
        }
    }
}

// Draw game (one frame)
void DrawGame(void)
{
    BeginDrawing();
    
        ClearBackground(RAYWHITE);
        
        if (!gameOver)
        {
        #if defined(MY_DEBUG)                                                                                                                     
            DrawText(FormatText("screen: %dx%d\nx: %f\nconsole: %d", screenWidth, screenHeight, player.position.x, console.mouseOnText),  50, 70, 20, BLACK);
        #endif
            // Draw ground
            DrawRectangleRec(GetGround(), GREEN);
            
            // Draw player bar
            DrawRectangle(player.position.x - player.size.x/2, player.position.y - player.size.y/2, player.size.x, player.size.y, BLACK);
            
            // Draw player lives
            for (int i = 0; i < player.life; i++) DrawRectangle(10 + 40*i, 10, 35, 10, LIGHTGRAY);
            
            // Draw food
            for (int i = 0; i < FOOD_AMOUNT; i++)
                if (foodArray[i].shouldBeDrawn == true) DrawCircle(foodArray[i].position.x, foodArray[i].position.y, foodArray[i].radius, RED);
            
            // Handle pausing
            if (pause) DrawText("GAME PAUSED", screenWidth / 2 - MeasureText("GAME PAUSED", 40)/2, screenHeight/2 - 40, 40, GRAY);
        }
        else DrawText("PRESS [ENTER] TO PLAY AGAIN", screenWidth/2 - MeasureText("PRESS [ENTER] TO PLAY AGAIN", 20)/2, screenHeight/2 - 50, 20, GRAY);
        
        if (console.shown) DrawConsole();
        
    EndDrawing();
}

// Unload game variables
void UnloadGame(void)
{
    // TODO: Free game assets
}

// Update and draw (one frame)
void UpdateDrawFrame(void)
{
    UpdateGame();
    DrawGame();
}    

//--------------------------------------------------------------------------------------
// Additional module functions
//--------------------------------------------------------------------------------------
void UpdateFood(void)
{
    // TODO: Implement collision detection
    int foodIndex = GetRandomValue(0, FOOD_AMOUNT - 1);
    if (Timer(2)) foodArray[foodIndex].shouldBeDrawn = true;        
}

/// Version with static variable
bool Timer(int seconds)
{
    static clock_t startTime = (clock_t) -1;
    
    if (startTime == -1) 
    {
        startTime = clock();
        return false;
    }
    
    else if (((clock() - startTime) / CLOCKS_PER_SEC) > seconds)
    {
        startTime = clock();
        return true;
    }
    
    return false;
}

void DrawConsole(void)
{
    DrawRectangle(0, 2*screenHeight/3, screenWidth, screenHeight/3, CONSOLE_BG);
    DrawRectangle(screenWidth/40, screenHeight-screenHeight/20 - screenHeight/40, screenWidth - screenWidth/20, screenHeight/20, LIGHTGRAY);
}

void UpdateConsole(void)
{
    if (CheckCollisionPointRec(GetMousePosition(), textBox)) console.mouseOnText = true;
    else console.mouseOnText = false;
    
    if (console.mouseOnText)
        {
            int key = GetKeyPressed();
            
            if ((key >= 32) && (key <= 125) && (console.letterCount < 8))
            {
                console.text[console.letterCount] = (char)key;
                console.letterCount++;
            }
            
            if (key == KEY_BACKSPACE)
            {
                console.letterCount--;
                console.text[console.letterCount] = '\0';
                
                if (console.letterCount < 0) console.letterCount = 0;
            }
        }
        
        if (console.mouseOnText) framesCounter++;
        else framesCounter = 0;
}

Rectangle GetGround(void)
{
    return (Rectangle) { 0, GetScreenHeight() - GetScreenHeight()/8 + (GetScreenHeight() - GetScreenHeight()/8)/36, GetScreenWidth(), GetScreenHeight()/9 };
}

bool CheckIfEaten(void)
{
    //for (int i = 0; i <= FOOD_AMOUNT)
    
}

int CompareFoodLocations(const Food* food1, const Food* food2)
{
    return (food1->position.x - food2->position.y);
}