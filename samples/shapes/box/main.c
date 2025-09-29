#include <math.h>
#include <raylib.h>
#include <rlgl.h>

#define RAYMATH_IMPLEMENTATION
#define RAYMATH_STATIC
#include "raymath.h"

#define ATTR_PLAYSTATION2_WIDTH  640
#define ATTR_PLAYSTATION2_HEIGHT 448

static float cube_spin_angle = 0.0f;
static const float cube_z = -6.0f;
static const float cube_forward_rotation = -18.0f;

static Model rgb_cube_model;


static void reshape(int width, int height);
static void perspective(float fov, float aspect, float nearClip, float farClip);
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

    InitWindow(screenWidth, screenHeight, "RGB Cube (raylib + rlgl immediate mode)");
    SetTargetFPS(60);

    rlEnableDepthTest();
    reshape(screenWidth, screenHeight);

    build_rgb_cube_model();

    while (!WindowShouldClose())
    {
        if (IsWindowResized()) reshape(GetScreenWidth(), GetScreenHeight());

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

        rlMatrixMode(RL_PROJECTION);
        rlLoadIdentity();
        perspective(40.0f, (float)GetScreenWidth()/(float)GetScreenHeight(), 0.1f, 4000.0f);

        rlMatrixMode(RL_MODELVIEW);
        rlLoadIdentity();

        draw_rgb_cube();
        //draw_rgb_cube_model();
        EndMode3D();

        DrawFPS(10, 10);
        EndDrawing();
    }
    UnloadModel(rgb_cube_model);

    CloseWindow();
    return 0;
}


static void reshape(int width, int height)
{
    if (height <= 0) height = 1;
    rlViewport(0, 0, width, height);

    rlMatrixMode(RL_PROJECTION);
    rlLoadIdentity();
    perspective(40.0f, (float)width/(float)height, 0.1f, 4000.0f);

    rlMatrixMode(RL_MODELVIEW);
    rlLoadIdentity();
}

static void perspective(float fov, float aspect, float nearClip, float farClip)
{
    // Match the classic glFrustum computed from fovy/aspect/near/far
    float fovRad = fov * (PI/180.0f);
    float h = 2.0f * nearClip * tanf(fovRad*0.5f);
    float w = h * aspect;

    rlMatrixMode(RL_PROJECTION);
    // Don’t reset here—caller decides when to load identity for flexibility
    rlFrustum(-w*0.5f, w*0.5f, -h*0.5f, h*0.5f, nearClip, farClip);

    rlMatrixMode(RL_MODELVIEW);
    rlLoadIdentity();
}

static void cube_position_and_rotation(void)
{
    // Translate to z=-6, pitch -18 degrees around -X, then spin around +Y
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

    Matrix baked_tilt = MatrixRotateX(DEG2RAD * 18.0f);
    rgb_cube_model.transform = MatrixMultiply(baked_tilt, rgb_cube_model.transform);
}

static void apply_barycentric_palette_to_mesh(Mesh *mesh)
{
    if (!mesh || mesh->vertexCount <= 0) return;

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
