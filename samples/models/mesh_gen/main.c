/*******************************************************************************************
*
*   raylib [models] example - mesh generation
*
*   Example complexity rating: [★★☆☆] 2/4
*
*   Example originally created with raylib 1.8, last time updated with raylib 4.0
*
*   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
*   BSD-like license that allows static linking with closed source software
*
*   Copyright (c) 2017-2025 Ramon Santamaria (@raysan5)
*
********************************************************************************************/

#include "raylib.h"
#include "rlgl.h"

#define NUM_MODELS  9               // Parametric 3d shapes to generate

int main(void)
{
    const int screenWidth = 800;
    const int screenHeight = 450;

    InitWindow(screenWidth, screenHeight, "raylib [models] example - mesh generation");
    // tsLoadFont();

    Image checked = GenImageChecked(2, 2, 1, 1, RED, GREEN);
    Texture2D texture = LoadTextureFromImage(checked);
    SetTextureWrap(texture, TEXTURE_WRAP_REPEAT);
    UnloadImage(checked);

    Model models[NUM_MODELS] = { 0 };

    models[0] = LoadModelFromMesh(GenMeshPlane(2, 2, 4, 3));
    models[1] = LoadModelFromMesh(GenMeshCube(2.0f, 1.0f, 2.0f));
    models[2] = LoadModelFromMesh(GenMeshSphere(2, 32, 32));
    models[3] = LoadModelFromMesh(GenMeshHemiSphere(2, 16, 16));
    models[4] = LoadModelFromMesh(GenMeshCylinder(1, 2, 16));
    models[5] = LoadModelFromMesh(GenMeshTorus(0.25f, 4.0f, 16, 32));
    models[6] = LoadModelFromMesh(GenMeshKnot(1.0f, 2.0f, 16, 128));
    models[7] = LoadModelFromMesh(GenMeshPoly(5, 2.0f));

    for (int i = 0; i < NUM_MODELS; i++) models[i].materials[0].maps[MATERIAL_MAP_DIFFUSE].texture = texture;
    Camera camera = { { 5.0f, 5.0f, 5.0f }, { 0.0f, 0.0f, 0.0f }, { 0.0f, 1.0f, 0.0f }, 40.0f, 0 };
    Vector3 position = { 0.0f, 0.0f, 0.0f };
    int currentModel = 0;
    SetTargetFPS(60);
    while (!WindowShouldClose()) {

        UpdateCamera(&camera, CAMERA_ORBITAL);

        if (IsGamepadAvailable(0) && IsGamepadButtonPressed(0, GAMEPAD_BUTTON_RIGHT_FACE_DOWN)) {
            currentModel = (currentModel + 1)%NUM_MODELS; // Cycle between the textures
        }

        if (IsGamepadAvailable(0) && IsGamepadButtonPressed(0, GAMEPAD_BUTTON_LEFT_FACE_RIGHT)) {
            currentModel++;
            if (currentModel >= NUM_MODELS) currentModel = 0;
        }
        else if (IsGamepadAvailable(0) && IsGamepadButtonPressed(0, GAMEPAD_BUTTON_LEFT_FACE_LEFT)) {
            currentModel--;
            if (currentModel < 0) currentModel = NUM_MODELS - 1;
        }
        BeginDrawing();

            ClearBackground(RAYWHITE);

            BeginMode3D(camera);
               // rlDisableColorBlend();
               DrawModel(models[currentModel], position, 1.0f, WHITE);
               DrawGrid(10, 1.0);
            EndMode3D();

            rlEnableColorBlend();
        DrawRectangle(30, 400, 360, 30, Fade(SKYBLUE, 0.5f));
        DrawRectangleLines(30, 400, 360, 30, Fade(DARKBLUE, 0.5f));
        DrawText("CONTROLLER LEFT BUTTON to CYCLE PROCEDURAL MODELS", 40, 410, 10, BLUE);

            switch (currentModel)
            {
            case 0: DrawText("PLANE", 500, 10, 20, DARKBLUE); break;
            case 1: DrawText("CUBE", 500, 10, 20, DARKBLUE); break;
            case 2: DrawText("SPHERE", 500, 10, 20, DARKBLUE); break;
            case 3: DrawText("HEMISPHERE", 500, 10, 20, DARKBLUE); break;
            case 4: DrawText("CYLINDER", 500, 10, 20, DARKBLUE); break;
            case 5: DrawText("TORUS", 500, 10, 20, DARKBLUE); break;
            case 6: DrawText("KNOT", 500, 10, 20, DARKBLUE); break;
            case 7: DrawText("POLY", 500, 10, 20, DARKBLUE); break;
            default: break;
            }

        EndDrawing();
    }
    UnloadTexture(texture);
    for (int i = 0; i < NUM_MODELS; i++) UnloadModel(models[i]);

    CloseWindow();
    return 0;
}
