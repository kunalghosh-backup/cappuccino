/*
 * CPTableHeaderView.j
 * AppKit
 *
 * Created by Ross Boucher.
 * Copyright 2009 280 North, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import "CPTableColumn.j"
@import "CPTableView.j"
@import "CPView.j"
 
@implementation _CPTableColumnHeaderView : CPView
{
    _CPImageAndTextView     _textField;
}

- (void)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {   
        [self _init];
    }
    
    return self;
}

- (void)_init
{
    _textField = [[_CPImageAndTextView alloc] initWithFrame:CGRectMake(5, 1, CGRectGetWidth([self bounds]) - 10, CGRectGetHeight([self bounds]) - 1)];
    [_textField setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
    
    [_textField setLineBreakMode:CPLineBreakByTruncatingTail];
    [_textField setTextColor: [CPColor colorWithHexString: @"333333"]];
    [_textField setFont:[CPFont boldSystemFontOfSize:12.0]];
    [_textField setAlignment:CPLeftTextAlignment];
    [_textField setVerticalAlignment:CPCenterVerticalTextAlignment];
    [_textField setTextShadowColor:[CPColor whiteColor]];
    [_textField setTextShadowOffset:CGSizeMake(0,1)];

    [self addSubview:_textField];
}

- (void)layoutSubviews
{
    var themeState = [self themeState];

    if(themeState & CPThemeStateSelected && themeState & CPThemeStateHighlighted)
        [self setBackgroundColor:[CPColor colorWithPatternImage:CPAppKitImage("tableview-headerview-highlighted-pressed.png", CGSizeMake(1.0, 22.0))]];
    else if (themeState & CPThemeStateSelected)
        [self setBackgroundColor:[CPColor colorWithPatternImage:CPAppKitImage("tableview-headerview-highlighted.png", CGSizeMake(1.0, 22.0))]];
    else if (themeState & CPThemeStateHighlighted)
        [self setBackgroundColor:[CPColor colorWithPatternImage:CPAppKitImage("tableview-headerview-pressed.png", CGSizeMake(1.0, 22.0))]];
    else 
        [self setBackgroundColor:[CPColor colorWithPatternImage:CPAppKitImage("tableview-headerview.png", CGSizeMake(1.0, 22.0))]];
}

- (void)setStringValue:(CPString)string
{
    [_textField setText:string];
}

- (CPString)stringValue
{
    return [_textField text];
}

- (void)textField
{
    return _textField;
}

- (void)sizeToFit
{
    [_textField sizeToFit];
}

- (void)setFont:(CPFont)aFont
{
    [_textField setFont:aFont];
}

- (void)setValue:(id)aValue forThemeAttribute:(id)aKey
{
    [_textField setValue:aValue forThemeAttribute:aKey];
}

- (void)_setIndicatorImage:(CPImage)anImage
{
	if (anImage)
	{
		[_textField setImage:anImage];
		[_textField setImagePosition:CPImageRight];
	}
	else
	{
		[_textField setImagePosition:CPNoImage];
	}
}

@end

var _CPTableColumnHeaderViewStringValueKey = @"_CPTableColumnHeaderViewStringValueKey",
    _CPTableColumnHeaderViewFontKey = @"_CPTableColumnHeaderViewFontKey",
    _CPTableColumnHeaderViewImageKey = @"_CPTableColumnHeaderViewImageKey";

@implementation _CPTableColumnHeaderView (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        [self _init];
        [self _setIndicatorImage:[aCoder decodeObjectForKey:_CPTableColumnHeaderViewImageKey]];
        [self setStringValue:[aCoder decodeObjectForKey:_CPTableColumnHeaderViewStringValueKey]];
        [self setFont:[aCoder decodeObjectForKey:_CPTableColumnHeaderViewFontKey]];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:[_textField text] forKey:_CPTableColumnHeaderViewStringValueKey];
    [aCoder encodeObject:[_textField image] forKey:_CPTableColumnHeaderViewImageKey];
    [aCoder encodeObject:[_textField font] forKey:_CPTableColumnHeaderViewFontKey];
}

@end

@implementation CPTableHeaderView : CPView
{
    CPPoint                 _mouseDownLocation;
    CPPoint                 _previousTrackingLocation;
    int                     _activeColumn;
    int                     _pressedColumn;
    
    BOOL                    _isResizing;
    BOOL                    _isDragging;
    BOOL                    _isTrackingColumn;
    
    // CPPoint             _previousTrackingLocation;
    // 
    // int                 _resizedColumn @accessors(readonly, property=resizedColumn);
    // int                 _draggedColumn @accessors(readonly, property=draggedColumn);
    // int                 _pressedColumn @accessors(readonly, property=pressedColumn);
    // int                 _clickedColumn @accessors(readonly, property=clickedColumn);
    // BOOL                _isTrackingColumn;
    // 
    // float               _draggedDistance @accessors(readonly, property=draggedDistance);
    // float               _lastLocation;
    // float               _columnOldWidth;
    
    CPTableView _tableView @accessors(property=tableView);
}

- (void)_init
{
    _resizedColumn = -1;
    _draggedColumn = -1;
    _pressedColumn = CPNotFound;
    _draggedDistance = 0.0;
    _lastLocation = nil;
    _columnOldWidth = nil;

    [self setBackgroundColor:[CPColor colorWithPatternImage:CPAppKitImage("tableview-headerview.png", CGSizeMake(1.0, 22.0))]];
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
        [self _init];

    return self;
}

- (int)columnAtPoint:(CGPoint)aPoint
{
    return [_tableView columnAtPoint:CGPointMake(aPoint.x, aPoint.y)];
}

- (CGRect)headerRectOfColumn:(int)aColumnIndex
{
    var tableColumns = [_tableView tableColumns];

    if (aColumnIndex < 0 || aColumnIndex > [tableColumns count])
        [CPException raise:"invalid" reason:"tried to get headerRectOfColumn: on invalid column"];

    // UPDATE COLUMN RANGES ?
        
    var tableRange = _tableView._tableColumnRanges[aColumnIndex],
        bounds = [self bounds];

    var rMinX = ROUND(tableRange.location);
    bounds.origin.x = rMinX;
    bounds.size.width = FLOOR(tableRange.length + tableRange.location - rMinX);
    
    return bounds;
}

- (CGRect)_cursorRectForColumn:(int)column
{
    if (column == -1 || !([_tableView._tableColumns[column] resizingMask] & CPTableColumnUserResizingMask))
        return CGRectMakeZero();

    var rect = [self headerRectOfColumn:column];

    rect.origin.x = CGRectGetMaxX(rect) - 5;
    rect.size.width = 20;

    return rect;    
}

- (void)_setPressedColumn:(CPInteger)column
{
    if (_pressedColumn != -1)
    {
        var headerView = [_tableView._tableColumns[_pressedColumn] headerView];
        [headerView unsetThemeState:CPThemeStateHighlighted];
    }    
    
    if (column != -1)
    {
        var headerView = [_tableView._tableColumns[column] headerView];
        [headerView setThemeState:CPThemeStateHighlighted];
    }
    
    _pressedColumn = column;
}

- (void)mouseDown:(CPEvent)theEvent
{
    [self trackMouse:theEvent];
}

- (void)trackMouse:(CPEvent)theEvent
{
    var type = [theEvent type],
        currentLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    
    // Take the right columns resize tracking area into account
    currentLocation.x -= 5.0;

    var columnIndex = [self columnAtPoint:currentLocation],
        shouldResize = [self shouldResizeTableColumn:columnIndex at:CPPointMake(currentLocation.x + 5.0, currentLocation.y)];
        
    if (type === CPLeftMouseUp)
    {
        if (shouldResize)
            [self stopResizingTableColumn:_activeColumn at:currentLocation];
        else if ([self _shouldStopTrackingTableColumn:columnIndex at:currentLocation])
        {
            [[self tableView] _didClickTableColumn:columnIndex modifierFlags:[theEvent modifierFlags]];
            [self stopTrackingTableColumn:columnIndex at:currentLocation];
            
            _isTrackingColumn = NO;
        }

        _activeColumn = CPNotFound;
        return;
    }

    if (type === CPLeftMouseDown)
    {
        if (columnIndex === -1)
            return;
        
        _mouseDownLocation = currentLocation;
        _activeColumn = columnIndex;

        [[self tableView] _sendDelegateDidMouseDownInHeader:columnIndex];

        if (shouldResize)
            [self startResizingTableColumn:columnIndex at:currentLocation];
        else
        {
            [self startTrackingTableColumn:columnIndex at:currentLocation];
            _isTrackingColumn = YES;
        }
    }
    else if (type === CPLeftMouseDragged)
    {
        if (shouldResize)
            [self continueResizingTableColumn:_activeColumn at:currentLocation];
        else
        {
            if (_activeColumn === columnIndex && CPRectContainsPoint([self headerRectOfColumn:columnIndex], currentLocation))
            {
                if (_isTrackingColumn && _pressedColumn !== CPNotFound)
                {
                    if (![self continueTrackingTableColumn:columnIndex at:currentLocation])
                        return; // Stop tracking the column, because it's being dragged
                } else
                    [self startTrackingTableColumn:columnIndex at:currentLocation];
                    
            } else if (_isTrackingColumn && _pressedColumn !== CPNotFound)
                [self stopTrackingTableColumn:_activeColumn at:currentLocation];
        }
    }
    
    _previousTrackingLocation = currentLocation;
    [CPApp setTarget:self selector:@selector(trackMouse:) forNextEventMatchingMask:CPLeftMouseDraggedMask | CPLeftMouseUpMask untilDate:nil inMode:nil dequeue:YES];
}

- (void)startTrackingTableColumn:(int)aColumnIndex at:(CPPoint)aPoint
{
    [self _setPressedColumn:aColumnIndex];
}

- (BOOL)continueTrackingTableColumn:(int)aColumnIndex at:(CPPoint)aPoint
{
    if ([self _shouldDragTableColumn:aColumnIndex at:aPoint])
    {
        var columnRect = [self headerRectOfColumn:aColumnIndex],
            offset = CPPointMakeZero(),
            view = [[self tableView] _dragViewForColumn:aColumnIndex event:[CPApp currentEvent] offset:offset],
            viewLocation = CPPointMakeZero();
        
        viewLocation.x = ( CPRectGetMinX(columnRect) + offset.x ) + ( aPoint.x - _mouseDownLocation.x );
        viewLocation.y = CPRectGetMinY(columnRect) + offset.y;
        
        [self dragView:view at:viewLocation offset:CPSizeMakeZero() event:[CPApp currentEvent] 
            pasteboard:[CPPasteboard pasteboardWithName:CPDragPboard] source:self slideBack:YES];
            
        return NO;
    }
    
    return YES;
}

- (BOOL)_shouldStopTrackingTableColumn:(int)aColumnIndex at:(CPPoint)aPoint
{
    return _isTrackingColumn && _activeColumn === aColumnIndex && 
        CPRectContainsPoint([self headerRectOfColumn:aColumnIndex], aPoint);
}

- (void)stopTrackingTableColumn:(int)aColumnIndex at:(CPPoint)aPoint
{
    [self _setPressedColumn:CPNotFound];
}

- (BOOL)_shouldDragTableColumn:(int)aColumnIndex at:(CPPoint)aPoint
{
    return [[self tableView] allowsColumnReordering] && ABS(aPoint.x - _mouseDownLocation.x) >= 10.0;
}

- (void)_constrainDragView:(CPView)theDragView at:(CPPoint)aPoint
{
    var tableColumns = [[self tableView] tableColumns],
        lastColumnRect = [self headerRectOfColumn:[tableColumns indexOfObjectIdenticalTo:[tableColumns lastObject]]],
        activeColumnRect = [self headerRectOfColumn:_activeColumn];
        dragWindow = [theDragView window],
        frame = [dragWindow frame];
    
    // This effectively clamps the value between the minimum and maximum
    frame.origin.x = MAX(0.0, MIN(CPRectGetMinX(frame), CPRectGetMaxX(lastColumnRect) - CPRectGetWidth(activeColumnRect)));
    
    // Make sure the column cannot move vertically
    frame.origin.y = CPRectGetMinY([self convertRect:lastColumnRect toView:nil]);
    
    [dragWindow setFrame:frame];
}

- (void)_moveColumn:(int)aFromIndex toColumn:(int)aToIndex
{
    [[self tableView] moveColumn:aFromIndex toColumn:aToIndex];
    _activeColumn = aToIndex;
    _pressedColumn = _activeColumn;
    
    [[self tableView] _setDraggedColumn:_activeColumn];
}

- (void)draggedView:(CPView)aView beganAt:(CPPoint)aPoint
{
    _isDragging = YES;
    
    [[[[[self tableView] tableColumns] objectAtIndex:_activeColumn] headerView] setHidden:YES];
    [[self tableView] _setDraggedColumn:_activeColumn];
    
    [self setNeedsDisplay:YES];
}

- (void)draggedView:(CPView)aView movedTo:(CPPoint)aPoint
{
    [self _constrainDragView:aView at:aPoint];
    
    var dragWindowFrame = [[aView window] frame];
    
    var hoverPoint = CPPointCreateCopy(aPoint);
    if (aPoint.x < _previousTrackingLocation.x)
        hoverPoint = CPPointMake(CPRectGetMinX(dragWindowFrame), CPRectGetMinY(dragWindowFrame));
    else if (aPoint.x > _previousTrackingLocation.x)
        hoverPoint = CPPointMake(CPRectGetMaxX(dragWindowFrame), CPRectGetMinY(dragWindowFrame));
    
    var hoveredColumn = [self columnAtPoint:hoverPoint],
    
    if (hoveredColumn !== -1)
    {
        var columnRect = [self headerRectOfColumn:hoveredColumn],
            columnCenterPoint = CPPointMake(CPRectGetMidX(columnRect), CPRectGetMidY(columnRect));
    
        if (hoveredColumn < _activeColumn && hoverPoint.x < columnCenterPoint.x)
            [self _moveColumn:_activeColumn toColumn:hoveredColumn];
        else if (hoveredColumn > _activeColumn && hoverPoint.x > columnCenterPoint.x)
            [self _moveColumn:_activeColumn toColumn:hoveredColumn];
    }
    
    _previousTrackingLocation = aPoint;
}

- (void)draggedView:(CPImage)aView endedAt:(CGPoint)aLocation operation:(CPDragOperation)anOperation
{
    _isDragging = NO;
    
    [[self tableView] _setDraggedColumn:-1];
    [[[[[self tableView] tableColumns] objectAtIndex:_activeColumn] headerView] setHidden:NO];
    [self stopTrackingTableColumn:_activeColumn at:aLocation];
    
    [self setNeedsDisplay:YES];
}

- (BOOL)shouldResizeTableColumn:(int)aColumnIndex at:(CPPoint)aPoint
{
    if (_isResizing)
        return YES;
        
    if (_isTrackingColumn)
        return NO;

    return [[self tableView] allowsColumnResizing] && CPRectContainsPoint([self _cursorRectForColumn:aColumnIndex], aPoint);
}

- (void)startResizingTableColumn:(int)aColumnIndex at:(CPPoint)aPoint
{
    _isResizing = YES;
    
    CPLog.debug(@"startResizingTableColumn: %@ at: %@", aColumnIndex, CPStringFromPoint(aPoint));
    
    var tableColumn = [[[self tableView] tableColumns] objectAtIndex:aColumnIndex];
    
    [tableColumn setDisableResizingPosting:YES];
    [[self tableView] setDisableAutomaticResizing:YES];
    
    _resizedColumn = aColumnIndex;
}

- (void)continueResizingTableColumn:(int)aColumnIndex at:(CPPoint)aPoint
{
    CPLog.debug(@"continueResizingTableColumn: %@ at: %@", aColumnIndex, CPStringFromPoint(aPoint));
    
    var tableColumn = [[[self tableView] tableColumns] objectAtIndex:aColumnIndex];
    
    var newWidth = [tableColumn width] + aPoint.x - _previousTrackingLocation.x;
    
    if (newWidth < [tableColumn minWidth])
        [[CPCursor resizeRightCursor] set];
    else if (newWidth > [tableColumn maxWidth])
        [[CPCursor resizeLeftCursor] set];
    else
    {
        [self tableView]._lastColumnShouldSnap = NO;
        [tableColumn setWidth:newWidth];
        
        [[CPCursor resizeLeftRightCursor] set];
        [self setNeedsLayout];
        [self setNeedsDisplay:YES];
    }
}

- (void)stopResizingTableColumn:(int)aColumnIndex at:(CPPoint)aPoint
{
    CPLog.debug(@"stopResizingTableColumn: %@ at: %@", aColumnIndex, CPStringFromPoint(aPoint));
    
    // [self _updateResizeCursorForTableColumn:aColumnIndex at:aPoint];
    
    var tableColumn = [[[self tableView] tableColumns] objectAtIndex:aColumnIndex];
    [tableColumn _postDidResizeNotificationWithOldWidth:_columnOldWidth];
    [tableColumn setDisableResizingPosting:NO];
    [[self tableView] setDisableAutomaticResizing:NO];
    
    _isResizing = NO;
}

- (void)_updateResizeCursorForTableColumn:(int)aColumnIndex at:(CPPoint)aPoint mouseIsUp:(BOOL)isMouseUp
{
    if (![[self tableView] allowsColumnResizing] || (isMouseUp && ![[self window] acceptsMouseMovedEvents]))
    {
        [[CPCursor arrowCursor] set];
        return;
    }
    
    
}

- (void)_updateResizeCursor:(CPEvent)theEvent
{
    // never get stuck in resize cursor mode (FIXME take out when we turn on tracking rects)
    if (![_tableView allowsColumnResizing] || ([theEvent type] === CPLeftMouseUp && ![[self window] acceptsMouseMovedEvents]))
    {
        [[CPCursor arrowCursor] set];
        return;
    }

    var mouseLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil],    
        mouseOverLocation = CGPointMake(mouseLocation.x - 5, mouseLocation.y),
        overColumn = [self columnAtPoint:mouseOverLocation];
    
    if (overColumn >= 0 && CGRectContainsPoint([self _cursorRectForColumn:overColumn], mouseLocation))
    {
        var tableColumn = [[_tableView tableColumns] objectAtIndex:overColumn],
            width = [tableColumn width];
            
        if (width == [tableColumn minWidth])
            [[CPCursor resizeRightCursor] set];
        else if (width == [tableColumn maxWidth])
            [[CPCursor resizeLeftCursor] set];
        else
            [[CPCursor resizeLeftRightCursor] set];
    }
    else
        [[CPCursor arrowCursor] set];
}

- (void)viewDidMoveToWindow
{
    //if ([_tableView allowsColumnResizing])
    //    [[self window] setAcceptsMouseMovedEvents:YES];
}

- (void)mouseEntered:(CPEvent)theEvent
{   
    [self _updateResizeCursor:theEvent];
}

- (void)mouseMoved:(CPEvent)theEvent
{
    [self _updateResizeCursor:theEvent];
}

- (void)mouseExited:(CPEvent)theEvent
{
    // FIXME: we should use CPCursor push/pop (if previous currentCursor != arrow).
    [[CPCursor arrowCursor] set];
}

- (void)layoutSubviews
{
    var tableColumns = [_tableView tableColumns],
        count = [tableColumns count];    
    
    for (var i = 0; i < count; i++) 
    {
        var column = [tableColumns objectAtIndex:i],
            headerView = [column headerView];
        
        var frame = [self headerRectOfColumn:i];
        frame.size.height -= 0.5;
        if (i > 0) 
        {
            frame.origin.x += 0.5;
            frame.size.width -= 1;
        }
        
        [headerView setFrame:frame];
        
        if([headerView superview] != self)
            [self addSubview:headerView];
    }
}

- (void)drawRect:(CGRect)aRect
{
    if (!_tableView)
        return;

    var context = [[CPGraphicsContext currentContext] graphicsPort],
        exposedColumnIndexes = [_tableView columnIndexesInRect:aRect],
        columnsArray = [],
        tableColumns = [_tableView tableColumns],
        exposedTableColumns = _tableView._exposedColumns,
        firstIndex = [exposedTableColumns firstIndex],
        exposedRange = CPMakeRange(firstIndex, [exposedTableColumns lastIndex] - firstIndex + 1);

    CGContextSetLineWidth(context, 1);
    CGContextSetStrokeColor(context, [_tableView gridColor]);

    [exposedColumnIndexes getIndexes:columnsArray maxCount:-1 inIndexRange:exposedRange];

    var columnArrayIndex = 0,
        columnArrayCount = columnsArray.length,
        columnMaxX;
        
    CGContextBeginPath(context);
    for(; columnArrayIndex < columnArrayCount; columnArrayIndex++)
    {
        // grab each column rect and add vertical lines
        var columnIndex = columnsArray[columnArrayIndex],
            columnToStroke = [self headerRectOfColumn:columnIndex];
            
        columnMaxX = CGRectGetMaxX(columnToStroke);
        
        CGContextMoveToPoint(context, ROUND(columnMaxX) + 0.5, ROUND(CGRectGetMinY(columnToStroke)));
        CGContextAddLineToPoint(context, ROUND(columnMaxX) + 0.5, ROUND(CGRectGetMaxY(columnToStroke)));
    }
    
    CGContextClosePath(context);
    CGContextStrokePath(context);
    
    if (_isDragging)
    {
        CGContextSetFillColor(context, [CPColor grayColor]);
        CGContextFillRect(context, [self headerRectOfColumn:_activeColumn])
    }
}

@end

var CPTableHeaderViewTableViewKey = @"CPTableHeaderViewTableViewKey";

@implementation CPTableHeaderView (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        [self _init];
        _tableView = [aCoder decodeObjectForKey:CPTableHeaderViewTableViewKey];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:_tableView forKey:CPTableHeaderViewTableViewKey];
}

@end
