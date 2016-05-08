//!
//! Copyright 2015 by Garmin Ltd. or its subsidiaries.
//! Subject to Garmin SDK License Agreement and Wearables
//! Application Developer Agreement.
//!

using Toybox.ActivityMonitor as Act;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Math as Math;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;
using Toybox.WatchUi as Ui;
using Toybox.Application as App;

//! This implements an analog watch face
//! Original design by Austen Harbour
class DrawDialsFace extends Ui.WatchFace
{
    var font;
    var battery_icon ;
    var steps_icon ;
    var highPowerMode = false;
    var debug = false;
    var deg2rad = Math.PI/180;
    var CLOCKWISE = -1;
    var COUNTERCLOCKWISE = 1;
    var radius = 0;
    var counter =0;
    var MAX_DIALS = 2;
    var screen_width = 0 ;
    var screen_height = 0 ;
    var icon_size = "large";
    var SCREEN_UNKNOWN = -1;
    var SCREEN_ROUND = 0;
    var SCREEN_SEMI_ROUND = 1;
    var screen_type = SCREEN_UNKNOWN;

    //! Constructor
    function initialize()
    {
    }

    //! Load resources
    function onLayout()
    {
        font = Ui.loadResource(Rez.Fonts.id_font_black_diamond);
        battery_icon = Ui.loadResource(Rez.Drawables.battery_id);
        steps_icon = Ui.loadResource(Rez.Drawables.steps_id);
        icon_size = Ui.loadResource(Rez.Strings.id_icon_size);
    }

    function onShow()
    {
    }

    //! Nothing to do when going away
    function onHide()
    {
    }

    function drawTriangleFromMin(dc, min, width, inner, length, colour)
    {
        var angle  = ( min / 60.0) * Math.PI * 2;
        drawTriangle(dc, angle, width, inner, length,colour);
    }

    function adjustSemiRound(xvalue) {
        if (screen_type == SCREEN_SEMI_ROUND) {
            return (1.0 * xvalue * (170.0 / 218.0));
        }
        return xvalue;
    }
    function drawTriangle(dc, angle, width, inner, length, colour)
    {
        // Map out the coordinates
        var coords = [ [0,-inner], [-(adjustSemiRound(width)/2), -length], [adjustSemiRound(width)/2, -length] ];
        var result = new [3];
        var centerX = screen_width/2;
        var centerY = screen_height /2;
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);

