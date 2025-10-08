#include <math.h>
#include <raylib.h>
#include <rlgl.h>

#define ATTR_PLAYSTATION2_WIDTH  640
#define ATTR_PLAYSTATION2_HEIGHT 448

static float cube_spin_angle = 0.0f;
static const float cube_z = -6.0f;
static const float cube_forward_rotation = -18.0f;

static void cube_position_and_rotation(void);
static void draw_rgb_cube(void);
static inline void colored_vertex(Color color, float x, float y, float z);
//TODO: just to confirm stuff
#define RED        CLITERAL(Color){ 255, 0, 0, 255 }
#define GREEN      CLITERAL(Color){ 0, 255, 0, 255 }
#define BLUE       CLITERAL(Color){ 0, 0, 255, 255 }


int main(void)
{
    const int screenWidth  = ATTR_PLAYSTATION2_WIDTH;
    const int screenHeight = ATTR_PLAYSTATION2_HEIGHT;
    InitWindow(screenWidth, screenHeight, "RGB Cube");

    //TODO: this causes issues only with the DrawArrays nature of raylib...
    // where i have to understand RGB vs RGBA and the GS tags stuff:
    rlDisableColorBlend();

    SetTargetFPS(60);
    while (!WindowShouldClose())
    {
        cube_spin_angle += 0.2f;
        BeginDrawing();
            ClearBackground(BLACK);
            rlClearScreenBuffers();
            rlEnableDepthTest();
            Camera camera = {0};
            camera.position = (Vector3){0.0f, 0.0f, 0.0f};
            camera.target   = (Vector3){0.0f, 0.0f, -1.0f};
            camera.up       = (Vector3){0.0f, 1.0f, 0.0f};
            camera.fovy     = 40.0f;
            camera.projection = CAMERA_PERSPECTIVE;
            BeginMode3D(camera);
                draw_rgb_cube();
            EndMode3D();
        EndDrawing();
    }
    CloseWindow();
    return 0;
}

static void cube_position_and_rotation(void)
{
    rlTranslatef(0.0f, 0.0f, cube_z);
    rlRotatef(cube_forward_rotation, -1.0f, 0.0f, 0.0f);
    rlRotatef(cube_spin_angle, 0.0f, 1.0f, 0.0f);
}

static void draw_rgb_cube(void) {
    rlPushMatrix();
    cube_position_and_rotation();
    rlBegin(RL_TRIANGLES);
    {
        colored_vertex(RED,   1,  1,  1);
        colored_vertex(GREEN,-1,  1,  1);
        colored_vertex(BLUE, -1, -1,  1);

        colored_vertex(RED,   1,  1,  1);
        colored_vertex(BLUE, -1, -1,  1);
        colored_vertex(GREEN, 1, -1,  1);

        colored_vertex(RED,   1, -1, -1);
        colored_vertex(GREEN,-1, -1, -1);
        colored_vertex(BLUE, -1,  1, -1);

        colored_vertex(RED,   1, -1, -1);
        colored_vertex(BLUE, -1,  1, -1);
        colored_vertex(GREEN, 1,  1, -1);

        colored_vertex(RED,   1,  1, -1);
        colored_vertex(GREEN,-1,  1, -1);
        colored_vertex(BLUE, -1,  1,  1);

        colored_vertex(RED,   1,  1, -1);
        colored_vertex(BLUE, -1,  1,  1);
        colored_vertex(GREEN, 1,  1,  1);

        colored_vertex(RED,   1, -1,  1);
        colored_vertex(GREEN,-1, -1,  1);
        colored_vertex(BLUE, -1, -1, -1);

        colored_vertex(RED,   1, -1,  1);
        colored_vertex(BLUE, -1, -1, -1);
        colored_vertex(GREEN, 1, -1, -1);

        colored_vertex(RED,  -1,  1,  1);
        colored_vertex(GREEN,-1,  1, -1);
        colored_vertex(BLUE, -1, -1, -1);

        colored_vertex(RED,  -1,  1,  1);
        colored_vertex(BLUE, -1, -1, -1);
        colored_vertex(GREEN,-1, -1,  1);

        colored_vertex(RED,   1,  1, -1);
        colored_vertex(GREEN, 1,  1,  1);
        colored_vertex(BLUE,  1, -1,  1);

        colored_vertex(RED,   1,  1, -1);
        colored_vertex(BLUE,  1, -1,  1);
        colored_vertex(GREEN, 1, -1, -1);
    }
    rlEnd();
    rlPopMatrix();
}

static inline void colored_vertex(Color color, float x, float y, float z)
{
    // rlColor4f(color.r/255.0, color.g/255.0, color.b/255.0, color.a/255.0);
    rlColor4ub(color.r, color.g, color.b, color.a);
    rlVertex3f(x, y, z);
}

