#define  IMGUI_DEFINE_MATH_OPERATORS
#include "imgui.h"
#include "imgui_internal.h"
#include "imgui_impl_dx9.h"
#include "imgui_impl_win32.h"
#include <d3d9.h>
#include <tchar.h>

#include "custom.hpp"
#include "bytes.hpp"

#include "imgui_freetype.hpp"

#include <d3dx9tex.h>
#pragma comment( lib, "d3dx9.lib" )

using namespace ImGui;

IDirect3DTexture9* background{ };

#define ALPHA    ( ImGuiColorEditFlags_AlphaPreview | ImGuiColorEditFlags_NoTooltip | ImGuiColorEditFlags_NoInputs | ImGuiColorEditFlags_NoLabel | ImGuiColorEditFlags_AlphaBar | ImGuiColorEditFlags_InputRGB | ImGuiColorEditFlags_Float      | ImGuiColorEditFlags_NoDragDrop   | ImGuiColorEditFlags_PickerHueBar | ImGuiColorEditFlags_NoBorder )
#define NO_ALPHA ( ImGuiColorEditFlags_NoTooltip    | ImGuiColorEditFlags_NoInputs  | ImGuiColorEditFlags_NoLabel  | ImGuiColorEditFlags_NoAlpha | ImGuiColorEditFlags_InputRGB | ImGuiColorEditFlags_Float    | ImGuiColorEditFlags_NoDragDrop | ImGuiColorEditFlags_PickerHueBar | ImGuiColorEditFlags_NoBorder )

// Data
static LPDIRECT3D9              g_pD3D = nullptr;
static LPDIRECT3DDEVICE9        g_pd3dDevice = nullptr;
static UINT                     g_ResizeWidth = 0, g_ResizeHeight = 0;
static D3DPRESENT_PARAMETERS    g_d3dpp = {};

// Forward declarations of helper functions
bool CreateDeviceD3D(HWND hWnd);
void CleanupDeviceD3D();
void ResetDevice();
LRESULT WINAPI WndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam);