        // Transform the coordinates
        for (var i = 0; i < 3; i += 1)
        {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin);
            var y = (coords[i][0] * sin) + (coords[i][1] * cos);
            result[i] = [ centerX+x, centerY+y];
        }

        // Draw the polygon
        dc.setColor(colour,colour);
        dc.fillPolygon(result);
    }

    function drawLineFromMin(dc, min, width, inner, length, colour)
    {
        var angle = (min / 60.0) * Math.PI * 2;
        // Map out the coordinates
        var coords = [ [0,-inner], [0, -length] ];
        var result = new [2];
        var centerX = screen_width/2;
        var centerY = screen_height /2;
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);

        // Transform the coordinates
        for (var i = 0; i < 2; i += 1)
        {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin);
            var y = (coords[i][0] * sin) + (coords[i][1] * cos);
            result[i] = [ centerX+x, centerY+y];
        }

        // Draw the Line
        dc.setColor(colour,colour);
        dc.drawLine(result[0][0],result[0][1],result[1][0],result[1][1]);
    }

    function drawBlockFromMin(dc, min, width, inner, length, colour)
    {
        var angle = (min / 60.0) * Math.PI * 2;
        dc.setColor(colour,colour);
        drawBlock(dc, angle, width, inner, length, colour);
    }

    function drawBlock(dc, angle, width, inner, length, colour)
    {
        // Map out the coordinates
        var coords = [ [-(adjustSemiRound(width)/2),-inner], [-(adjustSemiRound(width)/2), -length], [adjustSemiRound(width)/2, -length], [adjustSemiRound(width)/2, -inner] ];
        var result = new [4];
        var centerX = radius;
        var centerY = radius;
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);

        // Transform the coordinates
        for (var i = 0; i < 4; i += 1)
        {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin);
            var y = (coords[i][0] * sin) + (coords[i][1] * cos);
            result[i] = [ centerX+x, centerY+y];
        }

        // Draw the polygon
        dc.setColor(colour,colour);
        dc.fillPolygon(result);
    }

    function drawTwelve(dc)
    {
        drawTriangle(dc, 0, 30, radius-49, radius-12, Gfx.COLOR_LT_GRAY);
        drawTriangle(dc, 0, 23, radius-44, radius-14, Gfx.COLOR_WHITE);
        if (Sys.getDeviceSettings().phoneConnected)
        {
            drawTriangle(dc, 0,  12, radius-39, radius-17, Gfx.COLOR_BLUE);
        }
        else
        {
            dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
            dc.drawText(radius, 10 , Gfx.FONT_MEDIUM, "!", Gfx.TEXT_JUSTIFY_CENTER);
        }
    }

   // Draw an arc with polygons
   // https://forums.garmin.com/showthread.php?231881-Arc-Function&p=568317#post568317
    function drawPolygonArc(dc, x, y, radius, thickness, angle, offsetIn, color, direction){

       drawPolygonArcEllipse(dc, x, y, thickness, angle, offsetIn, color, direction);
    }
    function drawPolygonArcEllipse(dc, x, y,  thickness, angle, offsetIn, color, direction){
        var xradius = radius;
        var yradius = radius;
        var curAngle;
        direction = direction*-1;
        var ptCnt = 30;
        thickness = adjustSemiRound(thickness);

        if(angle > 0f){
          var pts = new [ptCnt*2+2];
          var offset = 90f*direction+offsetIn;
          var dec = angle / ptCnt.toFloat();
          for(var i=0,angle=0; i <= ptCnt; angle+=dec){
            curAngle = direction*(angle-offset)*deg2rad;
            pts[i] = [x+xradius*Math.cos(curAngle), y+yradius*Math.sin(curAngle)];
            i++;
          }
          for(var i=ptCnt+1; i <= ptCnt*2+1; angle-=dec){
            curAngle = direction*(angle-offset)*deg2rad;
            pts[i] = [x+(xradius-thickness)*Math.cos(curAngle), y+(yradius-thickness)*Math.sin(curAngle)];
            i++;
          }
          dc.setColor(color,Gfx.COLOR_TRANSPARENT);
          dc.fillPolygon(pts);
        }
    }

    function onExitSleep()
    {
        highPowerMode = true;
        Ui.requestUpdate();
    }

    function onEnterSleep()
    {
        highPowerMode = false;
        Ui.requestUpdate();
    }

    // ============================================================
    // Draw Wedge from outer circle to inner circle
    // ============================================================
    function drawWedge(dc, min, width, insetFromRad, length, colour)
    {
        var center_angle = 180f -min * 6;
        width = width * 6; // (width measured in minutes i.e. 6deg)
        insetFromRad = adjustSemiRound(insetFromRad);
        length = adjustSemiRound(length);

        var startangle = (center_angle-width/2) ;
        var endangle = (center_angle+width/2) ;
        var outside_radius = radius - insetFromRad;
        var inside_radius = outside_radius - length;

        var xcenter = screen_width/2;
        var ycenter = screen_height /2;

//System.println("xradius " + screen_width/2);
//System.println("yradius " + screen_height /2);

        var outside_startx = xcenter + (outside_radius) * Math.sin(startangle*deg2rad);
        var outside_starty = ycenter + (outside_radius) * Math.cos(startangle*deg2rad);
        var outside_endx = xcenter + (outside_radius) * Math.sin(  endangle*deg2rad);
        var outside_endy = ycenter + (outside_radius) * Math.cos(  endangle*deg2rad);
        var inside_startx = xcenter + (inside_radius) * Math.sin(startangle*deg2rad);
        var inside_starty = ycenter + (inside_radius) * Math.cos(startangle*deg2rad);
        var inside_endx = xcenter + (inside_radius) * Math.sin(  endangle*deg2rad);
        var inside_endy = ycenter + (inside_radius) * Math.cos(  endangle*deg2rad);
        // Map out the coordinates
        var coords = [ [inside_startx, inside_starty], [outside_startx, outside_starty], [outside_endx,outside_endy], [inside_endx,inside_endy] ];

        // Draw the polygon
        dc.setColor(colour,colour);
        dc.fillPolygon(coords);
    }

    // ============================================================
    // Function to rebuild the background which can be saved to png
    // ============================================================
    function drawFenix3BackgroundElegant(dc)
    {
        drawCommonBackground(dc);

        // ============================================================
        // Draw the minute marks

        drawWedge(dc, 0, 0.51, 0, 8, Gfx.COLOR_WHITE);
        drawWedge(dc, 5, 0.51, 0, 26, Gfx.COLOR_WHITE);
        drawWedge(dc,10, 0.51, 0, 26, Gfx.COLOR_WHITE);
        drawWedge(dc,15, 0.51, 0, 8, Gfx.COLOR_WHITE);
        drawWedge(dc,20, 0.51, 0, 26, Gfx.COLOR_WHITE);
        drawWedge(dc,25, 0.51, 0, 26, Gfx.COLOR_WHITE);
        drawWedge(dc,30, 0.51, 0, 8, Gfx.COLOR_WHITE);
        drawWedge(dc,35, 0.51, 0, 26, Gfx.COLOR_WHITE);
        drawWedge(dc,40, 0.51, 0, 26, Gfx.COLOR_WHITE);
        drawWedge(dc,45, 0.51, 0, 8, Gfx.COLOR_WHITE);
        drawWedge(dc,50, 0.51, 0, 26, Gfx.COLOR_WHITE);
        drawWedge(dc,55, 0.51, 0, 26, Gfx.COLOR_WHITE);

        var c;
        for (c=0; c<5; c++) { drawLineFromMin(dc,1+c,2,radius-6 ,radius,Gfx.COLOR_WHITE); }
        for (c=0; c<5; c++) { drawLineFromMin(dc,6+c,2,radius-6,radius,Gfx.COLOR_WHITE); }
        for (c=0; c<5; c++) { drawLineFromMin(dc,11+c,2,radius-6,radius,Gfx.COLOR_WHITE); }
        for (c=0; c<5; c++) { drawLineFromMin(dc,16+c,2,radius-6,radius,Gfx.COLOR_WHITE); }
        for (c=0; c<5; c++) { drawLineFromMin(dc,21+c,2,radius-6,radius,Gfx.COLOR_WHITE); }
        for (c=0; c<5; c++) { drawLineFromMin(dc,26+c,2,radius-6,radius,Gfx.COLOR_WHITE); }
        for (c=0; c<5; c++) { drawLineFromMin(dc,31+c,2,radius-6,radius,Gfx.COLOR_WHITE); }
        for (c=0; c<5; c++) { drawLineFromMin(dc,36+c,2,radius-6,radius,Gfx.COLOR_WHITE); }
        for (c=0; c<5; c++) { drawLineFromMin(dc,41+c,2,radius-6,radius,Gfx.COLOR_WHITE); }
        for (c=0; c<5; c++) { drawLineFromMin(dc,46+c,2,radius-6,radius,Gfx.COLOR_WHITE); }
        for (c=0; c<5; c++) { drawLineFromMin(dc,51+c,2,radius-6,radius,Gfx.COLOR_WHITE); }
        for (c=0; c<5; c++) { drawLineFromMin(dc,56+c,2,radius-6,radius,Gfx.COLOR_WHITE); }
        // Draw the steps icon
//        dc.drawBitmap(width* 0.70+4, height*.65,steps);
    }
    // ============================================================
    // Function to rebuild the background which can be saved to png
    // ============================================================

    function drawCommonBackground(dc)
    {
//        radius = height/2;

        // ============================================================
        // Draw the Battery icon
        var batt_icon_x = screen_width*0.24;
        var batt_icon_y = screen_height*0.24;

        if (icon_size.equals("small") ) {
            batt_icon_x = screen_width*0.28;
            batt_icon_y = screen_height*0.23;
        }

        dc.setColor( Gfx.COLOR_GREEN,Gfx.COLOR_GREEN);
        dc.drawBitmap(   batt_icon_x, batt_icon_y, battery_icon);
 //       dc.drawRectangle(batt_icon_x-1 , batt_icon_y-2 ,30, 22);

        // ============================================================
        // Draw the step icon
        var step_icon_x = screen_width*0.65;
        var step_icon_y = screen_height*.69;
        dc.drawBitmap(   step_icon_x, step_icon_y, steps_icon);
//        dc.drawRectangle(step_icon_x-1, step_icon_y-2, 25, 22); // colour feet

        // ============================================================
        // Draw the battery arc
        var bar_width = 8;
        drawPolygonArc(dc, screen_width/2, screen_height/2, screen_height/2, bar_width, 88,88, Gfx.COLOR_YELLOW, CLOCKWISE);

        // ============================================================
        // Draw the notification arc
        drawPolygonArc(dc, screen_width/2, screen_height/2, screen_height/2, bar_width, 87,89, Gfx.COLOR_YELLOW, COUNTERCLOCKWISE);

        // ============================================================
        // Draw the move arc
        drawPolygonArc(dc, screen_width/2, screen_height/2, screen_height/2, bar_width, 88,179, Gfx.COLOR_YELLOW, CLOCKWISE);

        // ============================================================
        // Draw the activity arc
        drawPolygonArc(dc, screen_width/2, screen_height/2, screen_height/2, bar_width ,  88, 179, Gfx.COLOR_YELLOW, COUNTERCLOCKWISE);
        drawPolygonArc(dc, screen_width/2, screen_height/2, screen_height/2, bar_width/3, 88,179, Gfx.COLOR_BLUE, COUNTERCLOCKWISE);
        dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_BLUE);
        drawWedge(dc, 15.3 , 0.7 , 0, 8, Gfx.COLOR_BLUE);
        drawWedge(dc, 29.7 , 0.7 , 0, 8, Gfx.COLOR_BLUE);

        // ============================================================
        // Draw the Move icon
        var sleep_move_icon_x = screen_width*.23;
        var sleep_move_icon_y = screen_height*.70;
        if (debug )
        {
            var dimensions =  dc.getTextDimensions("Move!",Gfx.FONT_XTINY);
            dc.setColor(Gfx.COLOR_DK_RED,Gfx.COLOR_DK_RED);
            dc.fillRoundedRectangle(sleep_move_icon_x, sleep_move_icon_y ,
                                    dimensions[0]+5, dimensions[1]-2, 4);
            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
            dc.drawText(sleep_move_icon_x+3, sleep_move_icon_y-2 ,
                        Gfx.FONT_XTINY, "Move!", Gfx.TEXT_JUSTIFY_LEFT);

        }

    }
    function drawFenix3BackgroundMacho(dc)
    {
        drawCommonBackground(dc);



        // ============================================================
        // Draw the 5 minute marks
        for (var count = 0; count < 60; count =count+5)
        {
          if (count == 0 or (count)% 15 == 0)
          {
            drawTriangleFromMin(dc, count,  12, radius-8, radius, Gfx.COLOR_WHITE);
          }
          else
          {
              drawWedge(dc,count, 0.3, 0 , 7, Gfx.COLOR_LT_GRAY); // wider minute tag
              drawWedge(dc,count, 1, 10, 26, Gfx.COLOR_LT_GRAY);
              drawWedge(dc,count, 0.3, 13, 20, Gfx.COLOR_WHITE);
          }
        }


        // Draw the small minute marks
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_WHITE);
        for (var count = 1; count < 60; count =count+5)
        {
          for (var c=0; c<5; c++) {
            drawLineFromMin(dc,count+c, 2,radius-5 ,radius, Gfx.COLOR_WHITE);
          }
        }
        if (debug)
        {
        drawTwelve(dc);
        }
    }

    // ============================================================
    //! Handle the update event
    function onUpdate(dc)
    {
        screen_width = dc.getWidth();
        screen_height = dc.getHeight();
        radius = screen_height/2;

        if (screen_type == SCREEN_UNKNOWN) {
          screen_width = dc.getWidth();
          screen_height = dc.getHeight();
          if (screen_width == 218 and screen_height == 218) {
            screen_type = SCREEN_ROUND;
          }
          else if (screen_width == 215 and screen_height == 180) {
            screen_type = SCREEN_SEMI_ROUND;
          }
          if (screen_height > screen_width) { // choose smallest dimension for radius
               radius = screen_width/2;
        }
          else {
            radius = screen_height/2;
          }
        }
        if (counter >= MAX_DIALS) { counter = 0; }


        // ============================================================
        // Clear the screen
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.fillRectangle(0,0,screen_width, screen_height);

        // ============================================================
        // Display the dials
        if (counter == 0)
        {
          drawFenix3BackgroundElegant(dc);
          counter=1;
        }
        else if (counter == 1)
        {
          drawFenix3BackgroundMacho(dc);
          counter=0;
        }

    }
}


class DrawDials extends App.AppBase
{
    function onStart()
    {
    }

    function onStop()
    {
    }

    function getInitialView()
    {
        return [new DrawDialsFace()];
    }
}
