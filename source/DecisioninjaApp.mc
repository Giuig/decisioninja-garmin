import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.System;
import Toybox.Math;
import Toybox.Timer;
import Toybox.Attention;

// Top right icon constants
var ICON_X = 144;
var ICON_Y = 31;
var ICON_R = 31;

// Footer constants
var FOOTER_Y = 35;

function drawFooter(dc, text) {
    dc.drawText(dc.getWidth() / 2, dc.getHeight() - FOOTER_Y, Graphics.FONT_XTINY, text, Graphics.TEXT_JUSTIFY_CENTER);
}

class DecisioninjaApp extends Application.AppBase {
    var binaryMode = 0;
    var diceCount = 1;
    var diceType = 6;
    var vibrationEnabled = true;

    function initialize() {
        AppBase.initialize();
        
        var savedBin = Storage.getValue("bin");
        if (savedBin != null) { binaryMode = savedBin; }
        
        var savedCnt = Storage.getValue("cnt");
        if (savedCnt != null) { diceCount = savedCnt; }
        
        var savedTyp = Storage.getValue("typ");
        if (savedTyp != null) { diceType = savedTyp; }
        
        var savedVib = Storage.getValue("vib");
        if (savedVib != null) { vibrationEnabled = savedVib; }
    }

    function onStop(state) {
        Storage.setValue("bin", binaryMode);
        Storage.setValue("cnt", diceCount);
        Storage.setValue("typ", diceType);
        Storage.setValue("vib", vibrationEnabled);
    }

    function getInitialView() {
        var menu = new WatchUi.Menu2({:title=>"Decisioninja"});
        menu.addItem(new WatchUi.MenuItem("Binary", "Pick between two", "id_binary", {:icon => new BinaryIcon()}));
        menu.addItem(new WatchUi.MenuItem("Dice", "Roll the dice", "id_dice", {:icon => new DiceIcon()}));
        menu.addItem(new WatchUi.MenuItem("Pointer", "Random direction", "id_pointer", {:icon => new PointerIcon()}));
        menu.addItem(new WatchUi.MenuItem("Settings", "Configure app", "id_settings", {:icon => new GearIcon()}));
        // Added About section
        menu.addItem(new WatchUi.MenuItem("About", "Credits & Info", "id_about", {:icon => new NinjaIconSmall()}));
        
        return [ menu, new MyMenuDelegate(self) ];
    }

    function getBinLabel() {
        var labels = ["YES / NO", "LEFT / RIGHT", "HEADS / TAILS"];
        return labels[binaryMode];
    }

    function triggerVibe() {
        if (vibrationEnabled && Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(50, 100)]);
        }
    }
}

// --- DELEGATES ---

class MyMenuDelegate extends WatchUi.Menu2InputDelegate {
    var app;
    function initialize(a) { Menu2InputDelegate.initialize(); app = a; }

    function onSelect(item) {
        var id = item.getId();
        if (id.equals("id_binary")) {
            var bView = new BinaryView(app);
            WatchUi.pushView(bView, new BinaryDelegate(bView), WatchUi.SLIDE_LEFT);
        } else if (id.equals("id_dice")) {
            var dView = new DiceView(app);
            WatchUi.pushView(dView, new DiceDelegate(dView), WatchUi.SLIDE_LEFT);
        } else if (id.equals("id_pointer")) {
            var pView = new PointerView(app);
            WatchUi.pushView(pView, new PointerDelegate(pView), WatchUi.SLIDE_LEFT);
        } else if (id.equals("id_about")) {
            WatchUi.pushView(new CreditsView(), new WatchUi.BehaviorDelegate(), WatchUi.SLIDE_UP);
        } else if (id.equals("id_settings")) {
            var sMenu = new WatchUi.Menu2({:title=>"Settings"});
            sMenu.addItem(new WatchUi.MenuItem("Binary Mode", app.getBinLabel(), "set_bin", {:icon => new GearIcon()}));
            sMenu.addItem(new WatchUi.MenuItem("Dice Count", app.diceCount == 1 ? "1 Die" : app.diceCount.toString() + " Dice", "set_count", {:icon => new GearIcon()}));
            sMenu.addItem(new WatchUi.MenuItem("Dice Type", "D" + app.diceType.toString(), "set_type", {:icon => new GearIcon()}));
            sMenu.addItem(new WatchUi.ToggleMenuItem("Vibration", {:enabled=>"ON", :disabled=>"OFF"}, "set_vibe", app.vibrationEnabled, {:icon => new GearIcon()}));
            WatchUi.pushView(sMenu, new SettingsDelegate(app), WatchUi.SLIDE_UP);
        }
    }
    function onBack() { System.exit(); }
}

