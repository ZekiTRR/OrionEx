#include "custom.hpp"
using namespace ImGui;

void c_custom::render_arrows_for_horizontal_bar( ImVec2 pos, float alpha, float width, float height ) {

    auto draw = GetWindowDrawList( );
    draw->AddRectFilled( pos, pos + ImVec2( width, height ), ImColor( 1.f, 1.f, 1.f, 0.4f * ( alpha * GetStyle( ).Alpha ) ) );
    draw->AddRect( pos, pos + ImVec2( width, height ), GetColorU32( ImGuiCol_Border ) );
}

bool c_custom::tab( const char* name, bool cur ) {

    auto window = GetCurrentWindow( );
    auto id = window->GetID( name );

    auto pos = window->DC.CursorPos;
    auto draw = window->DrawList;

    auto name_size = GetIO( ).Fonts->Fonts[2]->CalcTextSizeA( GetIO( ).Fonts->Fonts[2]->FontSize, FLT_MAX, 0, name );

    ImRect bb( pos, pos + ImVec2( 68, 68 ) );
    ItemAdd( bb, id );
    ItemSize( bb, GetStyle( ).FramePadding.y );

    bool hovered, held;
    bool pressed = ButtonBehavior( bb, id, &hovered, &held );

    if ( !cur ) {

        draw->AddRectFilled( bb.Min, bb.Max, to_vec4( 12, 12, 12, GetStyle( ).Alpha ) );
        draw->AddLine( ImVec2( bb.Max.x, bb.Min.y ), bb.Max, GetColorU32( ImGuiCol_Border ) );
        draw->AddLine( ImVec2( bb.Max.x + 1, bb.Min.y ), bb.Max + ImVec2( 1, 0 ), ImColor( 1.f, 1.f, 1.f, 0.05f * GetStyle( ).Alpha ) );
    }

    if ( cur ) {

        draw->AddLine( bb.Min, ImVec2( bb.Max.x + 1, bb.Min.y ), GetColorU32( ImGuiCol_Border ) );
        draw->AddLine( bb.Min + ImVec2( 0, 1 ), ImVec2( bb.Max.x + 1, bb.Min.y + 1 ), ImColor( 1.f, 1.f, 1.f, 0.05f * GetStyle( ).Alpha ) );

        draw->AddLine( ImVec2( bb.Min.x, bb.Max.y - 1 ), bb.Max - ImVec2( -1, 1 ), GetColorU32( ImGuiCol_Border ) );
        draw->AddLine( ImVec2( bb.Min.x, bb.Max.y - 2 ), bb.Max - ImVec2( -1, 2 ), ImColor( 1.f, 1.f, 1.f, 0.05f * GetStyle( ).Alpha ) );
    }

    draw->AddText( GetIO( ).Fonts->Fonts[2], GetIO( ).Fonts->Fonts[2]->FontSize, bb.GetCenter( ) - name_size / 2, GetColorU32( ImGuiCol_Text, cur ? 0.9f : hovered ? 0.5f : 0.25f ), name );

    return pressed;
}

struct group_box_ {

    ImVec2 size;
    bool held, hovered, calculate_height;
};

