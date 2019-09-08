/// All possible notifications you can subscribe to with `Observer`.
/// - seeAlso: [Notificatons](https://developer.apple.com/library/mac/documentation/AppKit/Reference/NSAccessibility_Protocol_Reference/index.html#//apple_ref/c/data/NSAccessibilityAnnouncementRequestedNotification)
public enum AXNotification: String {
    // Focus notifications
    case mainWindowChanged       = "AXMainWindowChanged"
    case focusedWindowChanged    = "AXFocusedWindowChanged"
    case focusedUIElementChanged = "AXFocusedUIElementChanged"

    // Application notifications
    case applicationActivated    = "AXApplicationActivated"
    case applicationDeactivated  = "AXApplicationDeactivated"
    case applicationHidden       = "AXApplicationHidden"
    case applicationShown        = "AXApplicationShown"

    // Window notifications
    case windowCreated           = "AXWindowCreated"
    case windowMoved             = "AXWindowMoved"
    case windowResized           = "AXWindowResized"
    case windowMiniaturized      = "AXWindowMiniaturized"
    case windowDeminiaturized    = "AXWindowDeminiaturized"

    // Drawer & sheet notifications
    case drawerCreated           = "AXDrawerCreated"
    case sheetCreated            = "AXSheetCreated"

    // Element notifications
    case uiElementDestroyed      = "AXUIElementDestroyed"
    case valueChanged            = "AXValueChanged"
    case titleChanged            = "AXTitleChanged"
    case resized                 = "AXResized"
    case moved                   = "AXMoved"
    case created                 = "AXCreated"

    // Used when UI changes require the attention of assistive application.  Pass along a user info
    // dictionary with the key NSAccessibilityUIElementsKey and an array of elements that have been
    // added or changed as a result of this layout change.
    case layoutChanged           = "AXLayoutChanged"

    // Misc notifications
    case helpTagCreated          = "AXHelpTagCreated"
    case selectedTextChanged     = "AXSelectedTextChanged"
    case rowCountChanged         = "AXRowCountChanged"
    case selectedChildrenChanged = "AXSelectedChildrenChanged"
    case selectedRowsChanged     = "AXSelectedRowsChanged"
    case selectedColumnsChanged  = "AXSelectedColumnsChanged"

    case rowExpanded             = "AXRowExpanded"
    case rowCollapsed            = "AXRowCollapsed"

    // Cell-table notifications
    case selectedCellsChanged    = "AXSelectedCellsChanged"

    // Layout area notifications
    case unitsChanged            = "AXUnitsChanged"
    case selectedChildrenMoved   = "AXSelectedChildrenMoved"

    // This notification allows an application to request that an announcement be made to the user
    // by an assistive application such as VoiceOver.  The notification requires a user info
    // dictionary with the key NSAccessibilityAnnouncementKey and the announcement as a localized
    // string.  In addition, the key NSAccessibilityAnnouncementPriorityKey should also be used to
    // help an assistive application determine the importance of this announcement.  This
    // notification should be posted for the application element.
    case announcementRequested   = "AXAnnouncementRequested"
}