// Main code
int main(int, char**)
{
    // Create application window
    //ImGui_ImplWin32_EnableDpiAwareness();
    WNDCLASSEXW wc = { sizeof(wc), CS_CLASSDC, WndProc, 0L, 0L, GetModuleHandle(nullptr), nullptr, nullptr, nullptr, nullptr, L"ImGui Example", nullptr };
    ::RegisterClassExW(&wc);
    HWND hwnd = ::CreateWindowW(wc.lpszClassName, L"Dear ImGui DirectX9 Example", WS_OVERLAPPEDWINDOW, 100, 100, 1280, 800, nullptr, nullptr, wc.hInstance, nullptr);

    // Initialize Direct3D
    if (!CreateDeviceD3D(hwnd))
    {
        CleanupDeviceD3D();
        ::UnregisterClassW(wc.lpszClassName, wc.hInstance);
        return 1;
    }

    // Show the window
    ::ShowWindow(hwnd, SW_SHOWDEFAULT);
    ::UpdateWindow(hwnd);

    // Setup Dear ImGui context
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;     // Enable Keyboard Controls
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad;      // Enable Gamepad Controls

    // Setup Dear ImGui style
    ImGui::StyleColorsDark();

    // Setup Platform/Renderer backends
    ImGui_ImplWin32_Init(hwnd);
    ImGui_ImplDX9_Init(g_pd3dDevice);

    // Load Fonts
    ImFontConfig font_config;
    font_config.PixelSnapH = false;
    font_config.OversampleH = 5;
    font_config.OversampleV = 5;
    font_config.RasterizerMultiply = 1.2f;

    static const ImWchar ranges[ ] = {

        0x0020, 0x00FF, // Basic Latin + Latin Supplement
        0x0400, 0x052F, // Cyrillic + Cyrillic Supplement
        0x2DE0, 0x2DFF, // Cyrillic Extended-A
        0xA640, 0xA69F, // Cyrillic Extended-B
        0xE000, 0xE226, // icons
        0,
    };

    font_config.GlyphRanges = ranges;

    io.Fonts->AddFontFromFileTTF( "C:\\Windows\\Fonts\\verdana.ttf", 12, &font_config, ranges );
    io.Fonts->AddFontFromFileTTF( "C:\\Windows\\Fonts\\verdanab.ttf", 12, &font_config, ranges );
    io.Fonts->AddFontFromMemoryTTF( icons_binary, sizeof icons_binary, 37, &font_config, ranges );

    // Our state
    ImVec4 clear_color = ImVec4(0.45f, 0.55f, 0.60f, 1.00f);

    // Main loop
    bool done = false;
    while (!done)
    {
        // Poll and handle messages (inputs, window resize, etc.)
        // See the WndProc() function below for our to dispatch events to the Win32 backend.
        MSG msg;
        while (::PeekMessage(&msg, nullptr, 0U, 0U, PM_REMOVE))
        {
            ::TranslateMessage(&msg);
            ::DispatchMessage(&msg);
            if (msg.message == WM_QUIT)
                done = true;
        }
        if (done)
            break;

        // Handle window resize (we don't resize directly in the WM_SIZE handler)
        if (g_ResizeWidth != 0 && g_ResizeHeight != 0)
        {
            g_d3dpp.BackBufferWidth = g_ResizeWidth;
            g_d3dpp.BackBufferHeight = g_ResizeHeight;
            g_ResizeWidth = g_ResizeHeight = 0;
            ResetDevice();
        }

        // Start the Dear ImGui frame
        ImGui_ImplDX9_NewFrame();
        ImGui_ImplWin32_NewFrame();
        ImGui::NewFrame();

        if ( !background )
            D3DXCreateTextureFromFileInMemoryEx( g_pd3dDevice, &background_binary, sizeof background_binary, 1920, 1080, D3DX_DEFAULT, 0, D3DFMT_UNKNOWN, D3DPOOL_MANAGED, D3DX_DEFAULT, D3DX_DEFAULT, 0, NULL, NULL, &background );

        static bool bools[50];
        static int ints[50];
        static float color[4] = { 1.f, 1.f, 1.f, 1.f };
        static char buf[64];
        vector < const char* > items = { "Head", "Neck", "Stomach", "Legs" };
        static bool multi[5];
        vector < ImColor > fade_colors = { ImColor( 12, 12, 12 ), ImColor( 55, 177, 218 ), ImColor( 201, 84, 192 ), ImColor( 204, 227, 54 ) };

        PushStyleVar( ImGuiStyleVar_WindowPadding, ImVec2( 0, 0 ) );
        PushStyleVar( ImGuiStyleVar_WindowMinSize, ImVec2( 500, 42 + ( 68 * custom.page_list.size( ) ) ) );

        ImGui::Begin( "Hello, world!", NULL, ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoCollapse ); {

            auto window = GetCurrentWindow( );
            auto draw   = window->DrawList;
            auto pos    = window->Pos;
            auto size   = window->Size;

            draw->AddRect( pos + ImVec2( 1, 1 ), pos + size - ImVec2( 1, 1 ), ImColor( 1.f, 1.f, 1.f, 0.1f ) );
            draw->AddRectFilled( pos + ImVec2( 2, 2 ), pos + size - ImVec2( 2, 2 ), GetColorU32( ImGuiCol_WindowBg ) );

            draw->AddImage( background, pos + ImVec2( 5, 5 ), pos + size - ImVec2( 5, 5 ) );
            draw->AddRect( pos + ImVec2( 5, 5 ), pos + size - ImVec2( 5, 5 ), ImColor( 1.f, 1.f, 1.f, 0.1f ) );

            draw->AddRectFilled( pos + ImVec2( 6, 6 ), pos + ImVec2( 75, 21 ), ImColor( 12, 12, 12 ) );
            draw->AddRectFilled( pos + ImVec2( 6, 21 + ( 68 * custom.page_list.size( ) ) ), pos + ImVec2( 75, size.y - 6 ), ImColor( 12, 12, 12 ) );
            draw->AddLine( pos + ImVec2( 75, 8 ), pos + ImVec2( 75, 21 ), ImColor( 1.f, 1.f, 1.f, 0.05f ) );
            draw->AddLine( pos + ImVec2( 74, 8 ), pos + ImVec2( 74, 21 ), GetColorU32( ImGuiCol_Border ) );
            draw->AddLine( pos + ImVec2( 75, 21 + ( 68 * custom.page_list.size( ) ) ), pos + ImVec2( 75, size.y - 6 ), ImColor( 1.f, 1.f, 1.f, 0.05f ) );
            draw->AddLine( pos + ImVec2( 74, 21 + ( 68 * custom.page_list.size( ) ) ), pos + ImVec2( 74, size.y - 6 ), GetColorU32( ImGuiCol_Border ) );

	        draw->AddRectFilledMultiColor( ImVec2( pos.x + 6, pos.y + 7 ), ImVec2( pos.x + size.x / 2 - 6, pos.y + 9 ), fade_colors.at( 0 ), fade_colors.at( 0 ), fade_colors.at( 0 ), fade_colors.at( 0 ) );
	        draw->AddRectFilledMultiColor( ImVec2( pos.x + 6 + size.x / 2, pos.y + 7 ), ImVec2( pos.x + size.x - 7, pos.y + 9 ), fade_colors.at( 0 ), fade_colors.at( 0 ), fade_colors.at( 0 ), fade_colors.at( 0 ) );
                                                   
	        draw->AddRectFilledMultiColor( ImVec2( pos.x + 7, pos.y + 8 ), ImVec2( pos.x + size.x / 2 + 6, pos.y + 10 ), fade_colors.at( 1 ), fade_colors.at( 2 ), fade_colors.at( 2 ), fade_colors.at( 1 ) );
	        draw->AddRectFilledMultiColor( ImVec2( pos.x + size.x / 2 + 6, pos.y + 8 ), ImVec2( pos.x + size.x - 7, pos.y + 10 ), fade_colors.at( 2 ), fade_colors.at( 3 ), fade_colors.at( 3 ), fade_colors.at( 2 ) );
                                                   
	        draw->AddRectFilledMultiColor( ImVec2( pos.x + 7, pos.y + 9 ), ImVec2( pos.x + size.x / 2 + 6, pos.y + 11 ), ImColor( 0.f, 0.f, 0.f, 0.43f ), ImColor( 0.f, 0.f, 0.f, 0.43f ), ImColor( 0.f, 0.f, 0.f, 0.43f ), ImColor( 0.f, 0.f, 0.f, 0.43f ) );
	        draw->AddRectFilledMultiColor( ImVec2( pos.x + size.x / 2 + 6, pos.y + 9 ), ImVec2( pos.x + size.x - 7, pos.y + 11 ), ImColor( 0.f, 0.f, 0.f, 0.43f ), ImColor( 0.f, 0.f, 0.f, 0.43f ), ImColor( 0.f, 0.f, 0.f, 0.43f ), ImColor( 0.f, 0.f, 0.f, 0.43f ) );

            SetCursorPos( ImVec2( 6, 21 ) );
            PushStyleVar( ImGuiStyleVar_ItemSpacing, ImVec2( 0, 0 ) );
            BeginGroup( );

            for ( int i = 0; i < custom.page_list.size( ); ++i )
                if ( custom.tab( custom.page_list.at( i ), custom.page == i ) )
                    custom.page = i;

            EndGroup( );
            PopStyleVar( );

            PushStyleVar( ImGuiStyleVar_ItemSpacing, ImVec2( 10, 10 ) );
            PushStyleVar( ImGuiStyleVar_WindowPadding, ImVec2( 0, 8 ) );

            SetCursorPos( ImVec2( 90, 25 - GetStyle( ).WindowPadding.y ) );
            BeginChild( "##Groups", ImVec2( size.x - 105, size.y - 40 + GetStyle( ).WindowPadding.y ), 0, ImGuiWindowFlags_AlwaysUseWindowPadding | ImGuiWindowFlags_NoScrollbar );

            switch ( custom.page ) {
            case 0:

                custom.group_box( "Main", ImVec2( GetWindowWidth( ) / 2 - GetStyle( ).ItemSpacing.x / 2, GetWindowHeight( ) / 2 - GetStyle( ).ItemSpacing.y / 2 - GetStyle( ).WindowPadding.y ) ); {

                    Checkbox( "Enabled", &bools[0] );
                    SliderInt( "Slider", &ints[0], 0, 100, "%d%%" );
                    Checkbox( "Hide shots", &bools[1] );
                    Checkbox( "Special", &bools[2], 1 );
                    Combo( "Hitbox", &ints[1], items.data( ), items.size( ) );
                    MultiCombo( "Multi", multi, items.data( ), items.size( ) );
                    Button( "Button", ImVec2( GetWindowWidth( ) - 90, 25 ) );
                    Hotkey( "Hotkey", &ints[2] );

                } custom.end_group_box( );

                custom.group_box( "Secondary", ImVec2( GetWindowWidth( ) / 2 - GetStyle( ).ItemSpacing.x / 2, GetWindowHeight( ) / 2 - GetStyle( ).ItemSpacing.y / 2 - GetStyle( ).WindowPadding.y ) ); {

                    for ( int i = 0; i < 50; ++i )
                        Text( std::to_string( i ).c_str( ) );

                } custom.end_group_box( );

                SameLine( ), SetCursorPosY( GetStyle( ).WindowPadding.y );

                custom.group_box( "Miscellaneous", ImVec2( GetWindowWidth( ) / 2 - GetStyle( ).ItemSpacing.x / 2, GetWindowHeight( ) - GetStyle( ).WindowPadding.y * 2 ) ); {

                    Checkbox( "Color", &bools[3] );
                    SameLine( GetWindowWidth( ) - 54 );
                    ColorEdit4( "##color", color, ALPHA );
                    InputText( "Text field", buf, sizeof buf );

                } custom.end_group_box( );

                break;

            case 1:

                custom.group_box( "General", ImVec2( GetWindowWidth( ) / 2 - GetStyle( ).ItemSpacing.x / 2, GetWindowHeight( ) - GetStyle( ).WindowPadding.y * 2 ) ); {

                } custom.end_group_box( );

                SameLine( ), SetCursorPosY( GetStyle( ).WindowPadding.y );

                custom.group_box( "Pitch", ImVec2( GetWindowWidth( ) / 2 - GetStyle( ).ItemSpacing.x / 2, GetWindowHeight( ) - GetStyle( ).WindowPadding.y * 2 ) ); {

                } custom.end_group_box( );

                break;
            }

            EndChild( );

            PopStyleVar( 2 );

        } ImGui::End( );

        PopStyleVar( 2 );

        // Rendering
        ImGui::EndFrame();
        g_pd3dDevice->SetRenderState(D3DRS_ZENABLE, FALSE);
        g_pd3dDevice->SetRenderState(D3DRS_ALPHABLENDENABLE, FALSE);
        g_pd3dDevice->SetRenderState(D3DRS_SCISSORTESTENABLE, FALSE);
        D3DCOLOR clear_col_dx = D3DCOLOR_RGBA((int)(clear_color.x*clear_color.w*255.0f), (int)(clear_color.y*clear_color.w*255.0f), (int)(clear_color.z*clear_color.w*255.0f), (int)(clear_color.w*255.0f));
        g_pd3dDevice->Clear(0, nullptr, D3DCLEAR_TARGET | D3DCLEAR_ZBUFFER, clear_col_dx, 1.0f, 0);
        if (g_pd3dDevice->BeginScene() >= 0)
        {
            ImGui::Render();
            ImGui_ImplDX9_RenderDrawData(ImGui::GetDrawData());
            g_pd3dDevice->EndScene();
        }
        HRESULT result = g_pd3dDevice->Present(nullptr, nullptr, nullptr, nullptr);

        // Handle loss of D3D9 device
        if (result == D3DERR_DEVICELOST && g_pd3dDevice->TestCooperativeLevel() == D3DERR_DEVICENOTRESET)
            ResetDevice();
    }

    ImGui_ImplDX9_Shutdown();
    ImGui_ImplWin32_Shutdown();
    ImGui::DestroyContext();

    CleanupDeviceD3D();
    ::DestroyWindow(hwnd);
    ::UnregisterClassW(wc.lpszClassName, wc.hInstance);

    return 0;
}

