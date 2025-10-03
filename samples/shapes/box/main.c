#include <math.h>
#include <raylib.h>
#include <rlgl.h>

#if defined(_EE)
    //TODO: still not sure if this is the best way
    #define RAYMATH_IMPLEMENTATION
    #define RAYMATH_STATIC
#endif
#include "raymath.h"

#define ATTR_PLAYSTATION2_WIDTH  640
#define ATTR_PLAYSTATION2_HEIGHT 448

static float cube_spin_angle = 0.0f;
static const float cube_z = -6.0f;
static const float cube_forward_rotation = -18.0f;

static Model rgb_cube_model;

static void cube_position_and_rotation(void);
static void draw_rgb_cube(void);
static inline void colored_vertex(float r, float g, float b, float x, float y, float z);
static void build_rgb_cube_model(void);
static void apply_barycentric_palette_to_mesh(Mesh *mesh);
static void draw_rgb_cube_model(void);

int main(void)
{
    const int screenWidth  = ATTR_PLAYSTATION2_WIDTH;
    const int screenHeight = ATTR_PLAYSTATION2_HEIGHT;
    InitWindow(screenWidth, screenHeight, "RGB Cube");

    //TODO: this causes issues only with the DrawArrays nature of raylib...
    // where i have to understand RGB vs RGBA and the GS tags stuff:
    rlDisableColorBlend();

    SetTargetFPS(60);
    // build_rgb_cube_model();
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
                // draw_rgb_cube_model();
            EndMode3D();
        EndDrawing();
    }
    // UnloadModel(rgb_cube_model);
    CloseWindow();
    return 0;
}

static void cube_position_and_rotation(void)
{
    rlTranslatef(0.0f, 0.0f, cube_z);
    rlRotatef(cube_forward_rotation, -1.0f, 0.0f, 0.0f);
    rlRotatef(cube_spin_angle, 0.0f, 1.0f, 0.0f);
}

static void draw_rgb_cube(void)
{
    rlPushMatrix();
    cube_position_and_rotation();
    rlBegin(RL_TRIANGLES);
    {
        colored_vertex(1,0,0,  1, 1, 1);
        colored_vertex(0,1,0, -1, 1, 1);
        colored_vertex(0,0,1, -1,-1, 1);

        colored_vertex(1,0,0,  1, 1, 1);
        colored_vertex(0,0,1, -1,-1, 1);
        colored_vertex(0,1,0,  1,-1, 1);

        colored_vertex(1,0,0,  1,-1,-1);
        colored_vertex(0,1,0, -1,-1,-1);
        colored_vertex(0,0,1, -1, 1,-1);

        colored_vertex(1,0,0,  1,-1,-1);
        colored_vertex(0,0,1, -1, 1,-1);
        colored_vertex(0,1,0,  1, 1,-1);

        colored_vertex(1,0,0,  1, 1,-1);
        colored_vertex(0,1,0, -1, 1,-1);
        colored_vertex(0,0,1, -1, 1, 1);

        colored_vertex(1,0,0,  1, 1,-1);
        colored_vertex(0,0,1, -1, 1, 1);
        colored_vertex(0,1,0,  1, 1, 1);

        colored_vertex(1,0,0,  1,-1, 1);
        colored_vertex(0,1,0, -1,-1, 1);
        colored_vertex(0,0,1, -1,-1,-1);

        colored_vertex(1,0,0,  1,-1, 1);
        colored_vertex(0,0,1, -1,-1,-1);
        colored_vertex(0,1,0,  1,-1,-1);

        colored_vertex(1,0,0, -1, 1, 1);
        colored_vertex(0,1,0, -1, 1,-1);
        colored_vertex(0,0,1, -1,-1,-1);

        colored_vertex(1,0,0, -1, 1, 1);
        colored_vertex(0,0,1, -1,-1,-1);
        colored_vertex(0,1,0, -1,-1, 1);

        colored_vertex(1,0,0,  1, 1,-1);
        colored_vertex(0,1,0,  1, 1, 1);
        colored_vertex(0,0,1,  1,-1, 1);

        colored_vertex(1,0,0,  1, 1,-1);
        colored_vertex(0,0,1,  1,-1, 1);
        colored_vertex(0,1,0,  1,-1,-1);
    }
    rlEnd();
    rlPopMatrix();
}

static inline void colored_vertex(float r, float g, float b, float x, float y, float z)
{
    rlColor4f(r, g, b, 1.0f);
    rlVertex3f(x, y, z);
}

static void draw_rgb_cube_model(void)
{
    Vector3 position = (Vector3){0.0f, 0.0f, cube_z};
    Vector3 rotation_axis = (Vector3){0.0f, 1.0f, 0.0f};
    Vector3 scale = (Vector3){1.0f, 1.0f, 1.0f};
    DrawModelEx(rgb_cube_model, position, rotation_axis, cube_spin_angle, scale, WHITE);
}

static void build_rgb_cube_model(void)
{
    Mesh cube_mesh = GenMeshCube(2.0f, 2.0f, 2.0f);
    apply_barycentric_palette_to_mesh(&cube_mesh);
    UploadMesh(&cube_mesh, false);
    rgb_cube_model = LoadModelFromMesh(cube_mesh);
    // Matrix baked_tilt = MatrixRotateX(DEG2RAD * 18.0f);
    // rgb_cube_model.transform = MatrixMultiply(baked_tilt, rgb_cube_model.transform);
}

static void apply_barycentric_palette_to_mesh(Mesh *mesh)
{
    if (!mesh || mesh->vertexCount <= 0) return;
    //TODO: oh no... is this all that it took for color buffer stuff?
    // test with opengl33 and es2 later...
    if (!mesh->colors)
        mesh->colors = (unsigned char *)MemAlloc(mesh->vertexCount * 4 * sizeof(unsigned char));

    for (int i = 0; i < mesh->vertexCount; ++i)
    {
        unsigned char r = 0, g = 0, b = 0;
        int mod = i % 3;
        if (mod == 0) { r = 255; }
        else if (mod == 1) { g = 255; }
        else { b = 255; }
        mesh->colors[i*4 + 0] = r;
        mesh->colors[i*4 + 1] = g;
        mesh->colors[i*4 + 2] = b;
        mesh->colors[i*4 + 3] = 255;
    }
}