/// All UIElement roles.
/// - seeAlso: [Roles](https://developer.apple.com/library/mac/documentation/AppKit/Reference/NSAccessibility_Protocol_Reference/index.html#//apple_ref/doc/constant_group/Roles)
public enum Role: String {
    case unknown            = "AXUnknown"
    case button             = "AXButton"
    case radioButton        = "AXRadioButton"
    case checkBox           = "AXCheckBox"
    case slider             = "AXSlider"
    case tabGroup           = "AXTabGroup"
    case textField          = "AXTextField"
    case staticText         = "AXStaticText"
    case textArea           = "AXTextArea"
    case scrollArea         = "AXScrollArea"
    case popUpButton        = "AXPopUpButton"
    case menuButton         = "AXMenuButton"
    case table              = "AXTable"
    case application        = "AXApplication"
    case group              = "AXGroup"
    case radioGroup         = "AXRadioGroup"
    case list               = "AXList"
    case scrollBar          = "AXScrollBar"
    case valueIndicator     = "AXValueIndicator"
    case image              = "AXImage"
    case menuBar            = "AXMenuBar"
    case menu               = "AXMenu"
    case menuItem           = "AXMenuItem"
    case column             = "AXColumn"
    case row                = "AXRow"
    case toolbar            = "AXToolbar"
    case busyIndicator      = "AXBusyIndicator"
    case progressIndicator  = "AXProgressIndicator"
    case window             = "AXWindow"
    case drawer             = "AXDrawer"
    case systemWide         = "AXSystemWide"
    case outline            = "AXOutline"
    case incrementor        = "AXIncrementor"
    case browser            = "AXBrowser"
    case comboBox           = "AXComboBox"
    case splitGroup         = "AXSplitGroup"
    case splitter           = "AXSplitter"
    case colorWell          = "AXColorWell"
    case growArea           = "AXGrowArea"
    case sheet              = "AXSheet"
    case helpTag            = "AXHelpTag"
    case matte              = "AXMatte"
    case ruler              = "AXRuler"
    case rulerMarker        = "AXRulerMarker"
    case link               = "AXLink"
    case disclosureTriangle = "AXDisclosureTriangle"
    case grid               = "AXGrid"
    case relevanceIndicator = "AXRelevanceIndicator"
    case levelIndicator     = "AXLevelIndicator"
    case cell               = "AXCell"
    case popover            = "AXPopover"
    case layoutArea         = "AXLayoutArea"
    case layoutItem         = "AXLayoutItem"
    case handle             = "AXHandle"
}

/// All UIElement subroles.
/// - seeAlso: [Subroles](https://developer.apple.com/library/mac/documentation/AppKit/Reference/NSAccessibility_Protocol_Reference/index.html#//apple_ref/doc/constant_group/Subroles)
public enum Subrole: String {
    case unknown              = "AXUnknown"
    case closeButton          = "AXCloseButton"
    case zoomButton           = "AXZoomButton"
    case minimizeButton       = "AXMinimizeButton"
    case toolbarButton        = "AXToolbarButton"
    case tableRow             = "AXTableRow"
    case outlineRow           = "AXOutlineRow"
    case secureTextField      = "AXSecureTextField"
    case standardWindow       = "AXStandardWindow"
    case dialog               = "AXDialog"
    case systemDialog         = "AXSystemDialog"
    case floatingWindow       = "AXFloatingWindow"
    case systemFloatingWindow = "AXSystemFloatingWindow"
    case incrementArrow       = "AXIncrementArrow"
    case decrementArrow       = "AXDecrementArrow"
    case incrementPage        = "AXIncrementPage"
    case decrementPage        = "AXDecrementPage"
    case searchField          = "AXSearchField"
    case textAttachment       = "AXTextAttachment"
    case textLink             = "AXTextLink"
    case timeline             = "AXTimeline"
    case sortButton           = "AXSortButton"
    case ratingIndicator      = "AXRatingIndicator"
    case contentList          = "AXContentList"
    case definitionList       = "AXDefinitionList"
    case fullScreenButton     = "AXFullScreenButton"
    case toggle               = "AXToggle"
    case switchSubrole        = "AXSwitch"
    case descriptionList      = "AXDescriptionList"
}

/// Orientations returned by the orientation property.
/// - seeAlso: [NSAccessibilityOrientation](https://developer.apple.com/library/mac/documentation/AppKit/Reference/NSAccessibility_Protocol_Reference/index.html#//apple_ref/c/tdef/NSAccessibilityOrientation)
public enum Orientation: Int {
    case unknown    = 0
    case vertical   = 1
    case horizontal = 2
}

