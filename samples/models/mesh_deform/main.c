#include <math.h>
#include <raylib.h>
#include <rlgl.h>
#include <GL/gl.h>


#define ATTR_PLAYSTATION2_WIDTH  640
#define ATTR_PLAYSTATION2_HEIGHT 448

static Model model;
static float spin = 0.0f;

static void ApplyRGBGradientToMesh(Mesh *mesh);

int main(void)
{
    const int screenWidth  = ATTR_PLAYSTATION2_WIDTH;
    const int screenHeight = ATTR_PLAYSTATION2_HEIGHT;
    InitWindow(screenWidth, screenHeight, "Mesh");

    //TODO: this causes issues only with the DrawArrays nature of raylib... should not need to flip back...
    rlDisableColorBlend();
    // rlDisableBackfaceCulling(); //TODO: something funky happens here with raylib opengl11? im not sure why...
    SetTargetFPS(15);
    model = LoadModel("sphere.obj");
    ApplyRGBGradientToMesh(&model.meshes[0]);
    while (!WindowShouldClose())
    {
        spin += 0.8f;
        BeginDrawing();
            ClearBackground(BLACK);
            Camera camera = {0};
            camera.position = (Vector3){0.0f, 0.0f, 0.0f};
            camera.target   = (Vector3){0.0f, 0.0f, -1.0f};
            camera.up       = (Vector3){0.0f, 1.0f, 0.0f};
            camera.fovy     = 45.0f;
            camera.projection = CAMERA_PERSPECTIVE;
            rlDisableColorBlend();
            BeginMode3D(camera);
                Vector3 position = (Vector3){0.0f, 0.0f, -6.0f};
                Vector3 rotation_axis = (Vector3){0.0f, 1.0f, 0.0f};
                Vector3 scale = (Vector3){1.0f, 1.0f, 1.0f};
                DrawModelWiresEx(model, position, rotation_axis, spin, scale, WHITE);
                // DrawModelEx(model, position, rotation_axis, spin, scale, WHITE);

            EndMode3D();
            rlEnableColorBlend();
            DrawText("HELLOOOOOOO, this is a TEsT oF TeXt!!", 20, 400, 20, WHITE);
            rlDisableTexture();
        EndDrawing();
    }
    UnloadModel(model);
    CloseWindow();
    return 0;
}

static void ApplyRGBGradientToMesh(Mesh *mesh)
{
    if (!mesh || mesh->vertexCount <= 0 || !mesh->vertices) return;

    if (!mesh->colors) mesh->colors = (unsigned char *)MemAlloc(mesh->vertexCount * 4);

    float x0 = mesh->vertices[0];
    float y0 = mesh->vertices[1];
    float z0 = mesh->vertices[2];
    Vector3 min = { x0, y0, z0 };
    Vector3 max = { x0, y0, z0 };

    for (int i = 1; i < mesh->vertexCount; i++) {
        float x = mesh->vertices[i*3 + 0];
        float y = mesh->vertices[i*3 + 1];
        float z = mesh->vertices[i*3 + 2];
        if (x < min.x) min.x = x; if (x > max.x) max.x = x;
        if (y < min.y) min.y = y; if (y > max.y) max.y = y;
        if (z < min.z) min.z = z; if (z > max.z) max.z = z;
    }

    float rx = max.x - min.x; if (rx == 0.0f) rx = 1.0f;
    float ry = max.y - min.y; if (ry == 0.0f) ry = 1.0f;
    float rz = max.z - min.z; if (rz == 0.0f) rz = 1.0f;

    for (int i = 0; i < mesh->vertexCount; i++) {
        float x = mesh->vertices[i*3 + 0];
        float y = mesh->vertices[i*3 + 1];
        float z = mesh->vertices[i*3 + 2];

        float nx = (x - min.x) / rx;
        float ny = (y - min.y) / ry;
        float nz = (z - min.z) / rz;

        if (nx < 0) nx = 0; if (nx > 1) nx = 1;
        if (ny < 0) ny = 0; if (ny > 1) ny = 1;
        if (nz < 0) nz = 0; if (nz > 1) nz = 1;

        mesh->colors[i*4 + 0] = (unsigned char)(nx * 255.0f + 0.5f);
        mesh->colors[i*4 + 1] = (unsigned char)(ny * 255.0f + 0.5f);
        mesh->colors[i*4 + 2] = (unsigned char)(nz * 255.0f + 0.5f);
        mesh->colors[i*4 + 3] = 255;
    }
}


//TODO tomorrow you need to get the sphere and all the proper examples clean cut and working
// fix all the make stuff to be idempotent and finalize your PR and post on raylib aswell
// PR for ps2gl
// PR for raylib
// test more about this whole wire mesh and backface culling issue IN PS2!!!! and in raylib ofc