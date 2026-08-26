#pragma once

#define  IMGUI_DEFINE_MATH_OPERATORS
#include "imgui.h"
#include "imgui_internal.h"

#include <vector>

#include <string>
#include <unordered_map>

#include <d3dx9tex.h>
#pragma comment( lib, "d3dx9.lib" )

using namespace std;

#define to_vec4( r, g, b, a ) ImColor( r / 255.f, g / 255.f, b / 255.f, a )

class c_custom {
private:
	int accent_c[4] = { 141, 188, 0, 255 };

public:

	int page = 0;
    vector < const char* > page_list = { "C", "B", "D", "E", "F", "G" };

    void render_arrows_for_horizontal_bar( ImVec2 pos, float alpha, float width, float height );

    bool tab( const char* name, bool cur );

    void group_box( const char* name, ImVec2 size );
    void end_group_box( );

	ImColor get_accent_color( float a = 1.f ) {
		return to_vec4( accent_c[0], accent_c[1], accent_c[2], a );
	}
};

inline c_custom custom;