public enum Attribute: String {
    // Standard attributes
    case role                                   = "AXRole" //(NSString *) - type, non-localized (e.g. radioButton)
    case roleDescription                        = "AXRoleDescription" //(NSString *) - user readable role (e.g. "radio button")
    case subrole                                = "AXSubrole" //(NSString *) - type, non-localized (e.g. closeButton)
    case help                                   = "AXHelp" //(NSString *) - instance description (e.g. a tool tip)
    case value                                  = "AXValue" //(id)         - element's value
    case minValue                               = "AXMinValue" //(id)         - element's min value
    case maxValue                               = "AXMaxValue" //(id)         - element's max value
    case enabled                                = "AXEnabled" //(NSNumber *) - (boolValue) responds to user?
    case focused                                = "AXFocused" //(NSNumber *) - (boolValue) has keyboard focus?
    case parent                                 = "AXParent" //(id)         - element containing you
    case children                               = "AXChildren" //(NSArray *)  - elements you contain
    case window                                 = "AXWindow" //(id)         - UIElement for the containing window
    case topLevelUIElement                      = "AXTopLevelUIElement" //(id)         - UIElement for the containing top level element
    case selectedChildren                       = "AXSelectedChildren" //(NSArray *)  - child elements which are selected
    case visibleChildren                        = "AXVisibleChildren" //(NSArray *)  - child elements which are visible
    case position                               = "AXPosition" //(NSValue *)  - (pointValue) position in screen coords
    case size                                   = "AXSize" //(NSValue *)  - (sizeValue) size
    case frame                                  = "AXFrame" //(NSValue *)  - (rectValue) frame
    case contents                               = "AXContents" //(NSArray *)  - main elements
    case title                                  = "AXTitle" //(NSString *) - visible text (e.g. of a push button)
    case description                            = "AXDescription" //(NSString *) - instance description
    case shownMenu                              = "AXShownMenu" //(id)         - menu being displayed
    case valueDescription                       = "AXValueDescription" //(NSString *)  - text description of value

    case sharedFocusElements                    = "AXSharedFocusElements" //(NSArray *)  - elements that share focus

    // Misc attributes
    case previousContents                       = "AXPreviousContents" //(NSArray *)  - main elements
    case nextContents                           = "AXNextContents" //(NSArray *)  - main elements
    case header                                 = "AXHeader" //(id)         - UIElement for header.
    case edited                                 = "AXEdited" //(NSNumber *) - (boolValue) is it dirty?
    case tabs                                   = "AXTabs" //(NSArray *)  - UIElements for tabs
    case horizontalScrollBar                    = "AXHorizontalScrollBar" //(id)       - UIElement for the horizontal scroller
    case verticalScrollBar                      = "AXVerticalScrollBar" //(id)         - UIElement for the vertical scroller
    case overflowButton                         = "AXOverflowButton" //(id)         - UIElement for overflow
    case incrementButton                        = "AXIncrementButton" //(id)         - UIElement for increment
    case decrementButton                        = "AXDecrementButton" //(id)         - UIElement for decrement
    case filename                               = "AXFilename" //(NSString *) - filename
    case expanded                               = "AXExpanded" //(NSNumber *) - (boolValue) is expanded?
    case selected                               = "AXSelected" //(NSNumber *) - (boolValue) is selected?
    case splitters                              = "AXSplitters" //(NSArray *)  - UIElements for splitters
    case document                               = "AXDocument" //(NSString *) - url as string - for open document
    case activationPoint                        = "AXActivationPoint" //(NSValue *)  - (pointValue)

    case url                                    = "AXURL" //(NSURL *)    - url
    case index                                  = "AXIndex" //(NSNumber *)  - (intValue)

    case rowCount                               = "AXRowCount" //(NSNumber *)  - (intValue) number of rows

    case columnCount                            = "AXColumnCount" //(NSNumber *)  - (intValue) number of columns

    case orderedByRow                           = "AXOrderedByRow" //(NSNumber *)  - (boolValue) is ordered by row?

    case warningValue                           = "AXWarningValue" //(id)  - warning value of a level indicator, typically a number

    case criticalValue                          = "AXCriticalValue" //(id)  - critical value of a level indicator, typically a number

    case placeholderValue                       = "AXPlaceholderValue" //(NSString *)  - placeholder value of a control such as a text field

    case containsProtectedContent               = "AXContainsProtectedContent" // (NSNumber *) - (boolValue) contains protected content?
    case alternateUIVisible                     = "AXAlternateUIVisible" //(NSNumber *) - (boolValue)

    // Linkage attributes
    case titleUIElement                         = "AXTitleUIElement" //(id)       - UIElement for the title
    case servesAsTitleForUIElements             = "AXServesAsTitleForUIElements" //(NSArray *) - UIElements this titles
    case linkedUIElements                       = "AXLinkedUIElements" //(NSArray *) - corresponding UIElements