void c_custom::group_box( const char* name, ImVec2 size ) {

    ImGuiWindow* window = GetCurrentWindow( );
    ImVec2 pos = window->DC.CursorPos;

    auto name_size = GetIO( ).Fonts->Fonts[1]->CalcTextSizeA( GetIO( ).Fonts->Fonts[1]->FontSize, FLT_MAX, 0.f, name );

    static std::unordered_map < std::string, group_box_ > values;
    auto value = values.find( std::string( name ).append( ".size" ) );
    if ( value == values.end( ) ) {

        values.insert( { std::string( name ).append( ".size" ), { size, false, false, true } } );
        value = values.find( std::string( name ).append( ".size" ) );
    }

    value->second.size.x = size.x;

    if ( value->second.calculate_height )
        value->second.size.y = size.y;

    ImRect resize_grip( pos + value->second.size - ImVec2( 8, 8 ), pos + value->second.size - ImVec2( 2, 2 ) );

    if ( IsMouseHoveringRect( resize_grip.Min, resize_grip.Max ) ) {

        value->second.hovered = true;

        if ( IsMouseClicked( ImGuiMouseButton_Left ) )
            value->second.held = true, value->second.calculate_height = false;
    } else {

        value->second.hovered = false;

        if ( IsMouseClicked( ImGuiMouseButton_Left ) )
            value->second.held = false;
    }

    if ( value->second.held ) {

        if ( value->second.size.y < 60 )
            value->second.held = false, value->second.size.y = 70;
        else
            value->second.size.y = GetMousePos( ).y - pos.y;
    }

    if ( value->second.hovered && IsMouseClicked( ImGuiMouseButton_Right ) )
        OpenPopup( std::string( name ).append( ".popup" ).c_str( ) );

    PushStyleColor( ImGuiCol_PopupBg, ImVec4( ImColor( 34, 33, 34 ) ) );
    PushStyleVar( ImGuiStyleVar_WindowPadding, ImVec2( 3, 6 ) );

    SetNextWindowSize( ImVec2( 110, 25 ) );
    if ( BeginPopup( std::string( name ).append( ".popup" ).c_str( ), ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoMove ) ) {

        if ( Selectable( "Calculate height", value->second.calculate_height, 0, GetWindowSize( ) - GetStyle( ).WindowPadding * 2 ) )
            value->second.calculate_height = !value->second.calculate_height;
        
        EndPopup( );
    }

    PopStyleVar( );
    PopStyleColor( );

    BeginChild( std::string( name ).append( ".main" ).c_str( ), value->second.size, 0, ImGuiWindowFlags_NoScrollbar );

    window->DrawList->AddRectFilled( pos, pos + value->second.size, to_vec4( 23, 23, 23, GetStyle( ).Alpha ) );
    window->DrawList->AddRect( pos, pos + value->second.size, GetColorU32( ImGuiCol_Border, 0.43f ) );
    window->DrawList->AddRect( pos + ImVec2( 1, 1 ), pos + value->second.size - ImVec2( 1, 1 ), value->second.held ? custom.get_accent_color( GetStyle( ).Alpha ) : ImColor( 1.f, 1.f, 1.f, 0.1f * GetStyle( ).Alpha ) );
    window->DrawList->AddLine( pos + ImVec2( 8, 0 ), pos + ImVec2( 16 + name_size.x, 0 ), to_vec4( 23, 23, 23, GetStyle( ).Alpha ), 2 );

    window->DrawList->AddText( GetIO( ).Fonts->Fonts[1], GetIO( ).Fonts->Fonts[1]->FontSize, pos + ImVec2( 13, -( name_size.y / 2 ) + 2 ), ImColor( 0.f, 0.f, 0.f, 0.43f * GetStyle( ).Alpha ), name, FindRenderedTextEnd( name ) );
    window->DrawList->AddText( GetIO( ).Fonts->Fonts[1], GetIO( ).Fonts->Fonts[1]->FontSize, pos + ImVec2( 12, -( name_size.y / 2 ) + 1 ), GetColorU32( ImGuiCol_Text ), name, FindRenderedTextEnd( name ) );

    window->DrawList->AddTriangleFilled( ImVec2( resize_grip.Min.x, resize_grip.Max.y ), ImVec2( resize_grip.Max.x, resize_grip.Min.y ), resize_grip.Max, value->second.held ? custom.get_accent_color( GetStyle( ).Alpha ) : ImColor( 0.2f, 0.2f, 0.2f, GetStyle( ).Alpha ) );

    PushStyleVar( ImGuiStyleVar_WindowPadding, { 0, 12 } );

    SetCursorPosY( 2 );
    BeginChild( name, { value->second.size.x, value->second.size.y - 4 }, 0, ImGuiWindowFlags_AlwaysUseWindowPadding );
    SetCursorPosX( 17 );

    if ( GetCurrentWindow( )->ScrollbarY ) {

        if ( GetCurrentWindow( )->Scroll.y <= GetCurrentWindow( )->ScrollMax.y - 2 )
            RenderArrow( window->DrawList, pos + ImVec2( value->second.size.x - 22, value->second.size.y - 12 ), GetColorU32( ImGuiCol_Text ), ImGuiDir_Down, 0.65f );
        if ( GetCurrentWindow( )->Scroll.y )
            RenderArrow( window->DrawList, pos + ImVec2( value->second.size.x - 22, 5 ), GetColorU32( ImGuiCol_Text ), ImGuiDir_Up, 0.65f );
    }

    BeginGroup( );

    PushStyleVar( ImGuiStyleVar_ItemSpacing, { 8, 8 } );
}

void c_custom::end_group_box( ) {

    PopStyleVar( 2 );
    EndGroup( );
    EndChild( );
    EndChild( );
}