class SettingsDelegate extends WatchUi.Menu2InputDelegate {
    var app;
    function initialize(a) { Menu2InputDelegate.initialize(); app = a; }

    function onSelect(item) {
        var id = item.getId();
        if (id.equals("set_vibe")) {
            if (item instanceof WatchUi.ToggleMenuItem) { app.vibrationEnabled = item.isEnabled(); }
            return;
        }
        var subMenu = new WatchUi.Menu2({:title=>item.getLabel()});
        if (id.equals("set_bin")) {
            subMenu.addItem(new WatchUi.MenuItem("YES / NO", "", 0, {:icon => new GearIcon()}));
            subMenu.addItem(new WatchUi.MenuItem("LEFT / RIGHT", "", 1, {:icon => new GearIcon()}));
            subMenu.addItem(new WatchUi.MenuItem("HEADS / TAILS", "", 2, {:icon => new GearIcon()}));
        } else if (id.equals("set_count")) {
            subMenu.addItem(new WatchUi.MenuItem("1 Die", "", 1, {:icon => new GearIcon()}));
            subMenu.addItem(new WatchUi.MenuItem("2 Dice", "", 2, {:icon => new GearIcon()}));
        } else if (id.equals("set_type")) {
            var types = [4, 6, 8, 10, 12, 20];
            for(var i=0; i<types.size(); i++) {
                subMenu.addItem(new WatchUi.MenuItem("D" + types[i], "", types[i], {:icon => new GearIcon()}));
            }
        }
        WatchUi.pushView(subMenu, new ApplySettingsDelegate(app, id, item), WatchUi.SLIDE_LEFT);
    }
}