    // Text-specific attributes
    case selectedText                           = "AXSelectedText" //(NSString *) - selected text
    case selectedTextRange                      = "AXSelectedTextRange" //(NSValue *)  - (rangeValue) range of selected text
    case numberOfCharacters                     = "AXNumberOfCharacters" //(NSNumber *) - number of characters
    case visibleCharacterRange                  = "AXVisibleCharacterRange" //(NSValue *)  - (rangeValue) range of visible text
    case sharedTextUIElements                   = "AXSharedTextUIElements" //(NSArray *)  - text views sharing text
    case sharedCharacterRange                   = "AXSharedCharacterRange" //(NSValue *)  - (rangeValue) part of shared text in this view
    case insertionPointLineNumber               = "AXInsertionPointLineNumber" //(NSNumber *) - line# containing caret
    case selectedTextRanges                     = "AXSelectedTextRanges" //(NSArray<NSValue *> *) - array of NSValue (rangeValue) ranges of selected text
    /// - note: private/undocumented attribute
    case textInputMarkedRange                   = "AXTextInputMarkedRange"

    // Parameterized text-specific attributes
    case lineForIndexParameterized              = "AXLineForIndexParameterized" //(NSNumber *) - line# for char index; param:(NSNumber *)
    case rangeForLineParameterized              = "AXRangeForLineParameterized" //(NSValue *)  - (rangeValue) range of line; param:(NSNumber *)
    case stringForRangeParameterized            = "AXStringForRangeParameterized" //(NSString *) - substring; param:(NSValue * - rangeValue)
    case rangeForPositionParameterized          = "AXRangeForPositionParameterized" //(NSValue *)  - (rangeValue) composed char range; param:(NSValue * - pointValue)
    case rangeForIndexParameterized             = "AXRangeForIndexParameterized" //(NSValue *)  - (rangeValue) composed char range; param:(NSNumber *)
    case boundsForRangeParameterized            = "AXBoundsForRangeParameterized" //(NSValue *)  - (rectValue) bounds of text; param:(NSValue * - rangeValue)
    case rtfForRangeParameterized               = "AXRTFForRangeParameterized" //(NSData *)   - rtf for text; param:(NSValue * - rangeValue)
    case styleRangeForIndexParameterized        = "AXStyleRangeForIndexParameterized" //(NSValue *)  - (rangeValue) extent of style run; param:(NSNumber *)
    case attributedStringForRangeParameterized  = "AXAttributedStringForRangeParameterized" //(NSAttributedString *) - does _not_ use attributes from Appkit/AttributedString.h

    // Text attributed string attributes and constants
    case fontText                               = "AXFontText" //(NSDictionary *)  - NSAccessibilityFontXXXKey's
    case foregroundColorText                    = "AXForegroundColorText" //CGColorRef
    case backgroundColorText                    = "AXBackgroundColorText" //CGColorRef
    case underlineColorText                     = "AXUnderlineColorText" //CGColorRef
    case strikethroughColorText                 = "AXStrikethroughColorText" //CGColorRef
    case underlineText                          = "AXUnderlineText" //(NSNumber *)     - underline style
    case superscriptText                        = "AXSuperscriptText" //(NSNumber *)     - superscript>0, subscript<0
    case strikethroughText                      = "AXStrikethroughText" //(NSNumber *)     - (boolValue)
    case shadowText                             = "AXShadowText" //(NSNumber *)     - (boolValue)
    case attachmentText                         = "AXAttachmentText" //id - corresponding element
    case linkText                               = "AXLinkText" //id - corresponding element
    case autocorrectedText                      = "AXAutocorrectedText" //(NSNumber *)     - (boolValue)

    // Textual list attributes and constants. Examples: unordered or ordered lists in a document.
    case listItemPrefixText                     = "AXListItemPrefixText" // NSAttributedString, the prepended string of the list item. If the string is a common unicode character (e.g. a bullet •), return that unicode character. For lists with images before the text, return a reasonable label of the image.
    case listItemIndexText                      = "AXListItemIndexText" // NSNumber, integerValue of the line index. Each list item increments the index, even for unordered lists. The first item should have index 0.
    case listItemLevelText                      = "AXListItemLevelText" // NSNumber, integerValue of the indent level. Each sublist increments the level. The first item should have level 0.

    // MisspelledText attributes
    case misspelledText                         = "AXMisspelledText" //(NSNumber *)     - (boolValue)
    case markedMisspelledText                   = "AXMarkedMisspelledText" //(NSNumber *) - (boolValue)

