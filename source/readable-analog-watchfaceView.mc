import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
using Toybox.Time.Gregorian;

class readable_analog_watchfaceView extends WatchUi.WatchFace {
    var screenCenterPoint;
    var font;
    var backgroundBuffer;
    var dateBuffer;
    var backgroundLoaded = false;
    var minuteHandCoords = [];
    var hourHandCoords = [];
    var date;

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
        screenCenterPoint = [dc.getWidth()/2, dc.getHeight()/2];
        font = WatchUi.loadResource(Rez.Fonts.id_font_black_diamond);

        backgroundBuffer = bufferedBitmapFactory({
                :width=>dc.getWidth(),
                :height=>dc.getHeight(),
                :palette=> [
                    Graphics.COLOR_DK_GRAY,
                    Graphics.COLOR_LT_GRAY,
                    Graphics.COLOR_BLACK,
                    Graphics.COLOR_WHITE
                ],

            });

        backgroundBuffer = backgroundBuffer.get();
        
        // Allocate a buffer tall enough to draw the date into the full width of the
        // screen. This buffer is also used for blanking the second hand. This full
        // color buffer is needed because anti-aliased fonts cannot be drawn into
        // a buffer with a reduced color palette
        dateBuffer = Graphics.createBufferedBitmap({
            :width=>dc.getWidth(),
            :height=>Graphics.getFontHeight(Graphics.FONT_MEDIUM)
        });
        minuteHandCoords.add(generateHandCoordinatesWithoutRotation(screenCenterPoint, 0, (dc.getWidth()/2 * 0.85), 0, 12, 4));
        minuteHandCoords.add(scaleBy(generateHandCoordinatesWithoutRotation(screenCenterPoint, 0, dc.getWidth()/2 * 0.85, 0, 12, 4),-3));
        hourHandCoords.add(generateHandCoordinatesWithoutRotation(screenCenterPoint, 0, dc.getWidth()/2 * 0.45, 0, 16, 7));
        hourHandCoords.add(scaleBy(generateHandCoordinatesWithoutRotation(screenCenterPoint, 0, dc.getWidth()/2 * 0.45, 0, 16, 7),-3));

        dateBuffer=dateBuffer.get();
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // // Update the view
    // function onUpdate(dc as Dc) as Void {
    //     // Get and show the current time
    //     var clockTime = System.getClockTime();
    //     var timeString = Lang.format("$1$:$2$", [clockTime.hour, clockTime.min.format("%02d")]);
    //     var view = View.findDrawableById("TimeLabel") as Text;
    //     view.setText(timeString);