// Helper functions

bool CreateDeviceD3D(HWND hWnd)
{
    if ((g_pD3D = Direct3DCreate9(D3D_SDK_VERSION)) == nullptr)
        return false;

    // Create the D3DDevice
    ZeroMemory(&g_d3dpp, sizeof(g_d3dpp));
    g_d3dpp.Windowed = TRUE;
    g_d3dpp.SwapEffect = D3DSWAPEFFECT_DISCARD;
    g_d3dpp.BackBufferFormat = D3DFMT_UNKNOWN; // Need to use an explicit format with alpha if needing per-pixel alpha composition.
    g_d3dpp.EnableAutoDepthStencil = TRUE;
    g_d3dpp.AutoDepthStencilFormat = D3DFMT_D16;
    g_d3dpp.PresentationInterval = D3DPRESENT_INTERVAL_ONE;           // Present with vsync
    //g_d3dpp.PresentationInterval = D3DPRESENT_INTERVAL_IMMEDIATE;   // Present without vsync, maximum unthrottled framerate
    if (g_pD3D->CreateDevice(D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, hWnd, D3DCREATE_HARDWARE_VERTEXPROCESSING, &g_d3dpp, &g_pd3dDevice) < 0)
        return false;

    return true;
}

void CleanupDeviceD3D()
{
    if (g_pd3dDevice) { g_pd3dDevice->Release(); g_pd3dDevice = nullptr; }
    if (g_pD3D) { g_pD3D->Release(); g_pD3D = nullptr; }
}