    // Window-specific attributes
    case main                                   = "AXMain" //(NSNumber *) - (boolValue) is it the main window?
    case minimized                              = "AXMinimized" //(NSNumber *) - (boolValue) is window minimized?
    case closeButton                            = "AXCloseButton" //(id) - UIElement for close box (or nil)
    case zoomButton                             = "AXZoomButton" //(id) - UIElement for zoom box (or nil)
    case minimizeButton                         = "AXMinimizeButton" //(id) - UIElement for miniaturize box (or nil)
    case toolbarButton                          = "AXToolbarButton" //(id) - UIElement for toolbar box (or nil)
    case proxy                                  = "AXProxy" //(id) - UIElement for title's icon (or nil)
    case growArea                               = "AXGrowArea" //(id) - UIElement for grow box (or nil)
    case modal                                  = "AXModal" //(NSNumber *) - (boolValue) is the window modal
    case defaultButton                          = "AXDefaultButton" //(id) - UIElement for default button
    case cancelButton                           = "AXCancelButton" //(id) - UIElement for cancel button
    case fullScreenButton                       = "AXFullScreenButton" //(id) - UIElement for full screen button (or nil)
    /// - note: private/undocumented attribute
    case fullScreen                             = "AXFullScreen" //(NSNumber *) - (boolValue) is the window fullscreen

    // Application-specific attributes
    case menuBar                                = "AXMenuBar" //(id)         - UIElement for the menu bar
    case windows                                = "AXWindows" //(NSArray *)  - UIElements for the windows
    case frontmost                              = "AXFrontmost" //(NSNumber *) - (boolValue) is the app active?
    case hidden                                 = "AXHidden" //(NSNumber *) - (boolValue) is the app hidden?
    case mainWindow                             = "AXMainWindow" //(id)         - UIElement for the main window.
    case focusedWindow                          = "AXFocusedWindow" //(id)         - UIElement for the key window.
    case focusedUIElement                       = "AXFocusedUIElement" //(id)         - Currently focused UIElement.
    case extrasMenuBar                          = "AXExtrasMenuBar" //(id)         - UIElement for the application extras menu bar.
    /// - note: private/undocumented attribute
    case enhancedUserInterface                  = "AXEnhancedUserInterface" //(NSNumber *) - (boolValue) is the enhanced user interface active?

    case orientation                            = "AXOrientation" //(NSString *) - NSAccessibilityXXXOrientationValue

    case columnTitles                           = "AXColumnTitles" //(NSArray *)  - UIElements for titles

    case searchButton                           = "AXSearchButton" //(id)         - UIElement for search field search btn
    case searchMenu                             = "AXSearchMenu" //(id)         - UIElement for search field menu
    case clearButton                            = "AXClearButton" //(id)         - UIElement for search field clear btn

    // Table/outline view attributes
    case rows                                   = "AXRows" //(NSArray *)  - UIElements for rows
    case visibleRows                            = "AXVisibleRows" //(NSArray *)  - UIElements for visible rows
    case selectedRows                           = "AXSelectedRows" //(NSArray *)  - UIElements for selected rows
    case columns                                = "AXColumns" //(NSArray *)  - UIElements for columns
    case visibleColumns                         = "AXVisibleColumns" //(NSArray *)  - UIElements for visible columns
    case selectedColumns                        = "AXSelectedColumns" //(NSArray *)  - UIElements for selected columns
    case sortDirection                          = "AXSortDirection" //(NSString *) - see sort direction values below

    // Cell-based table attributes
    case selectedCells                          = "AXSelectedCells" //(NSArray *)  - UIElements for selected cells
    case visibleCells                           = "AXVisibleCells" //(NSArray *)  - UIElements for visible cells
    case rowHeaderUIElements                    = "AXRowHeaderUIElements" //(NSArray *)  - UIElements for row headers
    case columnHeaderUIElements                 = "AXColumnHeaderUIElements" //(NSArray *)  - UIElements for column headers

    // Cell-based table parameterized attributes.  The parameter for this attribute is an NSArray containing two NSNumbers, the first NSNumber specifies the column index, the second NSNumber specifies the row index.
    case cellForColumnAndRowParameterized       = "AXCellForColumnAndRowParameterized" // (id) - UIElement for cell at specified row and column