    //     // Call the parent onUpdate function to redraw the layout
    //     View.onUpdate(dc);
    // }
// function onPartialUpdate(dc) {
//     System.println("onPartialUpdate");
//     drawWatchface(dc);
// }

function drawBackGround(targetDc, radius, width, height){
    System.println("drawBackGround");
    // Fill the entire background with Black.
    // log after 
    targetDc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
    targetDc.fillRectangle(0, 0, width, height);

    drawDateString(targetDc, screenCenterPoint[0] - radius* 0.45, screenCenterPoint[1]);

    // Draw the numbers.
    var distance = radius * 0.78;
    for (var i = 1 ; i<=12 ; i++){
        var angel = (Math.PI * 2 /12 * i) - (Math.PI/2);
        var _x = screenCenterPoint[0] + (distance * Math.cos(angel));
        var _y =screenCenterPoint[1] + (distance * Math.sin(angel));
        targetDc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        targetDc.drawText(_x , _y , font, i.toString(), Graphics.TEXT_JUSTIFY_VCENTER | Graphics.TEXT_JUSTIFY_CENTER);
        // targetDc.drawText(_x , _y , Graphics.FONT_MEDIUM, i.toString(), Graphics.TEXT_JUSTIFY_VCENTER | Graphics.TEXT_JUSTIFY_CENTER);
    }

    //draw the minutes indicators
    var tickAngle =  Math.PI * 2 / 60;
    for (var i = 1 ; i<= 60; i++){
        var x = (radius - 5);
        var y = 0;
        var tickWidth = 3;
        var tickHeight = 8;
        var points = [
            [x - tickHeight/2, y - tickWidth/2],
            [x - tickHeight/2, y + tickWidth/2],
            [x + tickHeight/2, y + tickWidth/2],
            [x+  tickHeight/2, y - tickWidth/2]
        ];
        var angel = (tickAngle * i);
        var sin = Math.sin(angel);
        var cos = Math.cos(angel);
        targetDc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        // Transform the coordinates
        for (var j = 0; j < points.size(); j += 1) {
            points[j] = [
                // screenCenterPoint[0] + points[j][0],
                // screenCenterPoint[1] + points[j][1],
                screenCenterPoint[0] + (points[j][0] * cos) - (points[j][1] * sin),
                screenCenterPoint[1] + (points[j][0] * sin) + (points[j][1] * cos)
            ];
        }
        targetDc.fillPolygon(points);
    }
}

function drawWatchface(dc){
        System.println("drawWatchface");
        var width;
        var height;
        var radius;
        var screenWidth = dc.getWidth();
        var clockTime = System.getClockTime();
        var minuteHandAngle;
        var hourHandAngle;
        var secondHand;
        var targetDc = dc;

        width = targetDc.getWidth();
        height = targetDc.getHeight();
        radius = width / 2;

        if (!backgroundLoaded) {
                backgroundLoaded = true;
                drawBackGround(backgroundBuffer.getDc(), radius, width, height);
        }

        dc.drawBitmap(0,0, backgroundBuffer);

        // dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        // dc.drawText(screenCenterPoint[0], screenCenterPoint[1] - radius* 0.5, Graphics.FONT_TINY, "T+N", Graphics.TEXT_JUSTIFY_CENTER);


        // drawDateString( targetDc, screenCenterPoint[0] - radius* 0.45, screenCenterPoint[1]);
        // Draw the battery percentage directly to the main screen.
        var dataString = (System.getSystemStats().battery + 0.5).toNumber().toString() + "%";
        dc.setColor(Graphics.
        
        COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(screenCenterPoint[0], screenCenterPoint[1] + radius* 0.4, Graphics.FONT_TINY, dataString, Graphics.TEXT_JUSTIFY_CENTER);

        // Draw the hour hand. Convert it to minutes and compute the angle.
        hourHandAngle = (((clockTime.hour % 12) * 60) + clockTime.min);
        hourHandAngle = hourHandAngle / (12 * 60.0);
        hourHandAngle = hourHandAngle * Math.PI * 2;
        drawHand2(screenCenterPoint, hourHandAngle, hourHandCoords[0], hourHandCoords[1], targetDc);

        // Draw the minute hand.
        minuteHandAngle = (clockTime.min / 60.0) * Math.PI * 2;
        drawHand2(screenCenterPoint, minuteHandAngle, minuteHandCoords[0], minuteHandCoords[1], targetDc);
        // targetDc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_LT_GRAY);
        // targetDc.fillPolygon(generateHandCoordinates(screenCenterPoint, minuteHandAngle, 80, 0, 8));
        drawCircleAtTheMiddle(targetDc);
}
        
function drawCircleAtTheMiddle(targetDc){
    var width = targetDc.getWidth();
    var height = targetDc.getHeight();
    var radius = width / 2;
    targetDc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
    targetDc.fillCircle(screenCenterPoint[0], screenCenterPoint[1], 10);
    targetDc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
    targetDc.fillCircle(screenCenterPoint[0], screenCenterPoint[1] , 7);
    targetDc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
    targetDc.fillCircle(screenCenterPoint[0], screenCenterPoint[1], 2);
    
}
function onUpdate(dc) {
    System.println("onUpdate");
    // if (prevMinute != System.getClockTime().min) {
    //     prevMinute = System.getClockTime().min;
    //     drawWatchface(dc);
    // }
    drawWatchface(dc);
}

    function drawHand(centerPoint, angle, handLength, tailLength, headWidth, tailWidth, targetDc) {
        var coords = generateHandCoordinates(centerPoint, angle, handLength, tailLength, headWidth, tailWidth);
        var scaledCords = scaleBy(coords, -3);
        targetDc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        targetDc.fillPolygon(scaledCords);
        targetDc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        targetDc.fillPolygon(coords);
    }

    function drawHand2(centerPoint, angle, cords, bigCords, targetDc){
        var coords = rotate(cords, angle, centerPoint);
        var bigCoords = rotate(bigCords, angle, centerPoint);

        targetDc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        targetDc.fillPolygon(bigCoords);
        targetDc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        targetDc.fillPolygon(coords);
    }

    // given two vertices pt0 and pt1, a desired distance, and a function rot()
// that turns a vector 90 degrees outward:

    function vecUnit(v) {
        var len = Math.sqrt(v[0] * v[0] + v[1] * v[1]);
        return [v[0] / len, v[1] / len ];
    }

    function vecMul(v, s) {
        return [v[0] * s, v[1] * s ];
    }

    function aurthogonal(v) {
        return [-v[1], v[0]];
    }

    function vecSub(v1, v2) {
        return [v1[0] - v2[0], v1[1] - v2[1]];
    }

    function vecAdd(v1, v2) {
        return [v1[0] + v2[0], v1[1] + v2[1]];
    }

    function intersect(line1, line2) {
        var a1 = line1[1][0] - line1[0][0];
        var b1 = line2[0][0] - line2[1][0];
        var c1 = line2[0][0] - line1[0][0];

        var a2 = line1[1][1] - line1[0][1];
        var b2 = line2[0][1] - line2[1][1];
        var c2 = line2[0][1] - line1[0][1];

        var t = (b1*c2 - b2*c1) / (a2*b1 - a1*b2);

    return [line1[0][0] + t * (line1[1][0] - line1[0][0]),line1[0][1] + t * (line1[1][1] - line1[0][1])]
    ;
}


    function generateHandCoordinates(centerPoint, angle, handLength, tailLength, headWidth, tailWidth) {
        // Map out the coordinates of the watch hand
        var coords = [
            [-(tailWidth / 2), tailLength], 
            [ -((headWidth) / 2), -handLength], 
            [0, - handLength - 10], 
            [(headWidth) / 2, -handLength], 
            [tailWidth / 2, tailLength]];

        var len = coords.size();
        var result = new [len];
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);

        // Transform the coordinates
        for (var i = 0; i < len; i += 1) {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin);
            var y = (coords[i][0] * sin) + (coords[i][1] * cos);

            result[i] = [centerPoint[0] + x, centerPoint[1] + y];
        }

