import CX11.Xlib
import CX11.X

#if os(Linux)
    import Glibc
    import SwiftShims
#else
    import Darwin
#endif

// MARK: Random number for random color

///
/// Cross platform random number generator based off of arc4random
/// - Parameter upperBound: The highest value
/// - Returns: A random number between 0 and `upperBound` - 1
///
func cs_arc4random_uniform(upperBound: UInt32) -> UInt32 {
    #if os(Linux)
        return _swift_stdlib_arc4random_uniform(upperBound)
    #else
        return arc4random_uniform(upperBound)
    #endif
}

// MARK: Colors

///
/// Struct to represent colors
///
struct Color {
    ///
    /// Red value between 0 and 0xFFFF
    ///
    let red: Int
    ///
    /// Green value between 0 and 0xFFFF
    ///
    let green: Int
    ///
    /// Blue value between 0 and 0xFFFF
    ///
    let blue: Int
    ///
    /// White color, equivalent hex value of `#FFFFFF`
    ///
    static let white    = Color(red: 0xFFFF, green: 0xFFFF, blue: 0xFFFF)
    ///
    /// Red color, equivalent hex value of `#FF0000`
    ///
    static let red      = Color(red: 0xFFFF, green: 0, blue: 0)
    ///
    /// Green color, equivalent hex value of `#00FF00`
    ///
    static let green    = Color(red: 0, green: 0xFFFF, blue: 0)
    ///
    /// Blue color, equivalent hex value of `#0000FF`
    ///
    static let blue     = Color(red: 0, green: 0, blue: 0xFFFF)
    ///
    /// Yellow color, equivalent hex value of `#FFFF00`
    ///
    static let yellow = Color(red: 0xFFFF, green: 0xFFFF, blue: 0)
    ///
    /// Cyan color, equivalent hex value of `#00FFFF`
    ///
    static let cyan = Color(red: 0, green: 0xFFFF, blue: 0xFFFF)
    ///
    /// Magenta color, equivalent hex value of `#FF00FF`
    ///
    static let magenta = Color(red: 0xFFFF, green: 0, blue: 0xFFFF)
    ///
    /// Black color, equivalent hex value of `#000000`
    ///
    static let black = Color(red: 0, green: 0, blue: 0)
    ///
    /// Generates a random, additive color
    /// - Returns: A random additive color
    ///
    static func random() -> Color {
        let red = cs_arc4random_uniform(2) == 0 ? 0xFFFF : 0
        let green = cs_arc4random_uniform(2) == 0 ? 0xFFFF : 0
        let blue = cs_arc4random_uniform(2) == 0 ? 0xFFFF : 0
        return Color(red: red, green: green, blue: blue)
    }
}

// MARK: Shapes

///
/// Shape protocol
///
protocol Shape {
    ///
    /// Color of this shape
    ///
    var color: Color { get set }
    ///
    /// Whether or not this shape is filled or has an outline
    ///
    var filled: Bool { get set }
    ///
    /// Position of the shape as `x` and `y`
    ///
    var position: (x: Int, y: Int) { get set }
    ///
    /// Size of the shape, where `w` represents width and `y` represents height
    ///
    var size: (w: Int, h: Int) { get set }
    ///
    /// Draws the shape to a specific window
    /// - Parameter window: The window to draw to
    ///
    func draw(window: ScreenWindow)
}

///
/// Rectangle shape
///
struct Rectangle: Shape {
    var color: Color
    var filled: Bool
    var position: (x: Int, y: Int)
    var size: (w: Int, h: Int)
    func draw(window: ScreenWindow) {
        if self.filled {
            // Implement using XFillRectangle if filled
            XFillRectangle(
                window.xDisplay,
                window.xWindow,
                window.xContext,
                Int32(self.position.x),
                Int32(self.position.y),
                UInt32(self.size.w),
                UInt32(self.size.h))
        } else {
            // Implement using XDrawRectangle if outline
            XDrawRectangle(
                window.xDisplay,
                window.xWindow,
                window.xContext,
                Int32(self.position.x),
                Int32(self.position.y),
                UInt32(self.size.w),
                UInt32(self.size.h))
        }
    }
}

// MARK: Window using X11

///
/// A window event binds to an X11 event, which is an `Int32`
///
typealias WindowEvent = Int32