    // Cell attributes.  The index range contains both the starting index, and the index span in a table.
    case rowIndexRange                          = "AXRowIndexRange" //(NSValue *)  - (rangeValue) location and row span
    case columnIndexRange                       = "AXColumnIndexRange" //(NSValue *)  - (rangeValue) location and column span

    // Layout area attributes
    case horizontalUnits                        = "AXHorizontalUnits" //(NSString *) - see ruler unit values below
    case verticalUnits                          = "AXVerticalUnits" //(NSString *) - see ruler unit values below
    case horizontalUnitDescription              = "AXHorizontalUnitDescription" //(NSString *)
    case verticalUnitDescription                = "AXVerticalUnitDescription" //(NSString *)

    // Layout area parameterized attributes
    case layoutPointForScreenPointParameterized = "AXLayoutPointForScreenPointParameterized" //(NSValue *)  - (pointValue); param:(NSValue * - pointValue)
    case layoutSizeForScreenSizeParameterized   = "AXLayoutSizeForScreenSizeParameterized" //(NSValue *)  - (sizeValue); param:(NSValue * - sizeValue)
    case screenPointForLayoutPointParameterized = "AXScreenPointForLayoutPointParameterized" //(NSValue *)  - (pointValue); param:(NSValue * - pointValue)
    case screenSizeForLayoutSizeParameterized   = "AXScreenSizeForLayoutSizeParameterized" //(NSValue *)  - (sizeValue); param:(NSValue * - sizeValue)

    // Layout item attributes
    case handles                                = "AXHandles" //(NSArray *)  - UIElements for handles

    // Outline attributes
    case disclosing                             = "AXDisclosing" //(NSNumber *) - (boolValue) is disclosing rows?
    case disclosedRows                          = "AXDisclosedRows" //(NSArray *)  - UIElements for disclosed rows
    case disclosedByRow                         = "AXDisclosedByRow" //(id)         - UIElement for disclosing row
    case disclosureLevel                        = "AXDisclosureLevel" //(NSNumber *) - indentation level

    // Slider attributes
    case allowedValues                          = "AXAllowedValues" //(NSArray<NSNumber *> *) - array of allowed values
    case labelUIElements                        = "AXLabelUIElements" //(NSArray *) - array of label UIElements
    case labelValue                             = "AXLabelValue" //(NSNumber *) - value of a label UIElement

    // Matte attributes
    // Attributes no longer supported
    case matteHole                              = "AXMatteHole" //(NSValue *) - (rect value) bounds of matte hole in screen coords
    case matteContentUIElement                  = "AXMatteContentUIElement" //(id) - UIElement clipped by the matte

    // Ruler view attributes
    case markerUIElements                       = "AXMarkerUIElements" //(NSArray *)
    case markerValues                           = "AXMarkerValues" //
    case markerGroupUIElement                   = "AXMarkerGroupUIElement" //(id)
    case units                                  = "AXUnits" //(NSString *) - see ruler unit values below
    case unitDescription                        = "AXUnitDescription" //(NSString *)
    case markerType                             = "AXMarkerType" //(NSString *) - see ruler marker type values below
    case markerTypeDescription                  = "AXMarkerTypeDescription" //(NSString *)

    // UI element identification attributes
    case identifier                             = "AXIdentifier" //(NSString *)

    // System-wide attributes
    case focusedApplication                     = "AXFocusedApplication"

    // Unknown attributes
    case functionRowTopLevelElements            = "AXFunctionRowTopLevelElements"
    case childrenInNavigationOrder              = "AXChildrenInNavigationOrder"
}

/// All actions a `UIElement` can support.
/// - seeAlso: [Actions](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/ApplicationKit/Protocols/NSAccessibility_Protocol/#//apple_ref/doc/constant_group/Actions)
public enum Action: String {
    case press           = "AXPress"
    case increment       = "AXIncrement"
    case decrement       = "AXDecrement"
    case confirm         = "AXConfirm"
    case pick            = "AXPick"
    case cancel          = "AXCancel"
    case raise           = "AXRaise"
    case showMenu        = "AXShowMenu"
    case delete          = "AXDelete"
    case showAlternateUI = "AXShowAlternateUI"
    case showDefaultUI   = "AXShowDefaultUI"
}
