#include <math.h>
#include <raylib.h>
#include <rlgl.h>


#define ATTR_PLAYSTATION2_WIDTH  640
#define ATTR_PLAYSTATION2_HEIGHT 448

static float cube_spin_angle = 0.0f;
static const float cube_z = -6.0f;
// static const float cube_forward_rotation = -18.0f;

static Model cube_model;

static void gen_rgb_cube_model(void);
static void apply_barycentric_palette_to_mesh(Mesh *mesh);
static void draw_cube_model(void);

int main(void)
{
    const int screenWidth  = ATTR_PLAYSTATION2_WIDTH;
    const int screenHeight = ATTR_PLAYSTATION2_HEIGHT;
    InitWindow(screenWidth, screenHeight, "RGB Cube");

    SetTargetFPS(60);
    gen_rgb_cube_model();
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
                Vector3 position = (Vector3){0.0f, 0.0f, cube_z};
                Vector3 rotation_axis = (Vector3){0.0f, 1.0f, 0.0f};
                Vector3 scale = (Vector3){1.0f, 1.0f, 1.0f};
                DrawModelEx(cube_model, position, rotation_axis, cube_spin_angle, scale, WHITE);
                // DrawModelEx(cube_model, position, rotation_axis, cube_spin_angle, scale, MAGENTA);
            EndMode3D();
        EndDrawing();
    }
    UnloadModel(cube_model);
    CloseWindow();
    return 0;
}

static void gen_rgb_cube_model(void)
{
    Mesh cube_mesh = GenMeshCube(2.0f, 2.0f, 2.0f);
    apply_barycentric_palette_to_mesh(&cube_mesh);
    cube_model = LoadModelFromMesh(cube_mesh);
}

static void apply_barycentric_palette_to_mesh(Mesh *mesh)
{
    if (!mesh || mesh->vertexCount <= 0) return;
    if (!mesh->colors) mesh->colors = (unsigned char *)MemAlloc(mesh->vertexCount * 4 * sizeof(unsigned char));

    const Vector3 ref[8] = {
        {-1, -1, -1}, 
        { 1, -1, -1},
        { 1,  1, -1},
        {-1,  1, -1},
        {-1, -1,  1},
        { 1, -1,  1},
        { 1,  1,  1},
        {-1,  1,  1}
    };

    const unsigned char palette[3][3] = {
        {255, 0, 0},  
        {0, 255, 0},  
        {0, 0, 255}   
    };

    for (int i = 0; i < mesh->vertexCount; i++)
    {
        Vector3 v = {
            mesh->vertices[i*3 + 0],
            mesh->vertices[i*3 + 1],
            mesh->vertices[i*3 + 2]
        };

        int idx = 0;
        float eps = 0.001f;
        for (int j = 0; j < 8; j++) {
            if (fabsf(v.x - ref[j].x) < eps &&
                fabsf(v.y - ref[j].y) < eps &&
                fabsf(v.z - ref[j].z) < eps)
            {
                idx = j;
                break;
            }
        }

        int colorIndex = idx % 3;
        mesh->colors[i*4 + 0] = palette[colorIndex][0];
        mesh->colors[i*4 + 1] = palette[colorIndex][1];
        mesh->colors[i*4 + 2] = palette[colorIndex][2];
        mesh->colors[i*4 + 3] = 255;
    }
}