///
/// A GUI window implemented using X11
///
struct ScreenWindow {
    ///
    /// The internal X11 window
    ///
    private let xWindow: Window
    ///
    /// The internal X11 display
    ///
    private let xDisplay: _XPrivDisplay
    ///
    /// The internal X11 graphic's content
    ///
    private let xContext: GC
    ///
    /// The internal X11 event handler value
    ///
    private let xEvent: UnsafeMutablePointer<_XEvent> = UnsafeMutablePointer<_XEvent>.alloc(1)
    ///
    /// The internal X11 colormap used for colors
    ///
    private let xColormap: Colormap
    
    ///
    /// The next event to handle from the window
    ///
    var nextEvent: WindowEvent {
        XNextEvent(xDisplay, xEvent)
        return WindowEvent(xEvent.memory.type)
    }

    ///
    /// Creates a new window in the top-left corner of the screen
    /// - Parameter title: The name of the window, defaults to `X11`
    /// - Parameter width: The width of the window, defaults to `600`
    /// - Parameter height: The height of the window, defaults to `300`
    ///
    init(title: String = "X11", width: UInt = 600, height: UInt = 300) {
        let xDisplay = XOpenDisplay(nil)
        if xDisplay == nil {
            fatalError("Cannot open display")
        }
        let xScreen = XDefaultScreenOfDisplay(xDisplay)
        let rootWindow = xScreen.memory.root
        let blackColor = XBlackPixel(xDisplay, XDefaultScreen(xDisplay))
        let whiteColor = XWhitePixel(xDisplay, XDefaultScreen(xDisplay))
        
        // Create the window
        let xWindow = XCreateSimpleWindow(  xDisplay,
                                            rootWindow,
                                            0,0,
                                            UInt32(width),
                                            UInt32(height),
                                            0, blackColor, whiteColor)
        
        // Change input type (listen to structre notify, exposure and keypress)
        XSelectInput(xDisplay, xWindow, StructureNotifyMask | ExposureMask | KeyPressMask)
        
        // Map the window to the display
        XMapWindow(xDisplay, xWindow)
        
        // Set the window title
        XStoreName(xDisplay, xWindow, title)

        // Get the context
        let xContext = XCreateGC(xDisplay, xWindow, 0, nil)
        XSetForeground(xDisplay, xContext, blackColor)
        XSetBackground(xDisplay, xContext, whiteColor)
        
        // Support close window
        var atom = XInternAtom(xDisplay, "WM_DELETE_WINDOW", False);
        XSetWMProtocols(xDisplay, xWindow, &atom, 1);
        
        // Bind locals to fields
        self.xDisplay = xDisplay
        self.xWindow = xWindow
        self.xContext = xContext
        self.xColormap = XDefaultColormap(xDisplay, XDefaultScreen(xDisplay))
    }
    
    ///
    /// Flushes the window for draw events
    ///
    func flush() {
        XFlush(xDisplay);
    }
    
    ///
    /// Sets the current foreground color
    /// - Parameter color: Color to set
    ///
    func setForeground(color: Color) {
        let flags: Int8 = Int8(DoRed) | Int8(DoGreen) | Int8(DoBlue);
        var xcolor = XColor(pixel: 1,
                            red: UInt16(color.red),
                            green: UInt16(color.green),
                            blue: UInt16(color.blue),
                            flags: flags,
                            pad: 1)
        XAllocColor(xDisplay, xColormap, &xcolor)
        XSetForeground(xDisplay, xContext, xcolor.pixel)
    }
    
    ///
    /// Draws a shape
    /// - Parameter shape: The shape to draw
    ///
    func draw(shape: Shape) {
        setForeground(shape.color)
        shape.draw(self)
    }
}

// MARK: Main Program

// Open a window
let window = ScreenWindow(title: "Hello World!", width: 300, height: 300)

// User has requested quit?
var hasQuit: Bool = false

// Simple function that draws some squares
func drawSquares() {
    for j in 0...2 {
        for k in 0...2 {
            let shape = Rectangle(color: Color.random(),
                                  filled: true,
                                  position: (j*100,k*100),
                                  size: (100,100))
            window.draw(shape)
        }
    }
}

// Main loop
repeat {
    // Keep grabbing the next event as it comes
    switch window.nextEvent {
    // On window map complete or key was pressed, draw us some shapes
    case MapNotify, KeyPress:
        drawSquares()
    // When exposing the window, refresh context
    case Expose:
        window.flush()
    // Window close requested
    case ClientMessage:
        hasQuit = true
    // Don't handle
    default:
        break
    }
} while !hasQuit