        return result;
    }

    function rotate(coords, angle, centerPoint){
        var len = coords.size();
        var result = new [len];
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);

        // Transform the coordinates
        for (var i = 0; i < len; i += 1) {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin);
            var y = (coords[i][0] * sin) + (coords[i][1] * cos);

            result[i] = [centerPoint[0] + x, centerPoint[1] + y];
        }
        return result;
    }

    function generateHandCoordinatesWithoutRotation(centerPoint, angle, handLength, tailLength, headWidth, tailWidth) {
        // Map out the coordinates of the watch hand
        var coords = [
            [-(tailWidth / 2), tailLength], 
            [ -((headWidth) / 2), -handLength], 
            [0, - handLength - 10], 
            [(headWidth) / 2, -handLength], 
            [tailWidth / 2, tailLength]];

        return coords;
        }

    function scaleBy(coords, scale) {
        var newLines = new [coords.size()];
        for (var i = 0; i < coords.size(); i += 1) {
            var p1 = coords[i];
            var p2 = coords[(i + 1) % coords.size()];
            var aorth = aurthogonal(vecUnit(vecSub(p2, p1)));
            var p1a = vecAdd(p1, vecMul(aorth, scale));
            var p2a = vecAdd(p2, vecMul(aorth, scale));
            newLines[i] = [p1a, p2a];            
        }
        // find intersections of lines 
        var result = new [coords.size()];
        for (var i = 0; i < coords.size(); i += 1) {
            result[i] = intersect(newLines[i], newLines[(i + 1) % coords.size()]);
        }
        return result;
    }

    // Draw the date string into the provided buffer at the specified location
    function drawDateString( dc, x, y ) {
        var info = Gregorian.info(Time.now(), Time.FORMAT_LONG);
        var dateStr = Lang.format("$1$$2$", [info.month, info.day]);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(x, y, Graphics.FONT_TINY, dateStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }


    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
        System.println("onExitSleep");
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
        System.println("onEnterSleep");
    }

    //! Factory function to create buffered bitmap
    function bufferedBitmapFactory(options as {
                :width as Number,
                :height as Number,
                :palette as Array<ColorType>,
                :colorDepth as Number,
                :bitmapResource as WatchUi.BitmapResource
            }) as BufferedBitmapReference or BufferedBitmap {
        if (Graphics has :createBufferedBitmap) {
            System.println("Using createBufferedBitmap");
            return Graphics.createBufferedBitmap(options);
        } else {
            System.println("Using BufferedBitmap");
            return new Graphics.BufferedBitmap(options);
        }
    }

}