void ResetDevice()
{
    ImGui_ImplDX9_InvalidateDeviceObjects();
    HRESULT hr = g_pd3dDevice->Reset(&g_d3dpp);
    if (hr == D3DERR_INVALIDCALL)
        IM_ASSERT(0);
    ImGui_ImplDX9_CreateDeviceObjects();
}

// Forward declare message handler from imgui_impl_win32.cpp
extern IMGUI_IMPL_API LRESULT ImGui_ImplWin32_WndProcHandler(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam);

// Win32 message handler
// You can read the io.WantCaptureMouse, io.WantCaptureKeyboard flags to tell if dear imgui wants to use your inputs.
// - When io.WantCaptureMouse is true, do not dispatch mouse input data to your main application, or clear/overwrite your copy of the mouse data.
// - When io.WantCaptureKeyboard is true, do not dispatch keyboard input data to your main application, or clear/overwrite your copy of the keyboard data.
// Generally you may always pass all inputs to dear imgui, and hide them from your application based on those two flags.
LRESULT WINAPI WndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    if (ImGui_ImplWin32_WndProcHandler(hWnd, msg, wParam, lParam))
        return true;

    switch (msg)
    {
    case WM_SIZE:
        if (wParam == SIZE_MINIMIZED)
            return 0;
        g_ResizeWidth = (UINT)LOWORD(lParam); // Queue resize
        g_ResizeHeight = (UINT)HIWORD(lParam);
        return 0;
    case WM_SYSCOMMAND:
        if ((wParam & 0xfff0) == SC_KEYMENU) // Disable ALT application menu
            return 0;
        break;
    case WM_DESTROY:
        ::PostQuitMessage(0);
        return 0;
    }
    return ::DefWindowProcW(hWnd, msg, wParam, lParam);
}