class ApplySettingsDelegate extends WatchUi.Menu2InputDelegate {
    var app; var type; var settingItem;
    function initialize(a, t, sItem) { Menu2InputDelegate.initialize(); app = a; type = t; settingItem = sItem; }
    function onSelect(item) {
        var val = item.getId();
        if (type.equals("set_bin")) { app.binaryMode = val; settingItem.setSubLabel(app.getBinLabel()); }
        else if (type.equals("set_count")) { app.diceCount = val; settingItem.setSubLabel(val == 1 ? "1 Die" : val.toString() + " Dice"); }
        else if (type.equals("set_type")) { app.diceType = val; settingItem.setSubLabel("D" + val.toString()); }
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

// --- VIEWS ---

class CreditsView extends WatchUi.View {
    function initialize() { View.initialize(); }
    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        var cx = dc.getWidth() / 2;
        
        // Draw icon indicator at top right
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.fillCircle(ICON_X, ICON_Y, ICON_R);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(ICON_X, ICON_Y, Graphics.FONT_XTINY, "i", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        
        // Draw Mascot centered
        var ninja = WatchUi.loadResource(Rez.Drawables.decisioninja_icon);
        dc.drawBitmap(cx - 55, 15, ninja);
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 85, Graphics.FONT_SMALL, "Decisioninja", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, 105, Graphics.FONT_XTINY, "v1.0.2", Graphics.TEXT_JUSTIFY_CENTER);
        
        dc.setPenWidth(1);
        dc.drawLine(cx - 40, 125, cx + 40, 125);
        
        dc.drawText(cx, 130, Graphics.FONT_XTINY, "Made by Giuig", Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class BinaryView extends WatchUi.View {
    var resultText = "???";
    var isSpinning = false;
    var myTimer;
    var app;

    function initialize(a) { View.initialize(); app = a; myTimer = new Timer.Timer(); generateDecision(); }

    function generateDecision() {
        isSpinning = true;
        resultText = "---";
        myTimer.start(method(:onTimerEnd), 1200, false);
        WatchUi.requestUpdate();
    }

    function onTimerEnd() {
        var rand = Math.rand() % 2;
        if (app.binaryMode == 0) { resultText = (rand == 0) ? "YES" : "NO"; }
        else if (app.binaryMode == 1) { resultText = (rand == 0) ? "LEFT" : "RIGHT"; }
        else { resultText = (rand == 0) ? "HEADS" : "TAILS"; }
        isSpinning = false;
        app.triggerVibe();
        WatchUi.requestUpdate();
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        // Draw binary mode indicator at top right
        var modeText = "";
        if (app.binaryMode == 0) { modeText = "Y/N"; }
        else if (app.binaryMode == 1) { modeText = "L/R"; }
        else { modeText = "H/T"; }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.fillCircle(ICON_X, ICON_Y, ICON_R);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(ICON_X, ICON_Y, Graphics.FONT_XTINY, modeText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (isSpinning) {
            var dots = ["", ".", "..", "..."][(System.getTimer() / 250) % 4];
            dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Graphics.FONT_MEDIUM, "DECIDING" + dots, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            WatchUi.requestUpdate();
        } else {
            // dc.drawText(dc.getWidth() / 2, 45, Graphics.FONT_XTINY, "RESULT:", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2 + 5, Graphics.FONT_NUMBER_THAI_HOT, resultText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            drawFooter(dc, "GPS TO RETRY");
        }
    }
}

class BinaryDelegate extends WatchUi.BehaviorDelegate {
    var view;
    function initialize(v) { BehaviorDelegate.initialize(); view = v; }
    function onSelect() { if (!view.isSpinning) { view.generateDecision(); } return true; }
}

class DiceView extends WatchUi.View {
    var diceValues = [0, 0];
    var isSpinning = false;
    var myTimer;
    var app;

    function initialize(a) { View.initialize(); app = a; myTimer = new Timer.Timer(); rollDice(); }

    function rollDice() {
        isSpinning = true;
        WatchUi.requestUpdate();
        myTimer.start(method(:onTimerEnd), 1200, false);
    }

    function onTimerEnd() {
        diceValues[0] = (Math.rand() % app.diceType) + 1;
        diceValues[1] = (Math.rand() % app.diceType) + 1;
        isSpinning = false;
        app.triggerVibe();
        WatchUi.requestUpdate();
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        // Draw dice type info at top right - matching menu icon position
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.fillCircle(ICON_X, ICON_Y, ICON_R);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        var diceText = app.diceCount.toString() + "D" + app.diceType.toString();
        dc.drawText(ICON_X, ICON_Y, Graphics.FONT_XTINY, diceText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (isSpinning) {
            var dots = ["", ".", "..", "..."][(System.getTimer() / 250) % 4];
            dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Graphics.FONT_MEDIUM, "CASTING" + dots, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            WatchUi.requestUpdate();
        } else {
            var cx = dc.getWidth() / 2;
            var cy = dc.getHeight() / 2;
            dc.setPenWidth(3);
            if (app.diceCount == 1) {
                dc.drawRoundedRectangle(cx - 25, cy - 25, 50, 50, 6);
                dc.drawText(cx, cy, Graphics.FONT_NUMBER_MEDIUM, diceValues[0].toString(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            } else {
                dc.drawRoundedRectangle(cx - 55, cy - 40, 50, 50, 5);
                dc.drawText(cx - 29, cy - 14, Graphics.FONT_NUMBER_MEDIUM, diceValues[0].toString(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                dc.drawRoundedRectangle(cx + 5, cy - 10, 50, 50, 5);
                dc.drawText(cx + 31, cy + 16, Graphics.FONT_NUMBER_MEDIUM, diceValues[1].toString(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
            drawFooter(dc, "GPS TO RETRY");
        }
    }
}

class DiceDelegate extends WatchUi.BehaviorDelegate {
    var view;
    function initialize(v) { BehaviorDelegate.initialize(); view = v; }
    function onSelect() { if (!view.isSpinning) { view.rollDice(); } return true; }
}

class PointerView extends WatchUi.View {
    var angle = 0;
    var isSpinning = false;
    var myTimer;
    var app;

    function initialize(a) { View.initialize(); app = a; myTimer = new Timer.Timer(); spin(); }

    function spin() {
        isSpinning = true;
        WatchUi.requestUpdate();
        myTimer.start(method(:onTimerEnd), 1200, false);
    }

    function onTimerEnd() {
        angle = Math.rand() % 360;
        isSpinning = false;
        app.triggerVibe();
        WatchUi.requestUpdate();
    }

function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        // Draw compass indicator at top right (Porthole)
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.fillCircle(ICON_X, ICON_Y, ICON_R);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(ICON_X, ICON_Y, Graphics.FONT_XTINY, "DIR", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;

        if (isSpinning) {
            var dots = ["", ".", "..", "..."][(System.getTimer() / 250) % 4];
            dc.drawText(cx, cy, Graphics.FONT_MEDIUM, "POINTING" + dots, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            WatchUi.requestUpdate();
        } else {
            // Convert to radians (Garmin uses 0 at right, subtract 90 to have 0 at top)
            var rad = (angle - 90) * (Math.PI / 180);

            // --- LARGER ARROW DIMENSIONS ---
            var fullLength = 60;  // Total arrow length
            var headLength = 25;  // Tip length
            var headWidth = 30;   // Tip width
            var shaftWidth = 10;  // Shaft thickness
            
            // To rotate in place, center (cx, cy) must be at half the total length
            var halfLen = fullLength / 2;
            
            // Start point (tail) and end of shaft (where tip begins)
            var tailX = cx - halfLen * Math.cos(rad);
            var tailY = cy - halfLen * Math.sin(rad);
            
            var headBaseX = cx + (halfLen - headLength) * Math.cos(rad);
            var headBaseY = cy + (halfLen - headLength) * Math.sin(rad);
            
            // Extreme tip
            var tipX = cx + halfLen * Math.cos(rad);
            var tipY = cy + halfLen * Math.sin(rad);

            // Draw shaft
            dc.setPenWidth(shaftWidth);
            dc.drawLine(tailX, tailY, headBaseX, headBaseY);

            // Calculate triangle base vertices (perpendicular to shaft)
            var angleOrtho = rad + (Math.PI / 2); 
            var hX1 = headBaseX + (headWidth / 2) * Math.cos(angleOrtho);
            var hY1 = headBaseY + (headWidth / 2) * Math.sin(angleOrtho);
            var hX2 = headBaseX - (headWidth / 2) * Math.cos(angleOrtho);
            var hY2 = headBaseY - (headWidth / 2) * Math.sin(angleOrtho);

            // Draw tip
            dc.fillPolygon([[tipX, tipY], [hX1, hY1], [hX2, hY2]]);

            // Footer
            drawFooter(dc, "GPS TO RETRY");
        }
    }
}

class PointerDelegate extends WatchUi.BehaviorDelegate {
    var view;
    function initialize(v) { BehaviorDelegate.initialize(); view = v; }
    function onSelect() { if (!view.isSpinning) { view.spin(); } return true; }
}

// --- DRAWABLES / ICONS ---

class BinaryIcon extends WatchUi.Drawable {
    function initialize() { Drawable.initialize({}); }
    function draw(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE); dc.clear();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT); dc.setPenWidth(2);
        var cx = dc.getWidth() / 2; var cy = dc.getHeight() / 2;
        dc.drawLine(cx, cy - 12, cx, cy + 12);
        dc.drawLine(cx - 10, cy + 8, cx - 6, cy - 8); dc.drawLine(cx - 2, cy + 8, cx - 6, cy - 8);
        dc.drawLine(cx + 3, cy - 8, cx + 3, cy + 8);
        dc.drawArc(cx + 3, cy - 4, 4, Graphics.ARC_CLOCKWISE, 90, 270);
    }
}

class DiceIcon extends WatchUi.Drawable {
    function initialize() { Drawable.initialize({}); }
    function draw(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE); dc.clear();
        var cx = dc.getWidth() / 2; var cy = dc.getHeight() / 2;
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(cx - 14, cy - 14, 28, 28, 4);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.fillCircle(cx, cy, 3);
        dc.fillCircle(cx - 8, cy - 8, 2); dc.fillCircle(cx + 8, cy + 8, 2);
    }
}

class PointerIcon extends WatchUi.Drawable {
    function initialize() { Drawable.initialize({}); }
    function draw(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE); dc.clear();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT); dc.setPenWidth(3);
        dc.drawCircle(dc.getWidth()/2, dc.getHeight()/2, 16);
        dc.fillPolygon([[dc.getWidth()/2, dc.getHeight()/2 - 12], [dc.getWidth()/2 - 5, dc.getHeight()/2], [dc.getWidth()/2 + 5, dc.getHeight()/2]]);
    }
}

class GearIcon extends WatchUi.Drawable {
    function initialize() { Drawable.initialize({}); }
    function draw(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE); dc.clear();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        var cx = dc.getWidth() / 2, cy = dc.getHeight() / 2, r = 12; 
        dc.fillPolygon([[cx-r/2, cy-r], [cx+r/2, cy-r], [cx+r, cy], [cx+r/2, cy+r], [cx-r/2, cy+r], [cx-r, cy]]);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE); dc.fillCircle(cx, cy, 4);
    }
}

// Small ninja head for the menu
class NinjaIconSmall extends WatchUi.Drawable {
    function initialize() { Drawable.initialize({}); }
    function draw(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE); dc.clear();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        var cx = dc.getWidth() / 2; var cy = dc.getHeight() / 2;
        dc.fillRectangle(cx - 12, cy - 8, 24, 16); // Face wrap
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.fillRectangle(cx - 8, cy - 3, 16, 4); // Eye slit
    }
}